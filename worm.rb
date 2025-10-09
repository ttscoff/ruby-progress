#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'open3'

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
    @message = options[:message] || 'Processing'
    @speed = parse_speed(options[:speed] || 'medium')
    @style = parse_style(options[:style] || 'circles')
    @command = options[:command]
    @success_text = options[:success]
    @error_text = options[:error]
    @show_checkmark = options[:checkmark] || false
    @output_stdout = options[:stdout] || false
    @running = false
  end

  def self.run_cli
    options = parse_cli_options
    progress = new(options)

    if options[:command]
      progress.run_with_command
    else
      # Run indefinitely like ripple does when no command is specified
      progress.run_indefinitely
    end
  end

  def animate(message: nil, success: nil, error: nil, &block)
    @message = message if message
    @success_text = success if success
    @error_text = error if error
    @running = true

    # Set up interrupt handler to ensure cursor is restored
    original_int_handler = Signal.trap('INT') do
      @running = false
      clear_line
      show_cursor
      puts "\nInterrupted!"
      exit 130
    end

    # Hide cursor
    hide_cursor

    animation_thread = Thread.new { animation_loop }

    begin
      if block_given?
        result = yield
        @running = false
        animation_thread.join
        clear_line
        display_completion_message(@success_text || 'Done!', true)
        result
      else
        animation_thread.join
      end
    rescue StandardError => e
      @running = false
      animation_thread.join
      clear_line
      display_completion_message(@error_text || "Error: #{e.message}", false)
      nil # Return nil instead of re-raising when used as a progress indicator
    ensure
      # Always restore cursor and signal handler
      show_cursor
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
      puts "\nInterrupted!"
      exit 130
    end
  end

  def run_indefinitely
    # Set up interrupt handler to ensure cursor is restored
    original_int_handler = Signal.trap('INT') do
      @running = false
      clear_line
      show_cursor
      puts "\nInterrupted!"
      exit 130
    end

    @running = true
    hide_cursor

    begin
      animation_loop
    ensure
      show_cursor
      Signal.trap('INT', original_int_handler) if original_int_handler
    end
  end

  def stop
    @running = false
  end

  private

  def display_completion_message(message, success)
    RubyProgress::Utils.clear_line
    RubyProgress::Utils.display_completion(
      message,
      success: success,
      show_checkmark: @show_checkmark,
      output_stream: :stdout
    )
  end

  def parse_speed(speed_input)
    case speed_input
    when String
      if speed_input.match?(/^\d+$/)
        # Numeric string (1-10)
        speed_num = speed_input.to_i
        return 0.6 - (speed_num - 1) * 0.05 if speed_num.between?(1, 10)
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
      speed_num.between?(1, 10) ? 0.6 - (speed_num - 1) * 0.05 : SPEED_MAP['medium']
    else
      SPEED_MAP['medium']
    end
  end

  def parse_style(style_input)
    return RIPPLE_STYLES['circles'] unless style_input

    style_lower = style_input.to_s.downcase
    if style_lower.start_with?('b')
      RIPPLE_STYLES['blocks']
    elsif style_lower.start_with?('g')
      RIPPLE_STYLES['geometric']
    elsif style_lower.start_with?('c')
      RIPPLE_STYLES['circles']
    else
      RIPPLE_STYLES['circles'] # default
    end
  end

  def animation_loop
    position = 0
    direction = 1

    while @running
      print "\r#{@message}#{generate_dots(position, direction)}"
      $stdout.flush

      sleep @speed

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

  def clear_line
    print "\r\e[K"
  end

  def hide_cursor
    print "\e[?25l"
  end

  def show_cursor
    print "\e[?25h"
  end

  def self.parse_cli_options
    options = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ''
      opts.separator 'Options:'

      opts.on('-s', '--speed SPEED', 'Animation speed (1-10, fast, medium, slow, or f/m/s)') do |speed|
        options[:speed] = speed
      end

      opts.on('-l', '--length LENGTH', Integer, 'Number of dots to display') do |length|
        options[:length] = length
      end

      opts.on('-m', '--message MESSAGE', 'Message to display before dots') do |message|
        options[:message] = message
      end

      opts.on('--style STYLE', 'Animation style (blocks, geometric, circles, or b/g/c)') do |style|
        options[:style] = style
      end

      opts.on('-c', '--command COMMAND', 'Command to run (optional - runs indefinitely without command)') do |command|
        options[:command] = command
      end

      opts.on('--success TEXT', 'Text to display on successful completion') do |text|
        options[:success] = text
      end

      opts.on('--error TEXT', 'Text to display on error') do |text|
        options[:error] = text
      end

      opts.on('--checkmark', 'Show checkmarks (✅/🛑) in completion messages') do
        options[:checkmark] = true
      end

      opts.on('--stdout', 'Output captured command result to STDOUT') do
        options[:stdout] = true
      end

      opts.on('-h', '--help', 'Show this help message') do
        puts opts
        exit
      end
    end.parse!

    options
  end
end

# Run as CLI if this file is executed directly
Worm.run_cli if __FILE__ == $0
