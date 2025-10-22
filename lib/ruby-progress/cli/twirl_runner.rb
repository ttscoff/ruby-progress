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
  # Runtime helper: run the provided command while showing a twirl spinner.
  # Captures output via RubyProgress::OutputCapture when appropriate and
  # prints final completion messages according to options.
  #
  # @param options [Hash] CLI options parsed from TwirlCLI::Options
  # @return [void] exits with appropriate status code (0 success, 1 failure)
  def self.run_with_command(options)
    message = options[:message]
    captured_output = nil

    spinner = TwirlSpinner.new(message, options)
    success = false

    begin
      RubyProgress::Utils.hide_cursor
      spinner_thread = Thread.new { loop { spinner.animate } }

      if $stdout.tty? && options[:stdout] && options[:stdout_live]
        oc = RubyProgress::OutputCapture.new(
          command: options[:command],
          lines: options[:output_lines] || 3,
          position: options[:output_position] || :above,
          stream: true
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
    rescue Interrupt
      spinner_thread&.kill
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor
      exit 130
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

  # Run the spinner indefinitely until interrupted (SIGINT).
  #
  # @param options [Hash] CLI options used to configure the spinner
  # @return [void] exits 130 on interrupt
  def self.run_indefinitely(options)
    message = options[:message]
    spinner = TwirlSpinner.new(message, options)

    # Pipeline mode: if no command provided and STDIN is not a TTY, consume
    # input until EOF while animating the spinner, then exit.
    unless $stdin.tty?
      buffer = []
      begin
        RubyProgress::Utils.hide_cursor
        spinner_thread = Thread.new { loop { spinner.animate } }

        $stdin.each_line do |line|
          if options[:stdout] && options[:stdout_live]
            $stderr.print "\r\e[2K" # clear spinner line before printing live output
            $stderr.flush
            $stdout.print(line)
            $stdout.flush
          elsif options[:stdout]
            buffer << line
          end
        end

        spinner_thread.kill
        RubyProgress::Utils.clear_line

        if options[:stdout] && !options[:stdout_live]
          $stdout.print(buffer.join)
          $stdout.flush
        end
      rescue Interrupt
        # Propagate interrupt semantics consistent with other modes
        RubyProgress::Utils.clear_line
        RubyProgress::Utils.show_cursor
        exit 130
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
      return
    end

    begin
      RubyProgress::Utils.hide_cursor
      loop { spinner.animate }
    rescue Interrupt
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor
      exit 130
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

  # Run the spinner in daemon mode. Writes a pid file and listens for
  # control messages via the daemon control message file.
  #
  # @param options [Hash]
  # @return [void]
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

      FileUtils.rm_f(pid_file)
    end
  end

  # Resolve pid file helper used by run_daemon_mode and CLI.
  #
  # @param options [Hash]
  # @param name_key [Symbol]
  # @return [String]
  def self.resolve_pid_file(options, name_key)
    return options[:pid_file] if options[:pid_file]

    if options[name_key]
      "/tmp/ruby-progress/#{options[name_key]}.pid"
    else
      RubyProgress::Daemon.default_pid_file
    end
  end
end
