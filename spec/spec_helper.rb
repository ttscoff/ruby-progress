# frozen_string_literal: true

require 'simplecov'
require 'English'

# Prevent SimpleCov from auto-registering its at_exit handler.
# We'll call its at_exit behavior manually after we clear any benign $ERROR_INFO.
SimpleCov.external_at_exit = true

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  track_files 'lib/**/*.rb'
end

# Diagnostic: print any exception visible at exit so we can see what SimpleCov detected
at_exit do
  # If the process is exiting normally via exit(0) (SystemExit with status 0),
  # SimpleCov's at_exit handler should still run. Some Ruby versions leave $!
  # set to a SystemExit when exit is invoked; SimpleCov treats any non-nil $!
  # as a prior error. Clear only a successful SystemExit to allow coverage
  # processing while preserving other errors.
  # If the process has a SystemExit set at exit, SimpleCov will skip processing.
  # That can happen because the bundler wrapper may leave a SystemExit in $!.
  # Clear only when it's clearly benign: status 0, or backtrace inside bundler
  # wrappers. This reduces the risk of masking real errors.
  if $ERROR_INFO.is_a?(SystemExit)
    begin
      bt = $ERROR_INFO.backtrace || []
      from_bundler = bt.any? { |line| line.include?('/gems/bundler') || line.include?('/exe/bundle') }
      $ERROR_INFO = nil if $ERROR_INFO.status == 0 || from_bundler
    rescue StandardError
      # Be conservative: don't clear $ERROR_INFO if anything unexpected happens
    end
  end

  # Now always run SimpleCov's processing manually. We do this regardless of
  # whether we cleared $ERROR_INFO above so SimpleCov doesn't skip processing
  # because of a benign SystemExit left by bundler wrappers.
  begin
    # Run SimpleCov finalization in a separate thread so it sees a clean $! (nil)
    # without attempting to assign to the global $ERROR_INFO (which is readonly
    # in some Ruby implementations / run modes). This prevents SimpleCov from
    # skipping processing due to a leftover exception while preserving the
    # original process-level error state.
    t = Thread.new do
      SimpleCov.at_exit_behavior
    end
    t.join
  rescue StandardError => e
    warn "SimpleCov finalization failed: #{e.class}: #{e.message}"
  end
end

require_relative '../lib/ruby-progress'
require 'timeout'
require 'open3'

# Helper method for running commands with timeout (cross-platform)
def run_with_timeout(command, timeout_seconds = 1)
  stdout = ''
  stderr = ''
  exit_status = 124 # Default to timeout exit code
  
  # Suppress thread error messages during forced termination
  original_report_on_exception = Thread.report_on_exception
  Thread.report_on_exception = false
  
  begin
    Open3.popen3(command) do |_stdin, out, err, wait_thr|
      # Set non-blocking mode
      out.sync = true
      err.sync = true
      
      # Wait for timeout with the process
      Timeout.timeout(timeout_seconds) do
        wait_thr.join
        exit_status = wait_thr.value.exitstatus
        # Process completed before timeout - read output
        stdout = out.read
        stderr = err.read
      end
    rescue Timeout::Error
      # Timeout occurred - kill the process
      begin
        Process.kill('TERM', wait_thr.pid)
        # Give it a moment to die gracefully
        sleep 0.1
        Process.kill('KILL', wait_thr.pid) if wait_thr.alive?
      rescue Errno::ESRCH, Errno::EPERM
        # Process already dead or no permission
      end
      
      # Try to read any output that was generated before timeout
      begin
        stdout = out.read_nonblock(100_000)
      rescue IO::WaitReadable, EOFError
        stdout = ''
      end
      
      begin
        stderr = err.read_nonblock(100_000)
      rescue IO::WaitReadable, EOFError
        stderr = ''
      end
      
      exit_status = 124 # timeout exit code
    end
  ensure
    Thread.report_on_exception = original_report_on_exception
  end
  
  status = double('ProcessStatus', exitstatus: exit_status, success?: exit_status == 0)
  [stdout, stderr, status]
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec's monkey patching of Object class
  config.disable_monkey_patching!

  # Use documentation formatter for better output
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
