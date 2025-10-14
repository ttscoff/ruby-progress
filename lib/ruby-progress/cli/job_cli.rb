# frozen_string_literal: true

# CLI: prg job send
# Simplified to send control messages (stop signal) to a backgrounded progress indicator.

require 'optparse'
require 'json'
require 'fileutils'
require_relative '../daemon'

# JobCLI - sends simple control messages to backgrounded progress indicators
#
# Usage: prg job send --daemon-name mytask [--message "Done!"] [--checkmark]
module JobCLI
  class Options
    def self.parse(argv)
      options = {}
      opt = OptionParser.new do |o|
        o.banner = 'Usage: prg job send [options]'
        o.on('--pid-file PATH', 'Path to daemon pid file') do |v|
          options[:pid_file] = v
        end
        o.on('--daemon-name NAME', 'Daemon name (maps to /tmp/ruby-progress/NAME.pid)') do |v|
          options[:daemon_name] = v
        end
        o.on('--message MSG', 'Optional completion message to display') do |v|
          options[:message] = v
        end
        o.on('--checkmark', 'Display a checkmark on completion') do
          options[:checkmark] = true
        end
        o.on('--error', 'Mark completion as error state') do
          options[:error] = true
        end
      end

      opt.parse(argv)
      options
    end
  end

  def self.send(argv = ARGV)
    opts = Options.parse(argv)

    # Resolve pid file
    pid_file = if opts[:pid_file]
                 opts[:pid_file]
               elsif opts[:daemon_name]
                 "/tmp/ruby-progress/#{opts[:daemon_name]}.pid"
               else
                 RubyProgress::Daemon.default_pid_file
               end

    unless File.exist?(pid_file)
      warn "PID file #{pid_file} not found. Is the daemon running?"
      exit 1
    end

    # Send stop signal with optional message
    RubyProgress::Daemon.stop_daemon_by_pid_file(
      pid_file,
      message: opts[:message],
      checkmark: opts[:checkmark] || false,
      error: opts[:error] || false
    )

    puts "Stop signal sent to #{opts[:daemon_name] || pid_file}"
  end
end
