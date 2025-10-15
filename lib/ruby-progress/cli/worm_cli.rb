# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require_relative 'worm_options'

# Enhanced Worm CLI (extracted from bin/prg)
module WormCLI
  def self.resolve_pid_file(options, name_key = :daemon_name)
    return options[:pid_file] if options[:pid_file]

    return "/tmp/ruby-progress/#{options[name_key]}.pid" if options[name_key]

    RubyProgress::Daemon.default_pid_file
  end

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
      # Background without detaching so worm remains visible in current terminal
      PrgCLI.backgroundize

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
        control_message_file: RubyProgress::Daemon.control_message_file(pid_file),
        icons: { success: options[:success_icon], error: options[:error_icon] }
      )
    ensure
      FileUtils.rm_f(pid_file)
    end
  end
end
