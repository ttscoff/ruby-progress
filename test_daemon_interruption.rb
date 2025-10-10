#!/usr/bin/env ruby
# Test script to explore terminal cursor behavior with daemon output interruption

require_relative 'lib/ruby-progress'

puts 'Testing daemon output interruption behavior...'
puts 'This will start a daemon and then output some text to see what happens.'

# Start a daemon
system("ruby -I lib bin/prg worm --daemon --message 'Testing daemon animation' &")

sleep 1

puts 'This output should interrupt the animation'
puts 'And this is a second line of output'

sleep 2

puts 'More interrupting output after animation has been running'

sleep 2

# Stop the daemon
system('ruby -I lib bin/prg --stop-all')

puts 'Test completed'
