# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  track_files 'lib/**/*.rb'
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
