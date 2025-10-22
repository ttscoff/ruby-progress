# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require_relative 'worm_options'

# Enhanced Worm CLI (extracted from bin/prg)
module WormCLI
  # CLI dispatcher for the Worm indicator.
  #
  # Responsibilities:
  # - parse CLI options (delegates to WormCLI::Options)
  # - handle daemonization, status, and stop commands via RubyProgress::Daemon
  # - launch the appropriate runtime mode (command-run, indefinite, daemon)
  #
  # Public methods:
  # - .run
  # - .resolve_pid_file
  # - .run_daemon_mode

  # Determine the pid file path from options. If options specify a custom
  # :pid_file, return it. If a named daemon key is present, use
  # /tmp/ruby-progress/<name>.pid. Otherwise fall back to the default.
  #
  # @param options [Hash] parsed CLI options
  # @param name_key [Symbol] key used for named daemons (default :daemon_name)
  # @return [String] path to the pid file
  def self.resolve_pid_file(options, name_key = :daemon_name)
    return options[:pid_file] if options[:pid_file]

    return "/tmp/ruby-progress/#{options[name_key]}.pid" if options[name_key]

    RubyProgress::Daemon.default_pid_file
  end

  # Entrypoint for the Worm CLI. Parses options and dispatches to status,
  # stop, daemon, or runtime modes. Ensures the cursor is restored on Ctrl+C.
  #
  # @return [void] exits with appropriate exit codes for status/stop modes.
  def self.run
    trap('INT') do
      RubyProgress::Utils.show_cursor
      exit
    end

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

  # Launch the worm indicator in daemon mode writing a pid file and
  # monitoring for control messages. Ensures pid file is removed on exit.
  #
  # @param options [Hash] parsed CLI options used to configure the Worm instance
  # @return [void]
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
