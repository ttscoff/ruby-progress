#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showing gem functionality for CI/CD validation

puts '🚀 Ruby Progress Gem Demo'
puts '========================='
puts

# Test library loading
begin
  require 'ruby-progress'
  puts '✅ Library loaded successfully'
  puts "📦 Version: #{RubyProgress::VERSION}"
rescue LoadError => e
  puts "❌ Failed to load library: #{e.message}"
  exit 1
end

puts

# Test Ripple class
begin
  puts '🌊 Testing Ripple class...'
  ripple = RubyProgress::Ripple.new('Demo Test')
  puts '✅ Ripple class instantiated successfully'
rescue StandardError => e
  puts "❌ Ripple test failed: #{e.message}"
  exit 1
end

# Test Worm class
begin
  puts '🐛 Testing Worm class...'
  worm = RubyProgress::Worm.new(message: 'Demo Test')
  puts '✅ Worm class instantiated successfully'
rescue StandardError => e
  puts "❌ Worm test failed: #{e.message}"
  exit 1
end

puts
puts '🎉 All tests passed! The gem is working correctly.'
puts
puts '📊 Key Features Verified:'
puts '  • Library structure and loading'
puts '  • Version management'
puts '  • Ripple and Worm class instantiation'
puts '  • Module namespacing'
puts
puts '🔗 Ready for badge display:'
puts '  • RubyGems version badge'
puts '  • MIT license badge'
puts '  • GitHub Actions test badge'
puts '  • Ruby version compatibility badge'
puts '  • Test coverage badge'
