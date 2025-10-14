# frozen_string_literal: true

require 'pty'
require 'io/console'
require 'English'
require 'fileutils'

begin
  require 'tty-cursor'
  require 'tty-screen'
rescue LoadError
  # fall back to ANSI sequences when tty gems are not installed
end

module RubyProgress
  # PTY-based live output capture that reserves a small terminal area
  # for printing captured output while the animation draws elsewhere.
  class OutputCapture
    attr_reader :exit_status

    def initialize(command:, lines: 3, position: :above, log_path: nil, stream: false, debug: nil)
      @command = command
      # Coerce lines into a positive Integer
      @lines = (lines || 3).to_i
      @lines = 1 if @lines < 1

      # Normalize position (accept :top/:bottom or :above/:below or strings)
      pos = position.respond_to?(:to_sym) ? position.to_sym : position
      @position = case pos
                  when :top, 'top' then :above
                  when :bottom, 'bottom' then :below
                  when :above, 'above' then :above
                  when :below, 'below' then :below
                  else
                    :above
                  end

      @buffer = []
      @buf_mutex = Mutex.new
      @stop = false
      @log_path = log_path
      @log_file = nil
      @stream = stream

      @debug = if debug.nil?
                 ENV.fetch('RUBY_PROGRESS_DEBUG', nil) && ENV['RUBY_PROGRESS_DEBUG'] != '0'
               else
                 debug
               end
      @debug_path = '/tmp/ruby-progress-debug.log'

      if @debug
        begin
          FileUtils.mkdir_p(File.dirname(@debug_path))
          File.open(@debug_path, 'w') { |f| f.puts("debug start: #{Time.now}") }
        rescue StandardError
          @debug = false
        end
      end

      # Debug: log init if requested via ENV or explicit debug flag
      debug_log("init: position=#{@position.inspect}; lines=#{@lines}")
    end

    # Start capturing the child process. Returns self.
    def start
      reserve_space($stderr) if @stream
      @reader_thread = Thread.new { spawn_and_read }
      self
    end

    def stop
      @stop = true
      @reader_thread&.join
    end

    def wait
      @reader_thread&.join
    end

    def lines
      @buf_mutex.synchronize { @buffer.dup }
    end

    def alive?
      @reader_thread&.alive? || false
    end

    # Redraw the reserved area using the current buffered lines.
    def redraw(io = $stderr)
      buf = lines
      debug_log("redraw called; buffer=#{buf.size}; lines=#{@lines}; position=#{@position}")

      # If not streaming live to the terminal, don't redraw during capture.
      return unless @stream

      cols = if defined?(TTY::Screen)
               TTY::Screen.columns
             else
               IO.console.winsize[1]
             end

      display_lines = Array.new(@lines, '')
      if buf.empty?
        # leave display_lines as blanks
      elsif buf.size <= @lines
        buf.each_with_index { |l, i| display_lines[i] = l.to_s }
      else
        buf.last(@lines).each_with_index { |l, i| display_lines[i] = l.to_s }
      end

      if defined?(TTY::Cursor)
        cursor = TTY::Cursor
        io.print cursor.save

        if @position == :above
          io.print cursor.up(@lines)
        else
          io.print cursor.down(1)
        end

        display_lines.each_with_index do |line, idx|
          io.print cursor.clear_line
          io.print line[0, cols]
          io.print cursor.down(1) unless idx == display_lines.length - 1
        end

        io.print cursor.restore
        debug_log('redraw finished (TTY)')
      else
        io.print "\e7"

        if @position == :above
          io.print "\e[#{@lines}A"
        else
          io.print "\e[1B"
        end

        display_lines.each_with_index do |line, idx|
          io.print "\e[2K\r"
          io.print line[0, cols]
          io.print "\e[1B" unless idx == display_lines.length - 1
        end

        io.print "\e8"
        debug_log('redraw finished (ANSI)')
      end

      io.flush
    rescue StandardError => e
      debug_log("redraw error: #{e.class}: #{e.message}")
    end

    # Flush the buffered lines to the given IO (defaults to STDOUT).
    # This is used when capturing non-live output: capture silently during
    # the run and emit all captured output at the end.
    def flush_to(io = $stdout)
      buf = lines
      return if buf.empty?

      begin
        buf.each do |line|
          io.puts(line)
        end
        io.flush
      rescue StandardError => e
        debug_log("flush_to error: #{e.class}: #{e.message}")
      end
    end

    private

    def spawn_and_read
      PTY.spawn(@command) do |reader, _writer, pid|
        @child_pid = pid
        debug_log("spawned pid=#{pid} cmd=#{@command}")

        until reader.eof? || @stop
          next unless reader.wait_readable(0.1)

          chunk = reader.read_nonblock(4096, exception: false)
          next if chunk.nil? || chunk.empty?

          debug_log("read chunk=#{chunk.inspect}")

          if @log_path && !@log_file
            begin
              FileUtils.mkdir_p(File.dirname(@log_path))
              @log_file = File.open(@log_path, 'a')
            rescue StandardError
              @log_file = nil
            end
          end

          process_chunk(chunk)
          debug_log("after process_chunk buffer_size=#{@buffer.size}")

          next unless @log_file

          begin
            @log_file.write(chunk)
            @log_file.flush
          rescue StandardError
            # ignore
          end
        end
      end

      begin
        Process.wait(@child_pid) if @child_pid
        @exit_status = $CHILD_STATUS.exitstatus if $CHILD_STATUS
      rescue StandardError
        @exit_status = nil
      ensure
        @log_file&.close
      end
    rescue Errno::EIO
      # PTY finished
    end

    def process_chunk(chunk)
      @buf_mutex.synchronize do
        chunk.each_line do |line|
          @buffer << line.chomp
          @buffer.shift while @buffer.size > @lines
        end
      end

      debug_log("process_chunk: buffer=#{@buffer.inspect}")
      redraw($stderr) if @stream
    rescue StandardError => e
      debug_log("process_chunk error: #{e.class}: #{e.message}")
    end

    def debug_log(msg)
      return unless ENV['RUBY_PROGRESS_DEBUG'] || @debug

      begin
        File.open(@debug_path, 'a') do |f|
          f.puts("#{Time.now.iso8601} PID=#{Process.pid} #{msg}")
        end
      rescue StandardError
        # swallow logging errors
      end
    end

    def reserve_space(io = $stderr)
      return unless io.tty?

      debug_log("reserve_space called; position=#{@position.inspect}; lines=#{@lines}")

      if @position == :above
        # Insert lines above current cursor using CSI n L
        io.print "\e[#{@lines}L"
        debug_log("reserve_space: inserted #{@lines} lines for :above")
      else
        # Print newlines then move cursor back up so animation stays above
        io.print("\n" * @lines)
        io.print "\e[#{@lines}A"
        debug_log("reserve_space: printed #{@lines} newlines and moved up #{@lines} for :below")
      end

      io.flush
    rescue StandardError => e
      debug_log("reserve_space error: #{e.class}: #{e.message}")
    end
  end
end
