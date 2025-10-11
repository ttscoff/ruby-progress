# frozen_string_literal: true

module RubyProgress
  # Determinate progress bar with customizable fill styles
  class Fill
    # Built-in fill styles with empty and full characters
    FILL_STYLES = {
      blocks: { empty: '▱', full: '▰' },
      classic: { empty: '-', full: '=' },
      dots: { empty: '·', full: '●' },
      squares: { empty: '□', full: '■' },
      circles: { empty: '○', full: '●' },
      ascii: { empty: '.', full: '#' },
      bars: { empty: '░', full: '█' },
      arrows: { empty: '▷', full: '▶' },
      stars: { empty: '☆', full: '★' }
    }.freeze

    attr_reader :length, :style, :current_progress, :start_chars, :end_chars
    attr_accessor :success_message, :error_message

    def initialize(options = {})
      @length = options[:length] || 20
      @style = parse_style(options[:style] || :blocks)
      @current_progress = 0
      @success_message = options[:success]
      @error_message = options[:error]

      # Parse --ends characters
      if options[:ends]
        @start_chars, @end_chars = RubyProgress::Utils.parse_ends(options[:ends])
      else
        @start_chars = ''
        @end_chars = ''
      end
    end

    # Advance the progress bar by one step or specified increment
    def advance(increment: 1, percent: nil)
      @current_progress = if percent
                            [@length * percent / 100.0, @length].min.round
                          else
                            [@current_progress + increment, @length].min
                          end

      render
      completed?
    end

    # Set progress to specific percentage (0-100)
    def percent=(percent)
      percent = percent.clamp(0, 100) # Clamp between 0-100
      @current_progress = (@length * percent / 100.0).round
      render
      completed?
    end

    # Check if progress bar is complete
    def completed?
      @current_progress >= @length
    end

    # Get current progress as percentage
    def percent
      (@current_progress.to_f / @length * 100).round(1)
    end

    # Get current progress as float (0.0-100.0) - for scripting
    def current
      (@current_progress.to_f / @length * 100).round(1)
    end

    # Get detailed progress status information
    def report
      {
        progress: [@current_progress, @length],
        percent: current,
        completed: completed?,
        style: @style
      }
    end

    # Render the current progress bar to stderr
    def render
      filled = @style[:full] * @current_progress
      empty = @style[:empty] * (@length - @current_progress)
      bar = "#{@start_chars}#{filled}#{empty}#{@end_chars}"

      $stderr.print "\r\e[2K#{bar}"
      $stderr.flush
    end

    # Complete the progress bar and show success message
    def complete(message = nil)
      @current_progress = @length
      render

      completion_message = message || @success_message
      if completion_message
        RubyProgress::Utils.display_completion(
          completion_message,
          success: true,
          show_checkmark: true,
          output_stream: :warn
        )
      else
        $stderr.puts # Just add a newline if no message
      end
    end

    # Cancel the progress bar and show error message
    def cancel(message = nil)
      $stderr.print "\r\e[2K" # Clear the progress bar
      $stderr.flush

      error_msg = message || @error_message
      return unless error_msg

      RubyProgress::Utils.display_completion(
        error_msg,
        success: false,
        show_checkmark: true,
        output_stream: :warn
      )
    end

    # Hide or show the cursor (delegated to Utils)
    def self.hide_cursor
      RubyProgress::Utils.hide_cursor
    end

    def self.show_cursor
      RubyProgress::Utils.show_cursor
    end

    # Progress with block interface for library usage
    def self.progress(options = {}, &block)
      return unless block_given?

      fill_bar = new(options)
      Fill.hide_cursor

      begin
        fill_bar.render # Show initial empty bar

        # Call the block with the fill bar instance
        result = block.call(fill_bar)

        # Handle completion based on block result or bar state
        if fill_bar.completed? || result == true || result.nil?
          fill_bar.complete
        elsif result == false
          fill_bar.cancel
        end

        result
      rescue StandardError => e
        fill_bar.cancel("Error: #{e.message}")
        raise
      ensure
        Fill.show_cursor
      end
    end

    private

    # Parse style option into empty/full character hash
    def parse_style(style_option)
      case style_option
      when Symbol, String
        style_name = style_option.to_sym
        if FILL_STYLES.key?(style_name)
          FILL_STYLES[style_name]
        else
          FILL_STYLES[:blocks] # Default fallback
        end
      when Hash
        # Allow direct hash specification: { empty: '.', full: '#' }
        {
          empty: style_option[:empty] || '.',
          full: style_option[:full] || '#'
        }
      else
        FILL_STYLES[:blocks] # Default fallback
      end
    end

    class << self
      # Parse custom style string like "custom=.#"
      def parse_custom_style(style_string)
        if style_string.start_with?('custom=')
          chars = style_string.sub('custom=', '')

          # Handle multi-byte characters properly
          char_array = chars.chars

          if char_array.length == 2
            { empty: char_array[0], full: char_array[1] }
          else
            # Invalid custom style, return default
            FILL_STYLES[:blocks]
          end
        else
          # Try to find built-in style
          style_name = style_string.to_sym
          FILL_STYLES[style_name] || FILL_STYLES[:blocks]
        end
      end
    end
  end
end
