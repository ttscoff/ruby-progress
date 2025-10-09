#!/usr/bin/env ruby
# frozen_string_literal: true

# Daemon mode test script for ruby-progress

require 'fileutils'

puts '=== Ruby Progress Daemon Mode Demo ==='
puts

# Test directories
test_dir = '/tmp/progress_test'
FileUtils.mkdir_p(test_dir)
pid_file = "#{test_dir}/progress.pid"

puts "Test directory: #{test_dir}"
puts "PID file: #{pid_file}"
puts

# Clean up any existing PID file
File.delete(pid_file) if File.exist?(pid_file)

puts '1. Starting worm progress indicator in daemon mode...'
bin_path = File.join(File.dirname(__dir__), 'bin', 'prg')
system("#{bin_path} worm --daemon --pid-file #{pid_file} --message 'Processing in background...' --success 'All tasks completed!' --checkmark &")

# Wait a moment for daemon to start
sleep 1

if File.exist?(pid_file)
  pid = File.read(pid_file).strip
  puts "   ✅ Daemon started with PID: #{pid}"
else
  puts '   ❌ Failed to start daemon'
  exit 1
end

puts
puts '2. Simulating background work (5 seconds)...'
puts '   - Task 1: Processing data...'
sleep 2
puts '   - Task 2: Running analysis...'
sleep 2
puts '   - Task 3: Generating report...'
sleep 1

puts
puts '3. Stopping daemon...'
system("#{bin_path} worm --stop-pid #{pid_file}")

puts
puts '4. Cleaning up...'
FileUtils.rm_rf(test_dir)

puts
puts '=== Demo Complete ==='
puts
puts 'Usage in bash scripts:'
puts '  # Start daemon'
puts "  prg worm --daemon --pid-file /tmp/my_progress.pid --message 'Working...' --success 'Done!' &"
puts '  '
puts '  # Do your work'
puts '  my_long_running_task_1'
puts '  my_long_running_task_2'
puts '  '
puts '  # Stop daemon'
puts '  prg worm --stop-pid /tmp/my_progress.pid'
