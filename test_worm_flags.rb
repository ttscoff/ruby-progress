#!/usr/bin/env ruby

# Test script to demonstrate the new --stdout and --checkmark flags in worm.rb

puts "Testing worm.rb with new flags:"
puts

puts "1. Testing --checkmark flag with success:"
system("ruby worm.rb --command 'echo Hello World' --message 'Running test' --success 'Test passed!' --checkmark")
puts

puts "2. Testing --stdout flag:"
system("ruby worm.rb --command 'echo This output will be displayed' --message 'Capturing output' --stdout")
puts

puts "3. Testing both --checkmark and --stdout together:"
system("ruby worm.rb --command 'echo Combined test output' --message 'Testing both flags' --success 'Both flags work!' --checkmark --stdout")
puts

puts "4. Testing --checkmark with failure:"
system("ruby worm.rb --command 'exit 1' --message 'Testing failure' --error 'Test failed!' --checkmark")
puts

puts "All tests completed!"