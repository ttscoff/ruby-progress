#!/usr/bin/env ruby
# frozen_string_literal: true

# Short demo script for interactive/manual testing of ruby-progress features.
# Focuses on a compact set of examples used during development and quick checks.
##
#
# A shorter, more focused demo script for quick testing and demonstrations.
# This version focuses on the most impressive features without long pauses.
# QuickDemo: small, focused demo runner used for development and CI smoke tests.
class QuickDemo
  def initialize
    @gem_path = File.expand_path('bin/prg', __dir__)
    @lib_path = File.expand_path('lib', __dir__)
  end

  def run
    puts "\n🚀 Ruby Progress Gem v1.2.2 - Quick Demo\n"
    puts "=========================================\n\n"

    # Showcase the most impressive features
    showcase_ends_feature
    showcase_custom_styles
    showcase_direction_control
    showcase_error_handling

    puts "\n✨ Demo complete! Install with: gem install ruby-progress"
    puts "📚 GitHub: https://github.com/ttscoff/ruby-progress\n\n"
  end

  private

  def showcase_ends_feature
    puts '🎯 Universal --ends Flag (NEW in v1.2.0)'
    puts '-' * 40

    puts 'Ripple with brackets:'
    run_cmd("ripple 'Loading...' --ends '[]' --command 'sleep 3' --success 'Bracketed!' --checkmark")

    puts "\nWorm with angles:"
    run_cmd("worm --length 10 --ends '<<>>' --command 'sleep 3' --success 'Angled!' --checkmark")

    puts "\nTwirl with emojis:"
    run_cmd("twirl --ends '♥️👍' --command 'sleep 2' --success 'Decorated!'")

    puts "\n"
  end

  def showcase_custom_styles
    puts '🎨 Custom Worm Styles (NEW in v1.2.0)'
    puts '-' * 40

    puts 'ASCII custom pattern:'
    run_cmd("worm --length 10 --style custom=_-= --command 'sleep 3' --success 'Custom ASCII!'")

    puts "\nEmoji custom pattern:"
    run_cmd("worm --length 10 --style custom=🟦🟨🟥 --command 'sleep 3' --success 'Custom emoji!'")

    puts "\n"
  end

  def showcase_direction_control
    puts '🏃 Direction Control (NEW in v1.2.0)'
    puts '-' * 40

    puts 'Forward-only worm:'
    run_cmd("worm --length 10 --direction forward --command 'sleep 4' --success 'Always forward!'")

    puts "\nCombined features:"
    run_cmd("worm --length 10 --style custom=.*🟡 --direction forward --ends '【】' --command 'sleep 4' --success 'Ultimate combo!'")

    puts "\n"
  end

  def showcase_error_handling
    puts '❌ Error Handling'
    puts '-' * 40

    puts 'Graceful failure:'
    run_cmd("ripple 'Processing...' --command 'sleep 2 && exit 1' --error 'Task failed!' --checkmark")

    puts "\n"
  end

  def print_command(args)
    # ANSI color codes
    cyan = "\e[36m"
    bright_red = "\e[91m"
    bright_white = "\e[97m"
    bright_green = "\e[92m"
    reset = "\e[0m"

    # Start with the base command
    colored_cmd = "$ #{cyan}prg#{reset}"

    # Use regex to colorize the command
    # First capture the subcommand (ripple, worm, twirl)
    colored_args = args.gsub(/^(ripple|worm|twirl)/, "#{bright_red}\\1#{reset}")

    # Colorize flags (--flag-name) in bright white and their values in bright green
    colored_args = colored_args.gsub(/(--[\w-]+)(\s+|=)('[^']*'|"[^"]*"|\S+)/) do |_match|
      flag = ::Regexp.last_match(1)
      separator = ::Regexp.last_match(2)
      value = ::Regexp.last_match(3)
      "#{bright_white}#{flag}#{reset}#{separator}#{bright_green}#{value}#{reset}"
    end

    # Colorize short flags (-f) in bright white and their values in bright green
    colored_args = colored_args.gsub(/(-[a-zA-Z])(\s+)('[^']*'|"[^"]*"|\S+)/) do |_match|
      flag = ::Regexp.last_match(1)
      separator = ::Regexp.last_match(2)
      value = ::Regexp.last_match(3)
      "#{bright_white}#{flag}#{reset}#{separator}#{bright_green}#{value}#{reset}"
    end

    puts "#{colored_cmd} #{colored_args}"
  end

  def run_cmd(args)
    full_cmd = "ruby -I #{@lib_path} #{@gem_path} #{args}"
    print_command(args)
    system(full_cmd)
    puts
  end
end

# Quick execution
if __FILE__ == $PROGRAM_NAME
  begin
    QuickDemo.new.run
  rescue Interrupt
    puts "\n\nDemo stopped. Thanks!"
  end
end
