# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative 'twirl_spinner'
require_relative '../output_capture'

# Top-level runtime helper module for the Twirl CLI.
#
# Contains helper methods used by the `TwirlCLI` dispatcher. These
# methods implement the runtime behavior (running a command, running
# indefinitely, or launching in daemon mode) and were extracted to
# reduce module size and improve testability.
module TwirlRunner
  def self.run_with_command(options)
    message = options[:message]
    captured_output = nil

    spinner = TwirlSpinner.new(message, options)
    success = false

    begin
      RubyProgress::Utils.hide_cursor
      spinner_thread = Thread.new { loop { spinner.animate } }

      if $stdout.tty? && options[:stdout]
        oc = RubyProgress::OutputCapture.new(
          command: options[:command],
          lines: options[:output_lines] || 3,
          position: options[:output_position] || :above
        )
        oc.start

        spinner.instance_variable_set(:@output_capture, oc)

        # wait for command while spinner thread runs
        oc.wait
        captured_lines = oc.lines
        captured_output = captured_lines.join("\n")
        success = true
      else
        captured_output = `#{options[:command]} 2>&1`
        success = $CHILD_STATUS.success?
      end

      spinner_thread.kill
      RubyProgress::Utils.clear_line
    ensure
      RubyProgress::Utils.show_cursor
    end

    puts captured_output if options[:stdout]

    if options[:success] || options[:error] || options[:checkmark]
      final_msg = success ? options[:success] : options[:error]
      final_msg ||= success ? 'Success' : 'Failed'

      RubyProgress::Utils.display_completion(
        final_msg,
        success: success,
        show_checkmark: options[:checkmark],
        icons: { success: options[:success_icon], error: options[:error_icon] }
      )
    end

    exit success ? 0 : 1
  end

  def self.run_indefinitely(options)
    message = options[:message]
    spinner = TwirlSpinner.new(message, options)

    begin
      RubyProgress::Utils.hide_cursor
      loop { spinner.animate }
    ensure
      RubyProgress::Utils.show_cursor
      if options[:success] || options[:checkmark]
        RubyProgress::Utils.display_completion(
          options[:success] || 'Complete',
          success: true,
          show_checkmark: options[:checkmark],
          icons: { success: options[:success_icon], error: options[:error_icon] }
        )
      end
    end
  end

  def self.run_daemon_mode(options)
    pid_file = resolve_pid_file(options, :daemon_name)
    FileUtils.mkdir_p(File.dirname(pid_file))
    File.write(pid_file, Process.pid.to_s)

    message = options[:message]
    spinner = TwirlSpinner.new(message, options)
    stop_requested = false

    Signal.trap('INT') { stop_requested = true }
    Signal.trap('USR1') { stop_requested = true }
    Signal.trap('TERM') { stop_requested = true }
    Signal.trap('HUP') { stop_requested = true }

    begin
      RubyProgress::Utils.hide_cursor

      # Start job processor thread for twirl
      job_dir = RubyProgress::Daemon.job_dir_for_pid(pid_file)
      job_thread = Thread.new do
        RubyProgress::Daemon.process_jobs(job_dir) do |job|
          oc = RubyProgress::OutputCapture.new(
            command: job['command'],
            lines: options[:output_lines] || 3,
            position: options[:output_position] || :above
          )
          oc.start

          spinner.instance_variable_set(:@output_capture, oc)
          oc.wait
          captured = oc.lines.join("\n")
          exit_status = oc.exit_status
          spinner.instance_variable_set(:@output_capture, nil)

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

          { 'exit_status' => exit_status, 'output' => captured }
        rescue StandardError
          # ignore
        end
      end

      spinner.animate until stop_requested
    ensure
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor

      # Check for control message
      cmf = RubyProgress::Daemon.control_message_file(pid_file)
      if File.exist?(cmf)
        begin
          data = JSON.parse(File.read(cmf))
          message = data['message']
          check = data.key?('checkmark') ? data['checkmark'] : false
          success_val = data.key?('success') ? data['success'] : true
          if message
            RubyProgress::Utils.display_completion(
              message,
              success: success_val,
              show_checkmark: check,
              output_stream: :stdout,
              icons: { success: options[:success_icon], error: options[:error_icon] }
            )
          end
        rescue StandardError
          # ignore
        ensure
          begin
            File.delete(cmf)
          rescue StandardError
            nil
          end
        end
      end

      job_thread&.kill
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
end
