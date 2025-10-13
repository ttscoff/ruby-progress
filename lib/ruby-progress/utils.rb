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

    def self.clear_line(output_stream = :stderr)
      io = case output_stream
           when :stdout
             $stdout
           when :stderr
             $stderr
           else
             # allow passing an IO-like object (e.g. StringIO) directly
             output_stream.respond_to?(:print) ? output_stream : $stderr
           end

      io.print "\r\e[K"
    end

    # Enhanced line clearing for daemon mode that handles output interruption
    def self.clear_line_aggressive
      $stderr.print "\r\e[2K"    # Clear entire current line
      $stderr.print "\e[1A\e[2K" # Move up one line and clear it too
      $stderr.print "\r"         # Return to start of line
    end

    # Universal completion message display
    # @param message [String] The message to display
    # @param success [Boolean] Whether this represents success or failure
    # @param show_checkmark [Boolean] Whether to show checkmark/X symbols
    # @param output_stream [Symbol] Where to output (:stdout, :stderr, :warn)
    def self.display_completion(message, success: true, show_checkmark: false, output_stream: :warn, icons: {})
      return unless message

      mark = if show_checkmark
               icon = success ? (icons[:success] || '✅') : (icons[:error] || '🛑')
               "#{icon} "
             else
               ''
             end

      formatted_message = "#{mark}#{message}"

      # Resolve destination IO: support symbols (:stdout/:stderr/:warn) or an IO-like object
      dest_io = case output_stream
                when :stdout
                  $stdout
                when :stderr
                  $stderr
                when :warn
                  $stderr
                else
                  output_stream.respond_to?(:print) ? output_stream : $stderr
                end

      # For "warn" behavior we clear the current line first. For other explicit IOs
      # we also clear, but honor whether the IO is a TTY.
      if output_stream == :warn || dest_io.respond_to?(:print)
        if dest_io.respond_to?(:tty?) && dest_io.tty?
          dest_io.print "\r\e[2K"
        else
          dest_io.print "\e[2K"
        end
        dest_io.flush if dest_io.respond_to?(:flush)
      end

      # Emit the message to the resolved destination IO. Use warn/puts when targeting
      # the standard streams to preserve familiar behavior (warn writes to $stderr).
      if dest_io == $stdout
        $stdout.puts formatted_message
      elsif dest_io == $stderr
        warn formatted_message
      else
        dest_io.puts formatted_message
      end
    end

    # Clear current line and display completion message
    # Convenience method that combines line clearing with message display
    def self.complete_with_clear(message, success: true, show_checkmark: false, output_stream: :warn, icons: {})
      clear_line(output_stream) if output_stream != :warn # warn already includes clear in display_completion
      display_completion(message, success: success, show_checkmark: show_checkmark, output_stream: output_stream, icons: icons)
    end

    # Parse start/end characters for animation wrapping
    # @param ends_string [String] Even-length string to split in half for start/end chars
    # @return [Array<String>] Array with [start_chars, end_chars]
    def self.parse_ends(ends_string)
      return ['', ''] unless ends_string && !ends_string.empty?

      chars = ends_string.each_char.to_a
      return ['', ''] if chars.length.odd? || chars.empty?

      mid_point = chars.length / 2
      start_chars = chars[0...mid_point].join
      end_chars = chars[mid_point..-1].join

      [start_chars, end_chars]
    end

    # Validate ends string: must be non-empty and even-length (handles multi-byte chars)
    def self.ends_valid?(ends_string)
      return false unless ends_string && !ends_string.empty?

      chars = ends_string.each_char.to_a
      !chars.empty? && (chars.length % 2).zero?
    end
  end
end
