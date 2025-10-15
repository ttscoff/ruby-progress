# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in ruby-progress.gemspec
gemspec

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.0'
  # RuboCop requires Ruby >= 2.7 for older versions, >= 3.0 for recent versions
  # Pin to a version compatible with Ruby 2.7/3.0 for CI
  if RUBY_VERSION >= '3.1'
    gem 'rubocop', '~> 1.50'
  else
    gem 'rubocop', '~> 1.21.0'
  end
  gem 'simplecov', '~> 0.21', require: false
  gem 'tty-cursor', '~> 0.7'
  gem 'tty-screen', '~> 0.8'
end
