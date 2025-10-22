# frozen_string_literal: true

module RubyProgress
  # Color definitions for terminal output
  COLORS = {
    'red' => "\e[31m",
    'green' => "\e[32m",
    'yellow' => "\e[33m",
    'blue' => "\e[34m",
    'magenta' => "\e[35m",
    'cyan' => "\e[36m",
    'white' => "\e[37m",
    'dark_red' => "\e[31;1m",
    'dark_green' => "\e[32;1m",
    'dark_yellow' => "\e[33;1m",
    'dark_blue' => "\e[34;1m",
    'dark_magenta' => "\e[35;1m",
    'dark_cyan' => "\e[36;1m",
    'dark_white' => "\e[37;1m",
    'light_red' => "\e[31;2m",
    'light_green' => "\e[32;2m",
    'light_yellow' => "\e[33;2m",
    'light_blue' => "\e[34;2m",
    'light_magenta' => "\e[35;2m",
    'light_cyan' => "\e[36;2m",
    'light_white' => "\e[37;2m",
    'reset' => "\e[0m"
  }.freeze

  # Spinner indicator definitions
  INDICATORS = {
    arc: %w[◜ ◠ ◝ ◞ ◡ ◟],
    arrow: %w[← ↖ ↑ ↗ → ↘ ↓ ↙],
    block_2: %w[▌ ▀ ▐ ▄],
    block_1: %w[▖▖▖ ▘▖▖ ▖▘▖ ▖▖▘],
    bounce: %w[⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈],
    classic: ['|', '/', '—', '\\'],
    dots: %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏],
    dots_2: %w[⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷],
    dots_3: %w[⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓],
    dots_4: %w[⢹ ⢺ ⢼ ⣸ ⣇ ⡧ ⡗ ⡏],
    ellipsis: ['.   ', '..  ', '... ', '....'],
    pipe: %w[┤ ┘ ┴ └ ├ ┌ ┬ ┐],
    pulse: %w[⎺ ⎻ ⎼ ⎽ ⎼ ⎻],
    pulse_2: %w[▁ ▃ ▅ ▆ ▇ █ ▇ ▆ ▅ ▃],
    pulse_3: %w[▉ ▊ ▋ ▌ ▍ ▎ ▏ ▎ ▍ ▌ ▋ ▊ ▉],
    pulse_4: %w[- = ≡ = -],
    o: %w[Ooo oOo ooO],
    spin: %w[◴ ◷ ◶ ◵],
    spin_2: %w[◐ ◓ ◑ ◒],
    spin_3: %w[◰ ◳ ◲ ◱],
    toggle: %w[■ □ ▪ ▫],
    triangle: %w[◢ ◣ ◤ ◥],
    twinkle: %w[⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠]
  }.freeze

  # String extensions for color support
  module StringExtensions
    # Extensions that add colorization helpers to String instances.
    # Methods are dynamically defined from the COLORS map (e.g. #red, #green).
    #
    # Example:
    #   "hello".red #=> "\e[31mhello\e[0m"
    COLORS.each do |color_name, color_code|
      define_method(color_name) do
        "#{color_code}#{self}#{COLORS['reset']}"
      end
    end

    def rainbow(index = 0)
      # Apply a per-character rainbow by cycling through the COLORS map.
      #
      # @param index [Integer] an optional offset to shift the colors
      # @return [String] colorized string where each character is wrapped
      #   in a terminal color escape sequence
      chars = self.chars
      colored_chars = chars.map.with_index do |char, idx|
        color = COLORS.values[(idx + index) % COLORS.size]
        "#{color}#{char}#{COLORS['reset']}"
      end
      colored_chars.join
    end

    def normalize_type
      # Attempt to guess a spinner indicator type from this string's
      # characters. Returns a symbol matching one of INDICATORS keys or
      # :classic as fallback.
      #
      # @return [Symbol]
      spinner_type = :classic
      INDICATORS.each do |spinner, _v|
        spinner_type = spinner if spinner =~ /^#{chars.join('.*?')}/i
      end
      spinner_type
    end
  end

  # Text ripple animation class
  class Ripple
    # Public API:
    # - instance: #advance, #printout
    # - class: .progress (block-based helper), .complete
    attr_accessor :index, :string, :speed, :format, :inverse, :rainbow, :spinner, :spinner_position, :caps

    def initialize(string, options = {})
      # Create a new Ripple animation for the given string.
      #
      # @param string [String] the text to animate
      # @param options [Hash] configuration options (speed, format, rainbow, etc.)
      # @option options [Symbol] :speed (:medium) animation speed :fast/:medium/:slow
      # @option options [Symbol] :format (:bidirectional) :bidirectional/:forward_only
      # @option options [Boolean] :rainbow (false) colorize characters individually
      # @option options [Boolean] :spinner (false) use a spinner glyph instead of ripple
      # @return [void]
      defaults = {
        speed: :medium,
        format: :bidirectional,
        rainbow: false,
        spinner: false,
        spinner_position: false,
        caps: false,
        inverse: false,
        output: :error,
        ends: nil
      }
      @options = defaults.merge(options)
      @string = string
      @index = 0
      @direction = :forward
      @rainbow = @options[:rainbow]
      @spinner = @options[:spinner]
      @spinner_position = @options[:spinner_position]
      @caps = @options[:caps]
      @inverse = @options[:inverse]
      @start_chars, @end_chars = RubyProgress::Utils.parse_ends(@options[:ends])
    end

    def printout
      # Render a single frame of the ripple to stderr, preserving any
      # reserved output area managed by OutputCapture.
      #
      # @return [void]
      letters = @string.dup.chars
      i = @index
      if @spinner
        case @spinner_position
        when :before
          pre = "#{INDICATORS[@spinner][i]} "
          post = @string
        else
          pre = "#{@string} "
          post = INDICATORS[@spinner][i]
        end
      elsif @caps
        pre = letters.slice!(0, i).join
        char = letters.slice!(0, 2).join
        post = letters.slice!(0, letters.length).join
        pre = @inverse ? pre.upcase : pre.downcase
        char = @inverse ? char.downcase : char.upcase
        post = @inverse ? post.upcase : post.downcase
      elsif @inverse
        pre = letters.slice!(0, i).join
        pre = @rainbow ? pre.rainbow : pre.extend(StringExtensions).light_white
        char = letters.slice!(0, 2).join
        char = char.extend(StringExtensions).dark_white
        post = letters.slice!(0, letters.length).join
        post = @rainbow ? post.rainbow : post.extend(StringExtensions).light_white
      else
        pre = letters.slice!(0, i).join.extend(StringExtensions).dark_white
        char = letters.slice!(0, 2).join
        char = @rainbow ? char.rainbow(i) : char.extend(StringExtensions).light_white
        post = letters.slice!(0, letters.length).join.extend(StringExtensions).dark_white
      end
      @output_capture&.redraw($stderr)
      $stderr.print "\r\e[2K#{@start_chars}#{pre}#{char}#{post}#{@end_chars}"
      $stderr.flush
    end

    # Hide or show the cursor (delegated to Utils)
    def self.hide_cursor
      RubyProgress::Utils.hide_cursor
    end

    def self.show_cursor
      RubyProgress::Utils.show_cursor
    end

    # Show the cursor in the terminal. Delegates to Utils.
    #
    # @return [void]

    def self.complete(string, message, checkmark, success, icons: {})
      # Display a final completion message for the ripple indicator.
      #
      # @param string [String] fallback message
      # @param message [String,nil] explicit message to show
      # @param checkmark [Boolean] whether to show a checkmark
      # @param success [Boolean] whether the result is success
      # @param icons [Hash] optional icons mapping
      # @return [void]
      display_message = message || (checkmark ? string : nil)
      return unless display_message

      RubyProgress::Utils.display_completion(
        display_message,
        success: success,
        show_checkmark: checkmark,
        output_stream: :warn,
        icons: icons
      )
    end

    def advance
      max = @spinner ? (INDICATORS[@spinner].count - 1) : (@string.length - 1)
      advance = true

      if @index == max && @options[:format] != :forward_only
        @direction = :backward
      elsif @index == max && @options[:format] == :forward_only
        @index = 0
        advance = false
      elsif @index == 0
        @direction = :forward
      end

      if advance
        @index = @direction == :backward ? @index - 1 : @index + 1
      end

      printout

      case @options[:speed]
      when :fast
        sleep 0.05
      when :medium
        sleep 0.1
      else
        sleep 0.2
      end
    end

    def self.progress(string, options = {})
      # Block-style helper which runs the ripple animation while the
      # provided block executes. The cursor is hidden for the duration and
      # restored afterwards. This method attempts to return a sensible
      # value depending on the :output option (see code).
      #
      # @param string [String] the label text to animate
      # @param options [Hash] configuration options forwarded to Ripple.new
      # @yield the work to perform while the animation runs
      # @return [Object,nil] returns block result or boolean depending on :output
      Signal.trap('INT') do
        Thread.current.kill
        nil
      end
      defaults = { speed: :medium,
                   format: :bidirectional,
                   rainbow: false,
                   inverse: false,
                   output: :error }
      options = defaults.merge(options)

      rippler = new(string, options)
      Ripple.hide_cursor
      begin
        thread = Thread.new do
          rippler.advance while true
        end
        result = yield if block_given?
        thread.kill

        if @options[:output] == :error
          $?.exitstatus.zero?
        elsif @options[:output] == :stdout
          result
        else
          nil
        end
      rescue StandardError
        thread&.kill
        nil
      ensure
        Ripple.show_cursor
      end
    end
  end
end

# Extend String class with color methods
class String
  include RubyProgress::StringExtensions
end
