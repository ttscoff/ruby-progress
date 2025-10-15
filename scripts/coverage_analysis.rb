#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# Read the SimpleCov results
data = JSON.parse(File.read('coverage/.resultset.json'))
files = data['RSpec']['coverage']

results = []
files.each do |path, coverage|
  next unless path.include?('lib/ruby-progress') && !path.include?('/bin/')

  lines = coverage['lines'] || []
  total = lines.compact.count
  next if total.zero?

  covered = lines.count { |l| l&.positive? }
  pct = (covered * 100.0 / total).round(1)
  short_path = path.split('ruby-progress/').last
  results << { path: short_path, pct: pct, covered: covered, total: total }
end

puts "\n=== Coverage Analysis by File ===\n\n"
puts "Files with lowest coverage (need attention):\n\n"

results.sort_by { |r| r[:pct] }.first(10).each do |r|
  color = if r[:pct] < 30
            "\e[31m"
          else
            r[:pct] < 60 ? "\e[33m" : "\e[32m"
          end
  reset = "\e[0m"
  puts format("#{color}%6.1f%%#{reset} (%4d/%4d) %s", r[:pct], r[:covered], r[:total], r[:path])
end

puts "\n\nFiles with highest coverage:\n\n"
results.sort_by { |r| -r[:pct] }.first(10).each do |r|
  color = "\e[32m"
  reset = "\e[0m"
  puts format("#{color}%6.1f%%#{reset} (%4d/%4d) %s", r[:pct], r[:covered], r[:total], r[:path])
end

total_lines = results.sum { |r| r[:total] }
total_covered = results.sum { |r| r[:covered] }
overall_pct = (total_covered * 100.0 / total_lines).round(2)

puts "\n\n=== Overall Coverage ===\n"
puts format('Total: %.2f%% (%d/%d lines)', overall_pct, total_covered, total_lines)
