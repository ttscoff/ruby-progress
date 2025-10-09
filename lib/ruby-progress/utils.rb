# frozen_string_literal: true

module RubyProgress
  # Universal terminal utilities shared between progress indicators
  module Utils
    # Terminal cursor control
    def self.hide_cursor
      $stderr.print "\e[?25l"
    end

    def self.show_cursor
      $stderr.print "\e[?25h"
    end

    def self.clear_line
      print "\r\e[K"
    end

    # Universal completion message display
    # @param message [String] The message to display
    # @param success [Boolean] Whether this represents success or failure
    # @param show_checkmark [Boolean] Whether to show checkmark/X symbols
    # @param output_stream [Symbol] Where to output (:stdout, :stderr, :warn)
    def self.display_completion(message, success: true, show_checkmark: false, output_stream: :warn)
      return unless message

      mark = ''
      if show_checkmark
        mark = success ? '✅ ' : '🛑 '
      end

      formatted_message = "#{mark}#{message}"

      case output_stream
      when :stdout
        puts formatted_message
      when :stderr
        warn formatted_message
      when :warn
        warn "\e[2K#{formatted_message}"
      else
        warn "\e[2K#{formatted_message}"
      end
    end

    # Clear current line and display completion message
    # Convenience method that combines line clearing with message display
    def self.complete_with_clear(message, success: true, show_checkmark: false, output_stream: :warn)
      clear_line if output_stream != :warn # warn already includes clear in display_completion
      display_completion(message, success: success, show_checkmark: show_checkmark, output_stream: output_stream)
    end
  end
end
