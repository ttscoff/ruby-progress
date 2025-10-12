# frozen_string_literal: true

require 'simplecov'
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
  if $!.is_a?(SystemExit)
    begin
      bt = $!.backtrace || []
      from_bundler = bt.any? { |line| line.include?('/gems/bundler') || line.include?('/exe/bundle') }
      $! = nil if $!.status == 0 || from_bundler
    rescue StandardError
      # Be conservative: don't clear $! if anything unexpected happens
    end
  end
end

require_relative '../lib/ruby-progress'

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
