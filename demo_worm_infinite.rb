#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showing worm.rb's new infinite mode

puts '=== Worm.rb Infinite Mode Demo ==='
puts

puts '1. Running indefinitely for 3 seconds (like ripple):'
system("timeout 3s ruby worm.rb --message 'Loading...' --speed fast --style circles || echo")
puts

puts '2. Running with command and checkmarks:'
system("ruby worm.rb --command 'sleep 1 && echo Success' --message 'Processing' --success 'Done!' --checkmark --stdout")
puts

puts '3. Running indefinitely with blocks style:'
system("timeout 2s ruby worm.rb --message 'Working' --style blocks --length 6 --speed medium || echo")
puts

puts 'Demo complete! Worm.rb now works like ripple when no command is specified.'
