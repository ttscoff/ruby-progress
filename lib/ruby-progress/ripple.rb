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
    COLORS.each do |color_name, color_code|
      define_method(color_name) do
        "#{color_code}#{self}#{COLORS['reset']}"
      end
    end

    def rainbow(index = 0)
      chars = self.chars
      colored_chars = chars.map.with_index do |char, idx|
        color = COLORS.values[(idx + index) % COLORS.size]
        "#{color}#{char}#{COLORS['reset']}"
      end
      colored_chars.join
    end

    def normalize_type
      spinner_type = :classic
      INDICATORS.each do |spinner, _v|
        spinner_type = spinner if spinner =~ /^#{chars.join('.*?')}/i
      end
      spinner_type
    end
  end

  # Text ripple animation class
  class Ripple
    attr_accessor :index, :string, :speed, :format, :inverse, :rainbow, :spinner, :spinner_position, :caps

    def initialize(string, options = {})
      defaults = {
        speed: :medium,
        format: :bidirectional,
        rainbow: false,
        spinner: false,
        spinner_position: false,
        caps: false,
        inverse: false,
        output: :error
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
    end

    def printout
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
      $stderr.print "\r\e[2K#{pre}#{char}#{post}"
      $stderr.flush
    end

    # Hide or show the cursor (delegated to Utils)
    def self.hide_cursor
      RubyProgress::Utils.hide_cursor
    end

    def self.show_cursor
      RubyProgress::Utils.show_cursor
    end

    def self.complete(string, message, checkmark, success)
      display_message = message || (checkmark ? string : nil)
      return unless display_message

      RubyProgress::Utils.display_completion(
        display_message,
        success: success,
        show_checkmark: checkmark,
        output_stream: :warn
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
