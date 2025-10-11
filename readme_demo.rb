#!/usr/bin/env ruby
# frozen_string_literal: true

# README Demo Script - Ruby Progress Gem
# =====================================
#
# ReadmeDemo: demos and examples intended for inclusion in the README
# and other documentation. Keeps examples compact and easy to run.

class ReadmeDemo
  def initialize
    @gem_path = File.expand_path('bin/prg', __dir__)
    @lib_path = File.expand_path('lib', __dir__)
  end

  def run_all_demos
    puts 'Ruby Progress Gem - README Examples'
    puts '==================================='
    puts

    basic_examples
    style_examples
    new_features_examples
    advanced_examples

    puts "\nAll examples completed!"
  end

  def basic_examples
    section('Basic Usage Examples')

    demo('Basic ripple animation',
         "ripple --command 'sleep 3' --success 'Download complete!'")

    demo('Basic worm progress bar',
         "worm --length 10 --command 'sleep 4' --success 'Processing finished!'")

    demo('Basic spinner',
         "twirl --command 'sleep 2' --success 'Task completed!'")
  end

  def style_examples
    section('Style Variations')

    demo('Ripple pulse style',
         "ripple --style pulse --command 'sleep 3' --success 'Pulsing!'")

    demo('Worm with emoji style',
         "worm --length 10 --style emoji --command 'sleep 3' --success 'Colorful! 🌈'")

    demo('Classic spinner',
         "twirl --style classic --command 'sleep 2' --success 'Spinning!'")
  end

  def new_features_examples
    section('New v1.2.0 Features')

    demo('Universal --ends flag with brackets',
         "ripple --ends '[]' --command 'sleep 3' --success 'Framed!'")

    demo('Worm with custom style',
         "worm --length 10 --style custom=▫▪■ --command 'sleep 3' --success 'Custom blocks!'")

    demo('Forward-only worm direction',
         "worm --length 10 --direction forward --command 'sleep 4' --success 'Always forward!'")

    demo('Emoji decoration',
         "twirl --ends '🎯🎪' --command 'sleep 2' --success 'Decorated!'")

    demo('Ultimate combination',
         "worm --length 10 --style custom=🟦🟨🟥 --direction forward --ends '《》' --command 'sleep 4' --success 'All features!'")
  end

  def advanced_examples
    section('Advanced Features')

    demo('Error handling',
         "worm --length 10 --command 'sleep 2 && exit 1' --error 'Task failed!' --fail-icon")

    demo('Silent completion',
         "ripple --command 'sleep 2'")

    demo('Custom success icon',
         "twirl --command 'sleep 2' --success 'Backup done' --icon '✓'")
  end

  private

  def section(title)
    puts "\n#{'-' * 50}"
    puts " #{title}"
    puts "#{'-' * 50}\n\n"
  end

  def demo(description, command)
    puts "#{description}:"
    puts "$ prg #{command}"
    puts

    full_command = "ruby -I #{@lib_path} #{@gem_path} #{command}"
    system(full_command)

    puts "\n"
    sleep(1) # Brief pause between demos
  end
end

# Command line interface
if __FILE__ == $PROGRAM_NAME
  demo = ReadmeDemo.new

  if ARGV.empty?
    demo.run_all_demos
  else
    case ARGV[0]
    when 'basic'
      demo.basic_examples
    when 'styles'
      demo.style_examples
    when 'new'
      demo.new_features_examples
    when 'advanced'
      demo.advanced_examples
    else
      puts "Usage: #{$PROGRAM_NAME} [basic|styles|new|advanced]"
      puts "       #{$PROGRAM_NAME}     # run all demos"
    end
  end
end
