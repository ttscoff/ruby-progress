#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo of RubyProgress::Utils universal utilities
require_relative '../lib/ruby-progress'

puts '=== RubyProgress::Utils Demo ==='
puts

# Test cursor control
puts 'Testing cursor control...'
print 'Hiding cursor for 2 seconds...'
RubyProgress::Utils.hide_cursor
sleep 2
print ' showing cursor again.'
RubyProgress::Utils.show_cursor
puts
puts

# Test line clearing
puts 'Testing line clearing...'
print 'This line will be cleared...'
sleep 1
RubyProgress::Utils.clear_line
print 'New content on the same line!'
puts
puts

# Test completion messages
puts 'Testing completion messages...'

RubyProgress::Utils.display_completion('Basic success message', success: true)
RubyProgress::Utils.display_completion('Basic failure message', success: false)

puts
puts 'With checkmarks:'
RubyProgress::Utils.display_completion('Success with checkmark', success: true, show_checkmark: true)
RubyProgress::Utils.display_completion('Failure with checkmark', success: false, show_checkmark: true)

puts
puts 'Different output streams:'
RubyProgress::Utils.display_completion('To STDOUT', success: true, show_checkmark: true, output_stream: :stdout)
RubyProgress::Utils.display_completion('To STDERR', success: false, show_checkmark: true, output_stream: :stderr)

puts
puts 'Complete with clear:'
print 'Content to be cleared and replaced...'
sleep 1
RubyProgress::Utils.complete_with_clear('Cleared and completed!', success: true, show_checkmark: true,
                                                                  output_stream: :stdout)

puts
puts '=== Demo Complete ==='
