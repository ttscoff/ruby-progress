# frozen_string_literal: true

require 'json'

module RubyProgress
  module Daemon
    module_function

    def default_pid_file
      '/tmp/ruby-progress/progress.pid'
    end

    def control_message_file(pid_file)
      "#{pid_file}.msg"
    end

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
        puts "Stop signal sent to process #{pid}"
        sleep 0.5
        File.delete(pid_file) if File.exist?(pid_file)
      rescue Errno::ESRCH
        puts "Process #{pid} not found (may have already stopped)"
        File.delete(pid_file) if File.exist?(pid_file)
        exit 1
      rescue Errno::EPERM
        puts "Permission denied sending signal to process #{pid}"
        exit 1
      end
    end
  end
end
