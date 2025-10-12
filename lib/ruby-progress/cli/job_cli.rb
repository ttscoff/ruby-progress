# frozen_string_literal: true

# CLI: prg job

# Provides the `prg job send` helper to enqueue commands into a daemon's
# job directory. This file contains a minimal implementation used by tests.

require 'optparse'
require 'json'
require 'securerandom'
require 'fileutils'
require_relative '../daemon'

# Job CLI helpers
#
# Exposed as `prg job send`.
module JobCLI
  # JobCLI
  #
  # Small CLI module that exposes `prg job send` for enqueuing jobs into the
  # daemon job directory. This is intentionally minimal: it writes a single
  # JSON file atomically and optionally waits for a result file created by
  # the daemon's job processor.
  # Simple CLI for submitting jobs to a running daemon job directory.
  # Usage: prg job send --pid-file /tmp/... --command "echo hi" [--wait]
  class Options
    def self.parse(argv)
      options = { wait: false }
      opt = OptionParser.new do |o|
        o.banner = 'Usage: prg job send [options]'
        o.on('--pid-file PATH', 'Path to daemon pid file') { |v| options[:pid_file] = v }
        o.on('--daemon-name NAME', 'Daemon name (maps to /tmp/ruby-progress/NAME.pid)') { |v| options[:daemon_name] = v }
        o.on('--command CMD', 'Command to run') { |v| options[:command] = v }
        o.on('--stdin', 'Read command from stdin (overrides --command)') { options[:stdin] = true }
        o.on('--wait', 'Wait for result file and print it') { options[:wait] = true }
        o.on('--timeout SECONDS', Integer, 'Timeout seconds for wait') { |v| options[:timeout] = v }
      end

      rest = opt.parse(argv)
      options[:command] ||= rest.join(' ') unless rest.empty?
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

    job_dir = RubyProgress::Daemon.job_dir_for_pid(pid_file)
    FileUtils.mkdir_p(job_dir)

    cmd = if opts[:stdin]
            $stdin.read
          else
            opts[:command]
          end

    unless cmd && !cmd.strip.empty?
      warn 'No command specified. Use --command or --stdin.'
      exit 1
    end

    job_id = SecureRandom.uuid
    tmp = File.join(job_dir, "#{job_id}.json.tmp")
    final = File.join(job_dir, "#{job_id}.json")

    payload = { 'id' => job_id, 'command' => cmd }

    File.write(tmp, JSON.dump(payload))
    FileUtils.mv(tmp, final)

    if opts[:wait]
      timeout = opts[:timeout] || 10
      start = Time.now
      result_path = "#{final}.processing.result"
      loop do
        if File.exist?(result_path)
          puts File.read(result_path)
          break
        end
        if Time.now - start > timeout
          warn 'Timed out waiting for result'
          exit 2
        end
        sleep 0.1
      end
    else
      puts job_id
    end
  end
end
