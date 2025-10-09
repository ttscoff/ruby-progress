# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

# Version management tasks
desc 'Show current version'
task :version do
  require_relative 'lib/ruby-progress/version'
  puts RubyProgress::VERSION
end

desc 'Bump patch version'
task :bump_patch do
  bump_version(:patch)
end

desc 'Bump minor version'
task :bump_minor do
  bump_version(:minor)
end

desc 'Bump major version'
task :bump_major do
  bump_version(:major)
end

def bump_version(type)
  require_relative 'lib/ruby-progress/version'
  version_parts = RubyProgress::VERSION.split('.').map(&:to_i)

  case type
  when :patch
    version_parts[2] += 1
  when :minor
    version_parts[1] += 1
    version_parts[2] = 0
  when :major
    version_parts[0] += 1
    version_parts[1] = 0
    version_parts[2] = 0
  end

  new_version = version_parts.join('.')

  # Update version file
  version_file = 'lib/ruby-progress/version.rb'
  content = File.read(version_file)
  content.gsub!(/VERSION = '[^']*'/, "VERSION = '#{new_version}'")
  File.write(version_file, content)

  puts "Version bumped from #{RubyProgress::VERSION} to #{new_version}"
end

# Package management
desc 'Clean up generated files'
task :clobber do
  require 'fileutils'
  FileUtils.rm_rf('pkg')
  FileUtils.rm_rf('coverage')
  puts 'Cleaned up generated files'
end

desc 'Build and install gem locally'
task install_local: :build do
  require_relative 'lib/ruby-progress/version'
  gem_file = "pkg/ruby-progress-#{RubyProgress::VERSION}.gem"
  system("gem install #{gem_file}")
end

desc 'Test installed binaries'
task :test_binaries do
  puts 'Testing ripple binary...'
  system('ripple --version') || abort('ripple binary test failed')
  puts 'Testing worm binary...'
  system('worm --version') || abort('worm binary test failed')
  puts 'Binary tests passed!'
end
