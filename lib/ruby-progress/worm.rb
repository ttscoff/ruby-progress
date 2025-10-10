# frozen_string_literal: true

require 'optparse'
require 'open3'
require 'json'
require_relative 'utils'

module RubyProgress
  # Animated progress indicator with ripple effect using Unicode combining characters
  class Worm
    # Ripple effect styles
    RIPPLE_STYLES = {
      'circles' => {
        baseline: '·',  # middle dot
        midline: '●',   # black circle
        peak: '⬤' # large circle
      },
      'blocks' => {
        baseline: '▁',  # lower eighth block
        midline: '▄',   # lower half block
        peak: '█'       # full block
      },
      'geometric' => {
        baseline: '▪',  # small black square
        midline: '▫',   # small white square
        peak: '■'       # large black square
      },
      'cirlces_small' => {
        baseline: '∙',
        midline: '∙',
        peak: '●'
      },
      'arrow' => {
        baseline: '▹',
        midline: '▸',
        peak: '▶'
      },
      'balloon' => {
        baseline: '.',
        midline: 'o',
        peak: '°'
      },
      'circle_open' => {
        baseline: '○',
        midline: '●',
        peak: '○'
      }
    }.freeze

    # Speed mappings
    SPEED_MAP = {
      'slow' => 0.5,
      'medium' => 0.2,
      'fast' => 0.1
    }.freeze

    def initialize(options = {})
      @length = options[:length] || 3
      @message = options[:message]
      @speed = parse_speed(options[:speed] || 'medium')
      @style = parse_style(options[:style] || 'circles')
      @command = options[:command]
      @success_text = options[:success]
      @error_text = options[:error]
      @show_checkmark = options[:checkmark] || false
      @output_stdout = options[:stdout] || false
      @running = false
    end

    def animate(message: nil, success: nil, error: nil, &block)
      @message = message if message
      @success_text = success if success
      @error_text = error if error
      @running = true

      # Set up interrupt handler to ensure cursor is restored
      original_int_handler = Signal.trap('INT') do
        @running = false
        RubyProgress::Utils.clear_line
        RubyProgress::Utils.show_cursor
        exit 130
      end

      # Hide cursor
      RubyProgress::Utils.hide_cursor

      animation_thread = Thread.new { animation_loop }

      begin
        if block_given?
          result = yield
          @running = false
          animation_thread.join
          display_completion_message(@success_text, true)
          result
        else
          animation_thread.join
        end
      rescue StandardError => e
        @running = false
        animation_thread.join
        display_completion_message(@error_text || "Error: #{e.message}", false)
        nil # Return nil instead of re-raising when used as a progress indicator
      ensure
        # Always clear animation line and restore cursor
        $stderr.print "\r\e[2K"
        RubyProgress::Utils.show_cursor
        Signal.trap('INT', original_int_handler) if original_int_handler
      end
    end

    def run_with_command
      return unless @command

      exit_code = 0
      stdout_content = nil

      begin
        stdout_content = animate do
          # Use popen3 instead of capture3 for better signal handling
          Open3.popen3(@command) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            captured_stdout = stdout.read
            stderr_content = stderr.read
            exit_code = wait_thr.value.exitstatus

            unless wait_thr.value.success?
              error_msg = @error_text || "Command failed with exit code #{exit_code}"
              error_msg += ": #{stderr_content.strip}" if stderr_content && !stderr_content.empty?
              raise StandardError, error_msg
            end
            captured_stdout
          end
        end

        # Output to stdout if --stdout flag is set
        puts stdout_content if @output_stdout && stdout_content
      rescue StandardError => e
        # animate method handles error display, just exit with proper code
        exit exit_code.nonzero? || 1
      rescue Interrupt
        exit 130
      end
    end

    def run_indefinitely
      # Set up interrupt handler to ensure cursor is restored
      original_int_handler = Signal.trap('INT') do
        @running = false
        RubyProgress::Utils.clear_line
        RubyProgress::Utils.show_cursor
        exit 130
      end

      @running = true
      RubyProgress::Utils.hide_cursor

      begin
        animation_loop
      ensure
        RubyProgress::Utils.show_cursor
        Signal.trap('INT', original_int_handler) if original_int_handler
      end
    end

    def stop
      @running = false
    end

    def run_daemon_mode(success_message: nil, show_checkmark: false, control_message_file: nil)
      @running = true
      stop_requested = false

      # Set up signal handlers
      original_int_handler = Signal.trap('INT') { stop_requested = true }
      Signal.trap('USR1') { stop_requested = true }
      Signal.trap('TERM') { stop_requested = true }
      Signal.trap('HUP')  { stop_requested = true }

      RubyProgress::Utils.hide_cursor

      begin
        animation_loop_daemon_mode(stop_requested_proc: -> { stop_requested })
      ensure
        RubyProgress::Utils.clear_line
        RubyProgress::Utils.show_cursor

        # Display stop-time completion message, preferring control file if provided
        final_message = success_message
        final_checkmark = show_checkmark
        final_success = true
        if control_message_file && File.exist?(control_message_file)
          begin
            data = JSON.parse(File.read(control_message_file))
            final_message = data['message'] if data['message']
            final_checkmark = !!data['checkmark'] if data.key?('checkmark')
            final_success = !!data['success'] if data.key?('success')
          rescue StandardError
            # ignore parse errors, fallback to provided message
          ensure
            begin
              File.delete(control_message_file)
            rescue StandardError
              nil
            end
          end
        end

        if final_message
          RubyProgress::Utils.display_completion(
            final_message,
            success: final_success,
            show_checkmark: final_checkmark,
            output_stream: :stdout
          )
        end

        Signal.trap('INT', original_int_handler) if original_int_handler
      end
    end

    def animation_loop_step
      return unless @running

      @position ||= 0
      @direction ||= 1

      message_part = @message && !@message.empty? ? "#{@message} " : ''
      $stderr.print "\r\e[2K#{message_part}#{generate_dots(@position, @direction)}"
      $stderr.flush

      sleep @speed

      # Update position and direction
      @position += @direction
      if @position >= @length - 1
        @direction = -1
      elsif @position <= 0
        @direction = 1
      end
    end

    private

    def display_completion_message(message, success)
      return unless message
      
      mark = ''
      if @show_checkmark
        mark = success ? '✅ ' : '🛑 '
      end

      # Clear animation line and output completion message on stderr
      $stderr.print "\r\e[2K#{mark}#{message}\n"
    end

    def parse_speed(speed_input)
      case speed_input
      when String
        if speed_input.match?(/^\d+$/)
          # Numeric string (1-10)
          speed_num = speed_input.to_i
          return 0.6 - ((speed_num - 1) * 0.05) if speed_num.between?(1, 10)
        end

        # Check for abbreviated forms
        speed_lower = speed_input.downcase
        if speed_lower.start_with?('f')
          SPEED_MAP['fast']
        elsif speed_lower.start_with?('m')
          SPEED_MAP['medium']
        elsif speed_lower.start_with?('s')
          SPEED_MAP['slow']
        else
          SPEED_MAP['medium']
        end
      when Numeric
        speed_num = speed_input.to_i
        speed_num.between?(1, 10) ? 0.6 - ((speed_num - 1) * 0.05) : SPEED_MAP['medium']
      else
        SPEED_MAP['medium']
      end
    end

    def parse_style(style_input)
      return RIPPLE_STYLES['circles'] unless style_input && !style_input.to_s.strip.empty?

      style_lower = style_input.to_s.downcase.strip

      # First, try exact match
      return RIPPLE_STYLES[style_lower] if RIPPLE_STYLES.key?(style_lower)

      # Then try prefix matching - keys that start with the input
      prefix_matches = RIPPLE_STYLES.keys.select do |key|
        key.downcase.start_with?(style_lower)
      end

      unless prefix_matches.empty?
        # For prefix matches, return the shortest one
        best_match = prefix_matches.min_by(&:length)
        return RIPPLE_STYLES[best_match]
      end

      # Try character-by-character fuzzy matching for partial inputs
      # Find keys where the input characters appear in order (not necessarily contiguous)
      fuzzy_matches = RIPPLE_STYLES.keys.select do |key|
        key_chars = key.downcase.chars
        input_chars = style_lower.chars

        # Check if all input characters appear in order in the key
        input_chars.all? do |char|
          idx = key_chars.index(char)
          if idx
            key_chars = key_chars[idx + 1..-1] # Remove matched chars and continue
            true
          else
            false
          end
        end
      end

      unless fuzzy_matches.empty?
        # Sort by length (prefer shorter keys)
        best_match = fuzzy_matches.min_by(&:length)
        return RIPPLE_STYLES[best_match]
      end

      # Fallback to substring matching
      substring_matches = RIPPLE_STYLES.keys.select do |key|
        key.downcase.include?(style_lower)
      end

      unless substring_matches.empty?
        best_match = substring_matches.min_by(&:length)
        return RIPPLE_STYLES[best_match]
      end

      # Default fallback
      RIPPLE_STYLES['circles']
    end

    def animation_loop
      position = 0
      direction = 1

      while @running
        message_part = @message && !@message.empty? ? "#{@message} " : ''
        # Enhanced line clearing for better daemon mode behavior
        $stderr.print "\r\e[2K#{message_part}#{generate_dots(position, direction)}"
        $stderr.flush

        sleep @speed

        position += direction
        if position >= @length - 1
          direction = -1
        elsif position <= 0
          direction = 1
        end
      end
    end

    # Enhanced animation loop for daemon mode with aggressive line clearing
    def animation_loop_daemon_mode(stop_requested_proc: -> { false })
      position = 0
      direction = 1
      frame_count = 0

      while @running && !stop_requested_proc.call
        message_part = @message && !@message.empty? ? "#{@message} " : ''

        # Always clear current line
        $stderr.print "\r\e[2K"

        # Every few frames, use aggressive clearing to handle interruptions
        if (frame_count % 10).zero?
          $stderr.print "\e[1A\e[2K"   # Move up and clear that line too (in case of interruption)
          $stderr.print "\r"           # Return to start
        end

        $stderr.print "#{message_part}#{generate_dots(position, direction)}"
        $stderr.flush

        sleep @speed
        frame_count += 1

        position += direction
        if position >= @length - 1
          direction = -1
        elsif position <= 0
          direction = 1
        end
      end
    end

    def generate_dots(ripple_position, direction)
      dots = Array.new(@length) { @style[:baseline] }

      # Apply ripple effect
      (0...@length).each do |i|
        distance = (i - ripple_position).abs
        case distance
        when 0
          dots[i] = @style[:peak]
        when 1
          # When moving left, midline appears to the right of peak
          # When moving right, midline appears to the left of peak
          if direction == -1 # moving left
            dots[i] = @style[:midline] if i > ripple_position
          elsif i < ripple_position # moving right
            dots[i] = @style[:midline]
          end
        else
          dots[i] = @style[:baseline]
        end
      end

      dots.join
    end

    # Terminal utilities moved to RubyProgress::Utils
  end
end
