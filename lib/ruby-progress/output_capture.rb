# frozen_string_literal: true

require 'pty'
require 'io/console'

module RubyProgress
  # Simple PTY-based output capture that reserves a small area of the terminal
  # for printing captured output while the animation is drawn separately.
  class OutputCapture
    def initialize(command:, lines: 3, position: :above)
      @command = command
      @lines = lines
      @position = position
      @buffer = []
      @buf_mutex = Mutex.new
      @stop = false
    end

    # Start the child process and return a thread that manages capture.
    def start
      @reader_thread = Thread.new { spawn_and_read }
      self
    end

    def stop
      @stop = true
      @reader_thread&.join
    end

    # Wait for the reader thread to complete
    def wait
      @reader_thread&.join
    end

    # Return snapshot of buffered lines (thread-safe)
    def lines
      @buf_mutex.synchronize { @buffer.dup }
    end

    # Returns whether the reader thread is still alive
    def alive?
      @reader_thread&.alive? || false
    end

    # Redraw buffered output into the terminal above/below the current cursor
    # io - IO object to write to (default $stderr)
    def redraw(io = $stderr)
      buf = lines
      _rows, cols = IO.console.winsize

      # Ensure we have exactly @lines entries (pad with empty strings)
      display_lines = Array.new(@lines) { '' }
      start = [0, buf.size - @lines].max
      buf[start, @lines]&.each_with_index do |l, i|
        display_lines[i + (@lines - [buf.size, @lines].min)] = l.to_s
      end

      # Save cursor, move up N lines, clear and print buffer, restore cursor
      io.print "\e[s" # save position
      io.print "\e[#{@lines}A"            # move up @lines
      display_lines.each do |line|
        io.print "\e[2K"                  # clear line
        io.print line[0, cols]
        io.print "\n"
      end
      io.print "\e[u" # restore
      io.flush
    end

    private

    def spawn_and_read
      PTY.spawn(@command) do |reader, _writer, _pid|
        until reader.eof? || @stop
          if reader.wait_readable(0.1)
            chunk = reader.read_nonblock(4096, exception: false)
            process_chunk(chunk) if chunk && !chunk.empty?
          end
        end
      end
    rescue Errno::EIO
      # PTY finished
    end

    def process_chunk(chunk)
      @buf_mutex.synchronize do
        # split into lines, keep last N lines
        chunk.each_line do |line|
          @buffer << line.chomp
          @buffer.shift while @buffer.size > @lines
        end
      end
    end
  end
end
