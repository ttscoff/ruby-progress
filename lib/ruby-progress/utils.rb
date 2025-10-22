# frozen_string_literal: true

module RubyProgress
  # Universal terminal utilities shared between progress indicators.
  #
  # This module provides common functionality for terminal manipulation,
  # cursor control, and output formatting used across all progress indicator types.
  module Utils
    # Hides the terminal cursor.
    #
    # @return [void]
    # @example
    #   RubyProgress::Utils.hide_cursor
    def self.hide_cursor
      $stderr.print "\e[?25l"
    end

    # Shows the terminal cursor.
    #
    # @return [void]
    # @example
    #   RubyProgress::Utils.show_cursor
    def self.show_cursor
      $stderr.print "\e[?25h"
    end

    # Clears the current terminal line.
    #
    # @param output_stream [Symbol, IO] Stream to clear (:stdout, :stderr, or IO object)
    # @return [void]
    # @example Clear to stderr (default)
    #   RubyProgress::Utils.clear_line
    # @example Clear to stdout
    #   RubyProgress::Utils.clear_line(:stdout)
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

    # Enhanced line clearing for daemon mode that handles output interruption.
    #
    # Clears the current line and the line above it, useful when daemon
    # output has been interrupted by other command output.
    #
    # @return [void]
    # @example
    #   RubyProgress::Utils.clear_line_aggressive
    def self.clear_line_aggressive
      $stderr.print "\r\e[2K"    # Clear entire current line
      $stderr.print "\e[1A\e[2K" # Move up one line and clear it too
      $stderr.print "\r"         # Return to start of line
    end

    # Displays a completion message with optional icons and formatting.
    #
    # Universal completion message display that handles success/error states,
    # custom icons, and output stream selection.
    #
    # @param message [String] The message to display
    # @param success [Boolean] Whether this represents success (true) or failure (false)
    # @param show_checkmark [Boolean] Whether to show checkmark/X symbols
    # @param output_stream [Symbol, IO] Where to output (:stdout, :stderr, :warn, or IO object)
    # @param icons [Hash] Custom icons hash with :success and :error keys
    # @option icons [String] :success Custom success icon (overrides default ✅)
    # @option icons [String] :error Custom error icon (overrides default 🛑)
    # @return [void]
    # @example Basic success message
    #   RubyProgress::Utils.display_completion("Done!", success: true, show_checkmark: true)
    # @example With custom icons
    #   RubyProgress::Utils.display_completion("Build complete",
    #     success: true,
    #     show_checkmark: true,
    #     icons: { success: '🚀', error: '💥' })
    def self.display_completion(message, success: true, show_checkmark: false, output_stream: :warn, icons: {})
      return unless message

      # Determine the mark to show. If checkmarks are enabled, prefer the
      # default icons but allow overrides via icons hash. If checkmarks are not
      # enabled, still show a custom icon when provided via CLI options.
      mark = ''
      if show_checkmark
        icon = success ? (icons[:success] || '✅') : (icons[:error] || '🛑')
        mark = "#{icon} "
      else
        custom_icon = success ? icons[:success] : icons[:error]
        mark = custom_icon ? "#{custom_icon} " : ''
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

      # Only treat explicit :stdout and :stderr as non-clearing requests.
      # For :warn and any other/custom stream, clear the current line first.
      unless %i[stdout stderr].include?(output_stream)
        # Always include a leading carriage return when clearing to match
        # terminal behavior expected by the test-suite.
        dest_io.print "\r\e[2K"
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

    # Clears the current line and displays a completion message.
    #
    # Convenience method that combines line clearing with message display.
    # Note: When output_stream is :warn, line clearing is already included
    # in display_completion.
    #
    # @param message [String] The message to display
    # @param success [Boolean] Whether this represents success (true) or failure (false)
    # @param show_checkmark [Boolean] Whether to show checkmark/X symbols
    # @param output_stream [Symbol, IO] Where to output (:stdout, :stderr, :warn, or IO object)
    # @param icons [Hash] Custom icons hash with :success and :error keys
    # @return [void]
    # @see display_completion
    # @example
    #   RubyProgress::Utils.complete_with_clear("Task complete", success: true, show_checkmark: true)
    def self.complete_with_clear(message, success: true, show_checkmark: false, output_stream: :warn, icons: {})
      clear_line(output_stream) if output_stream != :warn # warn already includes clear in display_completion
      display_completion(message, success: success, show_checkmark: show_checkmark, output_stream: output_stream, icons: icons)
    end

    # Parses start/end characters for animation wrapping.
    #
    # Takes an even-length string and splits it in half to create start
    # and end decorative characters for progress indicators. Handles
    # multi-byte characters correctly.
    #
    # @param ends_string [String, nil] Even-length string to split in half
    # @return [Array<String>] Array with [start_chars, end_chars]
    # @example Basic decoration
    #   RubyProgress::Utils.parse_ends("[]")  # => ["[", "]"]
    # @example Multi-character decoration
    #   RubyProgress::Utils.parse_ends("<<>>")  # => ["<<", ">>"]
    # @example Emoji decoration
    #   RubyProgress::Utils.parse_ends("🎯🎪")  # => ["🎯", "🎪"]
    # @example Empty or nil input
    #   RubyProgress::Utils.parse_ends(nil)  # => ["", ""]
    def self.parse_ends(ends_string)
      return ['', ''] unless ends_string && !ends_string.empty?

      chars = ends_string.each_char.to_a
      return ['', ''] if chars.length.odd? || chars.empty?

      mid_point = chars.length / 2
      start_chars = chars[0...mid_point].join
      end_chars = chars[mid_point..-1].join

      [start_chars, end_chars]
    end

    # Validates an ends string for proper format.
    #
    # Checks that the string is non-empty and has an even number of
    # characters (handles multi-byte characters correctly).
    #
    # @param ends_string [String, nil] String to validate
    # @return [Boolean] true if valid, false otherwise
    # @example Valid strings
    #   RubyProgress::Utils.ends_valid?("[]")  # => true
    #   RubyProgress::Utils.ends_valid?("🎯🎪")  # => true
    # @example Invalid strings
    #   RubyProgress::Utils.ends_valid?("abc")  # => false (odd length)
    #   RubyProgress::Utils.ends_valid?("")     # => false (empty)
    #   RubyProgress::Utils.ends_valid?(nil)    # => false (nil)
    def self.ends_valid?(ends_string)
      return false unless ends_string && !ends_string.empty?

      chars = ends_string.each_char.to_a
      !chars.empty? && (chars.length % 2).zero?
    end
  end
end
