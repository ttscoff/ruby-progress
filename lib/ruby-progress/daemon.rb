# frozen_string_literal: true

require 'json'
require 'fileutils'

module RubyProgress
  # Daemon helpers for backgrounding progress indicators.
  # Provides minimal daemonization, PID file management, and simple control-message signaling.
  module Daemon
    module_function

    # Return the default PID file path used by ruby-progress daemons.
    #
    # @return [String] The filesystem path to the default PID file.
    # @example
    #   RubyProgress::Daemon.default_pid_file
    #   #=> "/tmp/ruby-progress/progress.pid"
    def default_pid_file
      '/tmp/ruby-progress/progress.pid'
    end

    # Return the path for the control message file corresponding to a PID file.
    # The control message file is used to pass JSON-encoded messages to a running
    # daemon (for example, success/failure metadata or a final message).
    #
    # @param pid_file [String] the path to the pid file
    # @return [String] the control-message file path (pid_file + ".msg")
    # @example
    #   RubyProgress::Daemon.control_message_file('/tmp/foo.pid')
    #   #=> '/tmp/foo.pid.msg'
    def control_message_file(pid_file)
      "#{pid_file}.msg"
    end

    # Print the daemon status for the given PID file and exit with an appropriate
    # exit code. If the PID file exists and the process is running this prints
    # a message and exits 0. If the PID file exists but the process is not
    # running this prints a warning and exits 1. If the PID file does not
    # exist this prints that the daemon is not running and exits 1.
    #
    # @param pid_file [String] path to the pid file
    # @return [void]
    # @example
    #   RubyProgress::Daemon.show_status('/tmp/ruby-progress/progress.pid')
    def show_status(pid_file)
      if File.exist?(pid_file)
        pid = File.read(pid_file).strip
        running = system("ps -p #{pid} > /dev/null")
        puts(running ? "Daemon running (pid #{pid})" : 'PID file present but process not running')
        exit(running ? 0 : 1)
      else
        puts 'Daemon not running'
        exit 1
      end
    end

    # Stop a running daemon by reading its PID from the given pid file. Optionally
    # write a small JSON control message (containing :checkmark and :message keys)
    # to the corresponding control message file before signalling the process.
    # The method attempts to send SIGUSR1 to the running process, sleeps briefly
    # to allow the process to handle the signal, and then removes the pid file.
    #
    # This helper prints user-friendly errors and exits with non-zero status when
    # the pid file is missing, the process cannot be found, or permission is
    # denied when sending the signal.
    #
    # @param pid_file [String] path to the pid file
    # @param message [String, nil] optional message to send to the daemon via the control file
    # @param checkmark [Boolean] whether to include a checkmark flag in the control payload
    # @param error [Boolean] whether this stop represents an error (affects success flag in payload)
    # @return [void]
    # @example
    #   RubyProgress::Daemon.stop_daemon_by_pid_file('/tmp/ruby-progress/progress.pid', message: 'Stopping', checkmark: true)
    def stop_daemon_by_pid_file(pid_file, message: nil, checkmark: false, error: false)
      unless File.exist?(pid_file)
        puts "PID file #{pid_file} not found"
        exit 1
      end

      pid = File.read(pid_file).strip.to_i

      # Write control message file if provided
      if message || error
        cmf = control_message_file(pid_file)
        payload = { checkmark: checkmark, success: !error }
        payload[:message] = message if message
        File.write(cmf, payload.to_json)
      end

      begin
        Process.kill('USR1', pid)
        sleep 0.5
        FileUtils.rm_f(pid_file)
      rescue Errno::ESRCH
        puts "Process #{pid} not found (may have already stopped)"
        FileUtils.rm_f(pid_file)
        exit 1
      rescue Errno::EPERM
        puts "Permission denied sending signal to process #{pid}"
        exit 1
      end
    end
  end
end
