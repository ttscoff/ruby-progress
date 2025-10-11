# frozen_string_literal: true

# Experimental terminal line protection for daemon mode
# This demonstrates potential solutions for the daemon output interruption problem

module RubyProgress
  module SmartTerminal
    # Save current cursor position
    def self.save_cursor_position
      $stderr.print "\e[s" # Save cursor position
      $stderr.flush
    end

    # Restore cursor to saved position
    def self.restore_cursor_position
      $stderr.print "\e[u" # Restore cursor position
      $stderr.flush
    end

    # Get current cursor position (requires terminal interaction)
    def self.get_cursor_position
      # This is complex and requires reading from stdin
      # which may not work reliably in daemon mode
      $stderr.print "\e[6n" # Request cursor position
      $stderr.flush
      # Would need to read response: "\e[{row};{col}R"
      # But this requires terminal input capability
    end

    # Alternative: Use absolute positioning
    def self.position_cursor_absolute(row, col)
      $stderr.print "\e[#{row};#{col}H"
      $stderr.flush
    end

    # Enhanced line clearing that works from any position
    def self.clear_current_line_and_reposition
      $stderr.print "\r"        # Move to start of line
      $stderr.print "\e[2K"     # Clear entire line
      $stderr.print "\e[1A"     # Move up one line (in case we're on a new line)
      $stderr.print "\r"        # Move to start again
      $stderr.print "\e[2K"     # Clear that line too
      $stderr.flush
    end

    # Experimental: Try to "reclaim" the animation line
    def self.reclaim_animation_line(animation_text)
      # Strategy: Clear multiple lines and reposition
      $stderr.print "\r"        # Go to start of current line
      $stderr.print "\e[2K"     # Clear current line
      $stderr.print "\e[1A"     # Move up one line
      $stderr.print "\e[2K"     # Clear that line
      $stderr.print animation_text # Print our animation
      $stderr.flush
    end
  end
end
