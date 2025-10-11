#!/usr/bin/env ruby
# frozen_string_literal: true

# Ruby Progress Gem Demo Screencast Script
# ========================================
#
# This script creates a comprehensive demonstration of the ruby-progress gem
# showing all major features across the three subcommands: ripple, worm, and twirl.
#
# Usage: ruby demo_screencast.rb
#
# The script includes pauses between demonstrations to allow for narration
# and clear visual separation of different features.

require 'io/console'

class ProgressDemo
  def initialize
    @gem_path = File.expand_path('bin/prg', __dir__)
    @lib_path = File.expand_path('lib', __dir__)

    # Colors for terminal output
    @colors = {
      header: "\e[1;36m",    # Bright cyan
      command: "\e[1;33m",   # Bright yellow
      description: "\e[0;32m", # Green
      reset: "\e[0m",        # Reset
      dim: "\e[2m"           # Dim
    }
  end

  def run
    clear_screen
    show_title

    # Introduction
    show_section_header('Ruby Progress Gem Demo')
    show_description('Demonstrating terminal progress indicators with style!')
    pause_for_narration(3)

    # Basic examples for each command
    demo_basic_commands

    # Style demonstrations
    demo_styles

    # Advanced options
    demo_advanced_options

    # New v1.2.0 features
    demo_new_features

    # Finale
    show_finale
  end

  private

  def demo_basic_commands
    show_section_header('Basic Commands Overview')

    # Ripple - basic expanding circle animation
    show_demo_header('Ripple', 'Expanding circle animation for tasks with unknown duration')
    run_command("#{ruby_cmd} ripple --command 'sleep 4' --success 'Download complete!' --checkmark")
    pause_between_demos

    # Worm - progress bar animation
    show_demo_header('Worm', 'Animated progress bar for visual feedback')
    run_command("#{ruby_cmd} worm --length 10 --command 'sleep 5' --success 'Processing finished!' --checkmark")
    pause_between_demos

    # Twirl - spinning indicator
    show_demo_header('Twirl', 'Classic spinning indicator for quick tasks')
    run_command("#{ruby_cmd} twirl --command 'sleep 3' --success 'Task completed!' --checkmark")
    pause_between_demos
  end

  def demo_styles
    show_section_header('Style Variations')

    # Ripple styles
    show_demo_header('Ripple Styles', 'Different visual patterns')
    show_command_info('Default ripple style')
    run_command("#{ruby_cmd} ripple --command 'sleep 3' --success 'Default style'")
    pause_between_demos(2)

    show_command_info('Pulse style')
    run_command("#{ruby_cmd} ripple --style pulse --command 'sleep 3' --success 'Pulse style'")
    pause_between_demos

    # Worm styles
    show_demo_header('Worm Styles', 'Various progress bar animations')
    show_command_info('Classic worm style')
    run_command("#{ruby_cmd} worm --length 10 --style classic --command 'sleep 4' --success 'Classic worm'")
    pause_between_demos(2)

    show_command_info('Emoji worm style')
    run_command("#{ruby_cmd} worm --length 10 --style emoji --command 'sleep 4' --success 'Emoji worm! 🎉'")
    pause_between_demos(2)

    show_command_info('Blocks worm style')
    run_command("#{ruby_cmd} worm --length 10 --style blocks --command 'sleep 4' --success 'Block worm'")
    pause_between_demos

    # Twirl styles
    show_demo_header('Twirl Styles', 'Different spinning patterns')
    show_command_info('Classic spinner')
    run_command("#{ruby_cmd} twirl --style classic --command 'sleep 3' --success 'Classic spin'")
    pause_between_demos(2)

    show_command_info('Dots spinner')
    run_command("#{ruby_cmd} twirl --style dots --command 'sleep 3' --success 'Dotty!'")
    pause_between_demos(2)

    show_command_info('Arrow spinner')
    run_command("#{ruby_cmd} twirl --style arrow --command 'sleep 3' --success 'Arrow spin'")
    pause_between_demos
  end

  def demo_advanced_options
    show_section_header('Advanced Options')

    # Error handling
    show_demo_header('Error Handling', 'Graceful failure with custom messages')
    show_command_info('Simulating a failed task')
    run_command("#{ruby_cmd} worm --length 10 --command 'sleep 2 && exit 1' --error 'Something went wrong!' --fail-icon")
    pause_between_demos

    # Custom colors (if supported)
    show_demo_header('Success Messages', 'Custom completion messages')
    show_command_info('Custom success message with checkmark')
    run_command("#{ruby_cmd} ripple --command 'sleep 3' --success 'Data synchronized successfully' --checkmark")
    pause_between_demos(2)

    show_command_info('Different success icon')
    run_command("#{ruby_cmd} twirl --command 'sleep 3' --success 'Backup completed' --icon '✓'")
    pause_between_demos

    # No completion message
    show_demo_header('Silent Completion', 'Progress without completion messages')
    show_command_info('Silent completion (no message)')
    run_command("#{ruby_cmd} worm --length 10 --command 'sleep 3'")
    pause_between_demos
  end

  def demo_new_features
    show_section_header('New in v1.2.0 - Enhanced Features')

    # Universal --ends flag
    show_demo_header('Universal --ends Flag', 'Add decorative start/end characters')
    show_command_info("Ripple with square brackets: --ends '[]'")
    run_command("#{ruby_cmd} ripple --ends '[]' --command 'sleep 4' --success 'Framed ripple!'")
    pause_between_demos(2)

    show_command_info("Worm with angle brackets: --ends '<<>>'")
    run_command("#{ruby_cmd} worm --length 10 --ends '<<>>' --command 'sleep 4' --success 'Angled worm!'")
    pause_between_demos(2)

    show_command_info("Twirl with emoji decoration: --ends '🎯🎪'")
    run_command("#{ruby_cmd} twirl --ends '🎯🎪' --command 'sleep 3' --success 'Emoji decorated!'")
    pause_between_demos

    # Worm direction control
    show_demo_header('Worm Direction Control', 'Forward-only vs bidirectional movement')
    show_command_info('Bidirectional worm (default back-and-forth)')
    run_command("#{ruby_cmd} worm --length 10 --direction bidirectional --command 'sleep 5' --success 'Back and forth!'")
    pause_between_demos(2)

    show_command_info('Forward-only worm (resets at end)')
    run_command("#{ruby_cmd} worm --length 10 --direction forward --command 'sleep 5' --success 'Always forward!'")
    pause_between_demos

    # Custom worm styles
    show_demo_header('Custom Worm Styles', 'User-defined 3-character patterns')
    show_command_info('ASCII custom style: --style custom=_-=')
    run_command("#{ruby_cmd} worm --length 10 --style custom=_-= --command 'sleep 4' --success 'Custom ASCII!'")
    pause_between_demos(2)

    show_command_info('Unicode custom style: --style custom=▫▪■')
    run_command("#{ruby_cmd} worm --length 10 --style custom=▫▪■ --command 'sleep 4' --success 'Custom Unicode!'")
    pause_between_demos(2)

    show_command_info('Emoji custom style: --style custom=🟦🟨🟥')
    run_command("#{ruby_cmd} worm --length 10 --style custom=🟦🟨🟥 --command 'sleep 4' --success 'Custom emoji!'")
    pause_between_demos

    # Combining features
    show_demo_header('Feature Combinations', 'Mixing multiple options together')
    show_command_info('Custom style + direction + ends: the full package!')
    run_command("#{ruby_cmd} worm --length 10 --style custom=.🟡* --direction forward --ends '【】' --command 'sleep 5' --success 'Ultimate combo!' --checkmark")
    pause_between_demos
  end

  def show_finale
    show_section_header('Demo Complete!')
    show_description('Ruby Progress Gem v1.2.0 - Making terminal progress beautiful! 🚀')
    puts
    show_description('Key features demonstrated:')
    puts "#{@colors[:description]}  • Three animation types: ripple, worm, twirl#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Multiple built-in styles#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Universal --ends flag for decoration#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Worm direction control#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Custom user-defined styles#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Success/error handling#{@colors[:reset]}"
    puts "#{@colors[:description]}  • Multi-byte character support (Unicode/emoji)#{@colors[:reset]}"
    puts
    show_description('Install: gem install ruby-progress')
    show_description('GitHub: https://github.com/ttscoff/ruby-progress')
    puts
  end

  # Utility methods

  def ruby_cmd
    "ruby -I #{@lib_path} #{@gem_path}"
  end

  def clear_screen
    system('clear') || system('cls')
  end

  def show_title
    puts
    puts "#{@colors[:header]}#{'=' * 60}#{@colors[:reset]}"
    puts "#{@colors[:header]}  RUBY PROGRESS GEM - DEMO SCREENCAST#{@colors[:reset]}"
    puts "#{@colors[:header]}  Version 1.2.0 Feature Demonstration#{@colors[:reset]}"
    puts "#{@colors[:header]}#{'=' * 60}#{@colors[:reset]}"
    puts
  end

  def show_section_header(title)
    puts
    puts "#{@colors[:header]}#{'-' * 50}#{@colors[:reset]}"
    puts "#{@colors[:header]} #{title}#{@colors[:reset]}"
    puts "#{@colors[:header]}#{'-' * 50}#{@colors[:reset]}"
    puts
  end

  def show_demo_header(title, description)
    puts
    puts "#{@colors[:header]}### #{title}#{@colors[:reset]}"
    puts "#{@colors[:description]}#{description}#{@colors[:reset]}"
    puts
  end

  def show_command_info(description)
    puts "#{@colors[:dim]}#{description}#{@colors[:reset]}"
  end

  def show_description(text)
    puts "#{@colors[:description]}#{text}#{@colors[:reset]}"
  end

  def run_command(cmd)
    puts "#{@colors[:command]}$ #{cmd}#{@colors[:reset]}"
    puts
    system(cmd)
    puts
  end

  def pause_for_narration(seconds = 2)
    puts "#{@colors[:dim]}[Pausing #{seconds}s for narration...]#{@colors[:reset]}"
    sleep(seconds)
  end

  def pause_between_demos(seconds = 3)
    puts "#{@colors[:dim]}[Pausing #{seconds}s between demos...]#{@colors[:reset]}"
    sleep(seconds)
  end
end

# Script execution
if __FILE__ == $PROGRAM_NAME
  demo = ProgressDemo.new

  puts 'Ruby Progress Gem Demo Screencast'
  puts '================================='
  puts
  puts 'This script will demonstrate various features of the ruby-progress gem.'
  puts 'Press ENTER to start the demo, or Ctrl+C to exit.'
  puts
  print 'Ready? '
  gets

  begin
    demo.run
  rescue Interrupt
    puts "\n\nDemo interrupted. Thanks for watching!"
    exit(0)
  end
end
