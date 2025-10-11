# frozen_string_literal: true

require 'optparse'
require 'json'

module TwirlCLI
  module Options
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

        opts.on('--stdout', 'Output captured command result to STDOUT') do
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
end
