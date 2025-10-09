# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

# Used by markdown tasks
MARKDOWN_GLOB = ['**/*.md'].freeze

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

# Markdown lint/fix tasks (no external deps)
namespace :markdown do
  def markdown_files
    Dir.glob(MARKDOWN_GLOB).reject do |p|
      p.start_with?('pkg/') || p.start_with?('coverage/') || p.start_with?('node_modules/')
    end
  end

  def list_item?(line)
    !!(line =~ /^\s*([-*+]\s+|\d+\.\s+)/)
  end

  def fence_delimiter?(line)
    !!(line =~ /^\s*```|^\s*~~~/)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def format_markdown(content)
    lines = content.split("\n", -1)
    out = []
    in_fence = false
    i = 0
    while i < lines.length
      line = lines[i]

      if fence_delimiter?(line)
        in_fence = !in_fence
        out << line
        i += 1
        next
      end

      if in_fence
        out << line
        i += 1
        next
      end

      # Collapse multiple blank lines
      if line.strip.empty?
        prev = out.last
        out << '' if prev && !prev.strip.empty?
        i += 1
        next
      end

      # Ensure blank line after headings
      if line =~ /^\s*#+\s+/
        out << line
        nxt = lines[i + 1]
        out << '' if nxt && !nxt.strip.empty? && !fence_delimiter?(nxt)
        i += 1
        next
      end

      # Ensure blank line before and after list blocks
      if list_item?(line)
        prev = out.last
        out << '' unless prev.nil? || prev.strip.empty? || list_item?(prev)
        while i < lines.length && list_item?(lines[i])
          out << lines[i]
          i += 1
        end
        after = lines[i]
        out << '' if after && !after.strip.empty? && !fence_delimiter?(after)
        next
      end

      out << line
      i += 1
    end

    out << '' if (last = out.last) && !last.empty?
    out.join("\n")
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  desc 'Lint markdown (reports files that would be changed)'
  task :lint do
    changed = []
    markdown_files.each do |path|
      original = File.read(path)
      formatted = format_markdown(original)
      changed << path if formatted != original
    end
    if changed.empty?
      puts 'Markdown: no issues found.'
    else
      puts 'Markdown files needing formatting:'
      changed.each { |p| puts "  - #{p}" }
      abort 'Run: rake markdown:fix'
    end
  end

  desc 'Auto-fix markdown spacing (headings, lists, blank lines)'
  task :fix do
    updated = []
    markdown_files.each do |path|
      original = File.read(path)
      formatted = format_markdown(original)
      next if formatted == original

      File.write(path, formatted)
      updated << path
    end
    if updated.empty?
      puts 'Markdown: nothing to fix.'
    else
      puts 'Markdown updated:'
      updated.each { |p| puts "  - #{p}" }
    end
  end
end
