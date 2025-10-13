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
        o.on('--pid-file PATH', 'Path to daemon pid file') do |v|
          options[:pid_file] = v
        end
        o.on('--daemon-name NAME', 'Daemon name (maps to /tmp/ruby-progress/NAME.pid)') do |v|
          options[:daemon_name] = v
        end
        o.on('--command CMD', 'Command to run') do |v|
          options[:command] = v
        end
        o.on('--stdin', 'Read command from stdin (overrides --command)') do
          options[:stdin] = true
        end
        o.on('--advance', 'Send an advance action (no value)') do
          options[:action] = 'advance'
        end
        o.on('--percent N', Integer, 'Send a percent action with value N') do |v|
          options[:action] = 'percent'
          options[:value] = v
        end
        o.on('--complete', 'Send a complete action (no value)') do
          options[:action] = 'complete'
        end
        o.on('--cancel', 'Send a cancel action (no value)') do
          options[:action] = 'cancel'
        end
        o.on('--action ACTION', 'Send a custom action name') do |v|
          options[:action] = v
        end
        o.on('--value VAL', 'Value for the action (string or number)') do |v|
          options[:value] = v
        end
        o.on('--wait', 'Wait for result file and print it') do
          options[:wait] = true
        end
        o.on('--timeout SECONDS', Integer, 'Timeout seconds for wait') do |v|
          options[:timeout] = v
        end
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

    is_action = !opts[:action].nil? && opts[:action] != false

    if is_action
      if cmd && !cmd.strip.empty?
        warn 'Cannot specify both --command/--stdin and an action flag'
        exit 1
      end
    else
      unless cmd && !cmd.strip.empty?
        warn 'No command specified. Use --command, --stdin, or pass an action flag.'
        exit 1
      end
    end

    job_id = SecureRandom.uuid
    tmp = File.join(job_dir, "#{job_id}.json.tmp")
    final = File.join(job_dir, "#{job_id}.json")

    payload = build_payload(opts, job_id, cmd)

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

  # Build the JSON payload for a job based on parsed options.
  def self.build_payload(opts, job_id, cmd)
    payload = { 'id' => job_id }

    is_action = !opts[:action].nil? && opts[:action] != false

    if is_action
      payload['action'] = opts[:action]
      if opts.key?(:value)
        val = opts[:value]
        payload['value'] = val.to_i if val.is_a?(String) && val =~ /^\d+$/
        payload['value'] ||= val
      end
    else
      payload['command'] = cmd
    end

    payload
  end
end
