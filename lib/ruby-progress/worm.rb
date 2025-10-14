# frozen_string_literal: true

require 'optparse'
require 'open3'
require 'json'
require_relative 'utils'
require_relative 'cli/worm_runner'

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
      @output_lines = options[:output_lines]
      @output_position = options[:output_position]
      @output_live = options[:stdout_live] || false
      @direction_mode = options[:direction] || :bidirectional
      @start_chars, @end_chars = RubyProgress::Utils.parse_ends(options[:ends])
      @running = false
    end
    include WormRunner

    private

    def display_completion_message(message, success)
      return unless message

      # Delegate to Utils.display_completion so carriage-return and clearing
      # behavior is consistent across all indicators and respects TTY state.
      RubyProgress::Utils.display_completion(
        message,
        success: success,
        show_checkmark: @show_checkmark,
        output_stream: :warn
      )
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

      style_str = style_input.to_s.strip

      # Check for custom style format: custom=abc or custom_abc or customXabc
      if style_str.match(/^custom[_=](.+)$/i)
        custom_chars = Regexp.last_match(1)
        return parse_custom_style(custom_chars)
      end

      style_lower = style_str.downcase

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

    def parse_custom_style(custom_chars)
      # Split into individual characters, properly handling multi-byte characters (emojis)
      chars = custom_chars.each_char.to_a

      # Ensure we have exactly 3 characters
      if chars.length != 3
        # Fallback to default if not exactly 3 characters
        return RIPPLE_STYLES['circles']
      end

      # Create custom style hash with baseline, midline, peak
      {
        baseline: chars[0],
        midline: chars[1],
        peak: chars[2]
      }
    end

    # animation_loop and animation_loop_daemon_mode are implemented in
    # the WormRunner module so they can share the redraw behavior that
    # integrates with RubyProgress::OutputCapture. Do not redefine them
    # here, otherwise the module implementations (which call
    # @output_capture&.redraw) will be overridden.

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
