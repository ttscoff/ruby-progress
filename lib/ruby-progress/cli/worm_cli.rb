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
      # Start job processor thread for worm
      job_dir = RubyProgress::Daemon.job_dir_for_pid(pid_file)
      job_thread = Thread.new do
        RubyProgress::Daemon.process_jobs(job_dir) do |job|
          jid = job['id'] || SecureRandom.uuid
          log_path = begin
            File.join(File.dirname(job_dir), "#{jid}.log")
          rescue StandardError
            nil
          end

          oc = RubyProgress::OutputCapture.new(
            command: job['command'],
            lines: options[:output_lines] || 3,
            position: options[:output_position] || :above,
            log_path: log_path
          )
          oc.start

          progress.instance_variable_set(:@output_capture, oc)
          oc.wait
          captured = oc.lines.join("\n")
          exit_status = oc.exit_status
          progress.instance_variable_set(:@output_capture, nil)

          success = exit_status.to_i.zero?
          if job['message']
            RubyProgress::Utils.display_completion(
              job['message'],
              success: success,
              show_checkmark: job['checkmark'] || false,
              output_stream: :stdout,
              icons: { success: options[:success_icon], error: options[:error_icon] }
            )
          end

          { 'exit_status' => exit_status, 'output' => captured, 'log_path' => log_path }
        rescue StandardError
          # ignore per-job errors
        end
      end

      progress.run_daemon_mode(
        success_message: options[:success],
        show_checkmark: options[:checkmark],
        control_message_file: RubyProgress::Daemon.control_message_file(pid_file),
        icons: { success: options[:success_icon], error: options[:error_icon] }
      )
    ensure
      job_thread&.kill
      FileUtils.rm_f(pid_file)
    end
  end
end
