# frozen_string_literal: true

# CLI: prg job [subcommand]
# Send control messages to backgrounded progress indicators.

require 'optparse'
require 'json'
require 'fileutils'
require_relative '../daemon'

# JobCLI - sends control messages to backgrounded progress indicators
#
# Usage:
#   prg job stop --daemon-name mytask [--message "Done!"] [--checkmark]
#   prg job advance --daemon-name mytask [--amount 10]
#   prg job status --daemon-name mytask
module JobCLI
  def self.run(argv = ARGV)
    if argv.empty?
      print_help
      exit 1
    end

    subcommand = argv.shift

    case subcommand
    when 'stop'
      stop(argv)
    when 'advance'
      advance(argv)
    when 'status'
      status(argv)
    when 'send'
      # Backward compatibility: 'send' is now 'stop'
      warn "Warning: 'prg job send' is deprecated. Use 'prg job stop' instead."
      stop(argv)
    when '--help', '-h'
      print_help
    else
      warn "Error: Unknown subcommand '#{subcommand}'"
      print_help
      exit 1
    end
  end

  def self.print_help
    puts 'Usage: prg job [subcommand] [options]'
    puts
    puts 'Subcommands:'
    puts '  stop     Stop a running progress indicator'
    puts '  advance  Advance a fill progress bar'
    puts '  status   Check status of a running indicator'
    puts
    puts 'Common Options:'
    puts '  --daemon-name NAME   Name of the daemon to control'
    puts '  --pid-file PATH      Path to daemon PID file'
    puts
    puts 'Examples:'
    puts '  prg job stop --daemon-name mytask --message "Complete!"'
    puts '  prg job advance --daemon-name mybar --amount 10'
    puts '  prg job status --daemon-name mytask'
  end

  def self.resolve_pid_file(opts)
    if opts[:pid_file]
      opts[:pid_file]
    elsif opts[:daemon_name]
      "/tmp/ruby-progress/#{opts[:daemon_name]}.pid"
    else
      RubyProgress::Daemon.default_pid_file
    end
  end

  def self.stop(argv)
    opts = parse_stop_options(argv)
    pid_file = resolve_pid_file(opts)

    unless File.exist?(pid_file)
      warn "PID file #{pid_file} not found. Is the daemon running?"
      exit 1
    end

    RubyProgress::Daemon.stop_daemon_by_pid_file(
      pid_file,
      message: opts[:message],
      checkmark: opts[:checkmark] || false,
      error: opts[:error] || false
    )

    # Don't output confirmation - the daemon itself shows the completion message
  end

  def self.advance(argv)
    opts = parse_advance_options(argv)
    pid_file = resolve_pid_file(opts)

    unless File.exist?(pid_file)
      warn "PID file #{pid_file} not found. Is the daemon running?"
      exit 1
    end

    # Write advance command to control message file
    cmf = RubyProgress::Daemon.control_message_file(pid_file)
    control_data = {
      action: 'advance',
      amount: opts[:amount] || 1,
      total: opts[:total]
    }.compact

    File.write(cmf, JSON.generate(control_data))

    # Send signal to daemon to check for messages
    pid = File.read(pid_file).strip.to_i
    begin
      Process.kill('USR2', pid)
    rescue Errno::ESRCH
      # Process doesn't exist
    end

    # Silent operation for script-friendly usage
  end

  def self.status(argv)
    opts = parse_status_options(argv)
    pid_file = resolve_pid_file(opts)

    RubyProgress::Daemon.show_status(pid_file)
  end

  def self.parse_stop_options(argv)
    options = {}
    opt = OptionParser.new do |o|
      o.banner = 'Usage: prg job stop [options]'
      o.on('--pid-file PATH', 'Path to daemon PID file') do |v|
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

  def self.parse_advance_options(argv)
    options = {}
    opt = OptionParser.new do |o|
      o.banner = 'Usage: prg job advance [options]'
      o.on('--pid-file PATH', 'Path to daemon PID file') do |v|
        options[:pid_file] = v
      end
      o.on('--daemon-name NAME', 'Daemon name (maps to /tmp/ruby-progress/NAME.pid)') do |v|
        options[:daemon_name] = v
      end
      o.on('--amount N', Integer, 'Amount to advance (default: 1)') do |v|
        options[:amount] = v
      end
      o.on('--total N', Integer, 'Update total if needed') do |v|
        options[:total] = v
      end
    end

    opt.parse(argv)
    options
  end

  def self.parse_status_options(argv)
    options = {}
    opt = OptionParser.new do |o|
      o.banner = 'Usage: prg job status [options]'
      o.on('--pid-file PATH', 'Path to daemon PID file') do |v|
        options[:pid_file] = v
      end
      o.on('--daemon-name NAME', 'Daemon name (maps to /tmp/ruby-progress/NAME.pid)') do |v|
        options[:daemon_name] = v
      end
    end

    opt.parse(argv)
    options
  end

  # Backward compatibility
  def self.send(argv = ARGV)
    warn "Warning: 'JobCLI.send' is deprecated. Use 'JobCLI.stop' instead."
    stop(argv)
  end
end
