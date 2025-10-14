# frozen_string_literal: true

require 'optparse'

module WormCLI
  # Option parsing helpers for the Worm subcommand.
  #
  # Keeps the CLI option definitions for `prg worm` extracted from
  # the main dispatcher to keep the CLI module small and focused.
  module Options
    def self.parse_cli_options
      options = {
        output_position: :above,
        output_lines: 3
      }
      # rubocop:disable Metrics/BlockLength
      begin
        OptionParser.new do |opts|
          opts.banner = 'Usage: prg worm [options]'
          opts.separator ''
          opts.separator 'Animation Options:'

          opts.on('-s', '--speed SPEED', 'Animation speed (1-10, fast/medium/slow, or f/m/s)') do |speed|
            options[:speed] = speed
          end

          opts.on('-m', '--message MESSAGE', 'Message to display before animation') do |message|
            options[:message] = message
          end

          opts.on('-l', '--length LENGTH', Integer, 'Number of dots to display') do |length|
            options[:length] = length
          end

          opts.on('--style STYLE', 'Animation style (circles/blocks/geometric, c/b/g, or custom=abc)') do |style|
            options[:style] = style
          end

          opts.on('-d', '--direction DIRECTION', 'Animation direction (forward/bidirectional or f/b)') do |direction|
            options[:direction] = direction =~ /^f/i ? :forward_only : :bidirectional
          end

          opts.on('--ends CHARS', 'Start/end characters (even number of chars, split in half)') do |chars|
            options[:ends] = chars
          end

          opts.separator ''
          opts.separator 'Command Execution:'

          opts.on('-c', '--command COMMAND', 'Command to run (optional - runs indefinitely without)') do |command|
            options[:command] = command
          end

          opts.on('--output-position POSITION', 'Position to render captured output: above or below (default: above)') do |pos|
            options[:output_position] = pos.to_sym
          end

          opts.on('--output-lines N', Integer, 'Number of output lines to reserve for captured output (default: 3)') do |n|
            options[:output_lines] = n
          end

          opts.on('--success MESSAGE', 'Success message to display') do |text|
            options[:success] = text
          end

          opts.on('--success-icon ICON', 'Custom success icon to show with completion messages') do |ic|
            options[:success_icon] = ic
          end

          opts.on('--error-icon ICON', 'Custom error icon to show with failure messages') do |ic|
            options[:error_icon] = ic
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

          opts.on('--stdout-live', 'Stream captured output to STDOUT as it arrives (non-blocking)') do
            options[:stdout_live] = true
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

          # Accept --daemon-name as an alias for --daemon-as for compatibility
          opts.on('--daemon-name NAME', 'Alias for --daemon-as (compat)') do |name|
            options[:daemon] = true
            options[:daemon_name] = name
          end

          opts.on('--no-detach', 'When used with --daemon/--daemon-as: run background child but do not fully detach from the terminal') do
            options[:no_detach] = true
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

          opts.on('--stop-all', 'Stop all prg worm processes') do
            success = PrgCLI.stop_subcommand_processes('worm')
            exit(success ? 0 : 1)
          end

          opts.on('--stop-pid FILE', 'Stop daemon by reading PID from file (deprecated: use --stop [--pid-file])') do |file|
            RubyProgress::Daemon.stop_daemon_by_pid_file(file)
            exit
          end

          opts.separator ''
          opts.separator 'Daemon notes:'
          opts.separator '  - Do not append &; prg detaches itself and returns immediately.'
          opts.separator '  - Use --daemon-as NAME for named daemons, or --stop-id/--status-id for named control.'

          opts.separator ''
          opts.separator 'General:'

          opts.on('--show-styles', 'Show available worm styles with visual previews') do
            PrgCLI.show_worm_styles
            exit
          end

          opts.on('--stop-all', 'Stop all prg worm processes') do
            success = PrgCLI.stop_subcommand_processes('worm')
            exit(success ? 0 : 1)
          end

          opts.on('-v', '--version', 'Show version') do
            puts "Worm version #{RubyProgress::VERSION}"
            exit
          end

          opts.on('-h', '--help', 'Show this help') do
            puts opts
            exit
          end
        end.parse!
      rescue OptionParser::InvalidOption => e
        puts "Invalid option: #{e.args.first}"
        puts ''
        puts 'Usage: prg worm [options]'
        puts "Run 'prg worm --help' for more information."
        exit 1
      end
      # rubocop:enable Metrics/BlockLength
      options
    end
  end
end
