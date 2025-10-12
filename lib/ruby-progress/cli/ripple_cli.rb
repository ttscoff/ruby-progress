# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'securerandom'
require_relative 'ripple_options'
require_relative '../output_capture'

# Enhanced Ripple CLI with unified flags (extracted from bin/prg)
module RippleCLI
  def self.run
    trap('INT') do
      RubyProgress::Utils.show_cursor
      exit
    end

    options = RippleCLI::Options.parse_cli_options

    # Daemon/status/stop handling (process these without requiring text)
    if options[:status]
      pid_file = options[:pid_file] || RubyProgress::Daemon.default_pid_file
      RubyProgress::Daemon.show_status(pid_file)
      exit
    elsif options[:stop]
      pid_file = options[:pid_file] || RubyProgress::Daemon.default_pid_file
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
      # For daemon mode, detach so shell has no tracked job
      PrgCLI.daemonize

      # For daemon mode, default message if none provided
      text = options[:message] || ARGV.join(' ')
      text = 'Processing' if text.nil? || text.empty?
      run_daemon_mode(text, options)
    else
      # Non-daemon path requires text
      text = options[:message] || ARGV.join(' ')
      if text.empty?
        puts 'Error: Please provide text to animate via argument or --message flag'
        puts "Example: prg ripple 'Loading...' or prg ripple --message 'Loading...'"
        exit 1
      end

      # Convert styles array to individual flags for backward compatibility
      options[:rainbow] = options[:styles].include?(:rainbow)
      options[:inverse] = options[:styles].include?(:inverse)
      options[:caps] = options[:styles].include?(:caps)

      if options[:command]
        run_with_command(text, options)
      else
        run_indefinitely(text, options)
      end
    end
  end

  def self.run_with_command(text, options)
    if $stdout.tty? && options[:output] == :stdout
      oc = RubyProgress::OutputCapture.new(command: options[:command], lines: options[:output_lines] || 3, position: options[:output_position] || :above)
      oc.start

      # Create rippler and attach output capture so redraw occurs each frame
      rippler = RubyProgress::Ripple.new(text, options)
      rippler.instance_variable_set(:@output_capture, oc)

      thread = Thread.new { loop { rippler.advance } }
      oc.wait
      thread.kill

      captured_lines = oc.lines
      captured_output = captured_lines.join("\n")
      success = true
    else
      # Fallback to legacy capture (non-interactive / CI)
      captured_output = `#{options[:command]} 2>&1`
      success = $CHILD_STATUS.success?
    end

    puts captured_output if options[:output] == :stdout
    if options[:success_message] || options[:complete_checkmark]
      message = success ? options[:success_message] : options[:fail_message] || options[:success_message]
      RubyProgress::Ripple.complete(text, message, options[:complete_checkmark], success)
    end
    exit success ? 0 : 1
  end

  def self.run_indefinitely(text, options)
    rippler = RubyProgress::Ripple.new(text, options)
    RubyProgress::Utils.hide_cursor
    begin
      loop { rippler.advance }
    ensure
      RubyProgress::Utils.show_cursor
      RubyProgress::Ripple.complete(text, options[:success_message], options[:complete_checkmark], true)
    end
  end

  def self.run_daemon_mode(text, options)
    pid_file = options[:pid_file] || RubyProgress::Daemon.default_pid_file
    FileUtils.mkdir_p(File.dirname(pid_file))
    File.write(pid_file, Process.pid.to_s)
    begin
      # For Ripple, re-use the existing animation loop via a simple loop
      RubyProgress::Utils.hide_cursor
      rippler = RubyProgress::Ripple.new(text, options)
      stop_requested = false

      Signal.trap('INT') { stop_requested = true }
      Signal.trap('USR1') { stop_requested = true }
      Signal.trap('TERM') { stop_requested = true }
      Signal.trap('HUP')  { stop_requested = true }

      job_dir = RubyProgress::Daemon.job_dir_for_pid(pid_file)
      job_thread = Thread.new { process_daemon_jobs_for_rippler(job_dir, rippler, options) }

      rippler.advance until stop_requested
    ensure
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor

      # If a control message file exists, output its message with optional checkmark
      cmf = RubyProgress::Daemon.control_message_file(pid_file)
      if File.exist?(cmf)
        begin
          data = JSON.parse(File.read(cmf))
          message = data['message']
          check = if data.key?('checkmark')
                    data['checkmark'] ? true : false
                  else
                    false
                  end
          success_val = if data.key?('success')
                          data['success'] ? true : false
                        else
                          true
                        end
          if message
            RubyProgress::Utils.display_completion(
              message,
              success: success_val,
              show_checkmark: check,
              output_stream: :stdout
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

      # stop job thread and cleanup
      job_thread&.kill
      FileUtils.rm_f(pid_file)
    end
  end

  def self.process_daemon_jobs_for_rippler(job_dir, rippler, options)
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

      rippler.instance_variable_set(:@output_capture, oc)
      oc.wait
      captured = oc.lines.join("\n")
      exit_status = oc.exit_status
      rippler.instance_variable_set(:@output_capture, nil)

      success = exit_status.to_i.zero?
      if job['message']
        RubyProgress::Utils.display_completion(
          job['message'],
          success: success,
          show_checkmark: job['checkmark'] || false,
          output_stream: :stdout
        )
      end

      { 'exit_status' => exit_status, 'output' => captured, 'log_path' => log_path }
    rescue StandardError
      # ignore per-job errors; process_jobs will write result
      nil
    end
  end

  # Options parsing moved to ripple_options.rb
end
