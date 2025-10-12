# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require_relative 'worm_options'

# Enhanced Worm CLI (extracted from bin/prg)
module WormCLI
  def self.run
    options = WormCLI::Options.parse_cli_options

    if options[:status]
      pid_file = resolve_pid_file(options, :status_name)
      RubyProgress::Daemon.show_status(pid_file)
      exit
    elsif options[:stop]
      pid_file = resolve_pid_file(options, :stop_name)
      stop_msg = options[:stop_error] || options[:stop_success]
      is_error = !options[:stop_error].nil?
      RubyProgress::Daemon.stop_daemon_by_pid_file(
        pid_file,
        message: stop_msg,
        checkmark: options[:stop_checkmark],
        error: is_error
      )
      exit
    elsif options[:daemon]
      # Detach before starting daemon logic so there's no tracked shell job
      PrgCLI.daemonize
      run_daemon_mode(options)
    else
      progress = RubyProgress::Worm.new(options)

      if options[:command]
        progress.run_with_command
      else
        progress.run_indefinitely
      end
    end
  end

  def self.run_daemon_mode(options)
    pid_file = resolve_pid_file(options, :daemon_name)
    FileUtils.mkdir_p(File.dirname(pid_file))
    File.write(pid_file, Process.pid.to_s)

    progress = RubyProgress::Worm.new(options)

    begin
      progress.run_daemon_mode(
        success_message: options[:success],
        show_checkmark: options[:checkmark],
        control_message_file: RubyProgress::Daemon.control_message_file(pid_file)
      )
    ensure
      FileUtils.rm_f(pid_file)
    end
  end

  def self.resolve_pid_file(options, name_key)
    return options[:pid_file] if options[:pid_file]

    if options[name_key]
      "/tmp/ruby-progress/#{options[name_key]}.pid"
    else
      RubyProgress::Daemon.default_pid_file
    end
  end

  # parse_cli_options is intentionally kept together; further extraction possible
  # parse_cli_options is intentionally delegated to WormCLI::Options
  def self.parse_cli_options
    WormCLI::Options.parse_cli_options
  end
end
