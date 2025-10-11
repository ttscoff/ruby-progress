# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'json'

# Twirl CLI (extracted from bin/prg)
module TwirlCLI
  def self.run
    options = parse_cli_options

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
      PrgCLI.daemonize
      run_daemon_mode(options)
    elsif options[:command]
      run_with_command(options)
    else
      run_indefinitely(options)
    end
  end

  def self.run_with_command(options)
    message = options[:message]
    captured_output = nil

    spinner = TwirlSpinner.new(message, options)
    success = false

    begin
      RubyProgress::Utils.hide_cursor
      spinner_thread = Thread.new { loop { spinner.animate } }

      captured_output = `#{options[:command]} 2>&1`
      success = $CHILD_STATUS.success?

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
        show_checkmark: options[:checkmark]
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
          show_checkmark: options[:checkmark]
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

  def self.parse_cli_options
    options = {}

    OptionParser.new do |opts|
      opts.banner = 'Usage: prg twirl [options]'
      opts.separator ''
      opts.separator 'Animation Options:'

      opts.on('-s', '--speed SPEED', 'Animation speed (1-10, fast/medium/slow, or f/m/s)') do |speed|
        options[:speed] = speed
      end

      opts.on('-m', '--message MESSAGE', 'Message to display before spinner') do |message|
        options[:message] = message
      end

      opts.on('--style STYLE', 'Spinner style (see --show-styles for options)') do |style|
        options[:style] = style
      end

      opts.on('--ends CHARS', 'Start/end characters (even number of chars, split in half)') do |chars|
        options[:ends] = chars
      end

      opts.separator ''
      opts.separator 'Command Execution:'

      opts.on('-c', '--command COMMAND', 'Command to run (optional - runs indefinitely without)') do |command|
        options[:command] = command
      end

      opts.on('--success MESSAGE', 'Success message to display') do |text|
        options[:success] = text
      end

      opts.on('--error MESSAGE', 'Error message to display') do |text|
        options[:error] = text
      end

      opts.on('--checkmark', 'Show checkmarks (✅ success, 🛑 failure)') do
        options[:checkmark] = true
      end

      opts.on('--stdout', 'Output captured command result to STDOUT') do |_text|
        options[:stdout] = true
      end

      opts.separator ''
      opts.separator 'Daemon Mode:'

      opts.on('--daemon', 'Run in background daemon mode') do
        options[:daemon] = true
      end

      opts.on('--daemon-as NAME', 'Run in daemon mode with custom name (creates /tmp/ruby-progress/NAME.pid)') do |name|
        options[:daemon] = true
        options[:daemon_name] = name
      end

      opts.on('--pid-file FILE', 'Write process ID to file (default: /tmp/ruby-progress/progress.pid)') do |file|
        options[:pid_file] = file
      end

      opts.on('--stop', 'Stop daemon (uses default PID file unless --pid-file specified)') do
        options[:stop] = true
      end
      opts.on('--stop-id NAME', 'Stop daemon by name (automatically implies --stop)') do |name|
        options[:stop] = true
        options[:stop_name] = name
      end
      opts.on('--status', 'Show daemon status (uses default PID file unless --pid-file specified)') do
        options[:status] = true
      end
      opts.on('--status-id NAME', 'Show daemon status by name') do |name|
        options[:status] = true
        options[:status_name] = name
      end
      opts.on('--stop-success MESSAGE', 'Stop daemon with success message (automatically implies --stop)') do |msg|
        options[:stop] = true
        options[:stop_success] = msg
      end
      opts.on('--stop-error MESSAGE', 'Stop daemon with error message (automatically implies --stop)') do |msg|
        options[:stop] = true
        options[:stop_error] = msg
      end
      opts.on('--stop-checkmark', 'When stopping, include a success checkmark') { options[:stop_checkmark] = true }

      opts.separator ''
      opts.separator 'Daemon notes:'
      opts.separator '  - Do not append &; prg detaches itself and returns immediately.'
      opts.separator '  - Use --daemon-as NAME for named daemons, or --stop-id/--status-id for named control.'

      opts.separator ''
      opts.separator 'General:'

      opts.on('--show-styles', 'Show available twirl styles with visual previews') do
        PrgCLI.show_twirl_styles
        exit
      end

      opts.on('--stop-all', 'Stop all prg twirl processes') do
        success = PrgCLI.stop_subcommand_processes('twirl')
        exit(success ? 0 : 1)
      end

      opts.on('-v', '--version', 'Show version') do
        puts "Twirl version #{RubyProgress::VERSION}"
        exit
      end

      opts.on('-h', '--help', 'Show this help') do
        puts opts
        exit
      end
    end.parse!

    options
  rescue OptionParser::InvalidOption => e
    puts "Invalid option: #{e.args.first}"
    puts ''
    puts 'Usage: prg twirl [options]'
    puts "Run 'prg twirl --help' for more information."
    exit 1
  end
end
