# frozen_string_literal: true

require 'optparse'
require 'json'

module RippleCLI
  # Option parsing extracted to its own file to reduce module size of RippleCLI.
  module Options
    def self.parse_cli_options
      options = {
        speed: :medium,
        direction: :bidirectional,
        styles: [],
        caps: false,
        command: nil,
        success_message: nil,
        fail_message: nil,
        complete_checkmark: false,
        output: :error,
        message: nil
      }

      begin
        OptionParser.new do |opts|
          opts.banner = 'Usage: prg ripple [options] [STRING]'
          opts.separator ''
          opts.separator 'Animation Options:'

          opts.on('-s', '--speed SPEED', 'Animation speed (fast/medium/slow or f/m/s)') do |s|
            options[:speed] = case s.downcase
                              when /^f/ then :fast
                              when /^s/ then :slow
                              else :medium
                              end
          end

          opts.on('-m', '--message MESSAGE', 'Message to display (alternative to positional argument)') do |msg|
            options[:message] = msg
          end

          opts.on('--style STYLES', 'Animation styles (rainbow, inverse, caps - can be comma-separated)') do |styles|
            options[:styles] = styles.split(',').map(&:strip).map(&:to_sym)
          end

          opts.on('-d', '--direction DIRECTION', 'Animation direction (forward/bidirectional or f/b)') do |f|
            options[:format] = f =~ /^f/i ? :forward_only : :bidirectional
          end

          opts.on('--ends CHARS', 'Start/end characters (even number of chars, split in half)') do |chars|
            options[:ends] = chars
          end

          opts.separator ''
          opts.separator 'Command Execution:'

          opts.on('-c', '--command COMMAND', 'Run command during animation (optional)') do |command|
            options[:command] = command
          end

          opts.on('--success MESSAGE', 'Success message to display') do |msg|
            options[:success_message] = msg
          end

          opts.on('--error MESSAGE', 'Error message to display') do |msg|
            options[:fail_message] = msg
          end

          opts.on('--checkmark', 'Show checkmarks (✅ success, 🛑 failure)') do
            options[:complete_checkmark] = true
          end

          opts.on('--stdout', 'Output captured command result to STDOUT') do
            options[:output] = :stdout
          end

          opts.on('--quiet', 'Suppress all output') do
            options[:output] = :quiet
          end

          opts.separator ''
          opts.separator 'Daemon Mode:'

          opts.on('--daemon', 'Run in background daemon mode') do
            options[:daemon] = true
          end

          opts.on('--pid-file FILE', 'Write process ID to file (default: /tmp/ruby-progress/progress.pid)') do |file|
            options[:pid_file] = file
          end

          opts.on('--stop', 'Stop daemon (uses default PID file unless --pid-file specified)') do
            options[:stop] = true
          end

          opts.on('--status', 'Show daemon status (running/not running)') do
            options[:status] = true
          end

          opts.on('--stop-success MESSAGE', 'When stopping, show this success message') do |msg|
            options[:stop_success] = msg
          end
          opts.on('--stop-error MESSAGE', 'When stopping, show this error message') do |msg|
            options[:stop_error] = msg
          end
          opts.on('--stop-checkmark', 'When stopping, include a success/error checkmark') do
            options[:stop_checkmark] = true
          end

          opts.separator ''
          opts.separator 'Daemon notes:'
          opts.separator '  - Do not append &; prg detaches itself and returns immediately.'
          opts.separator '  - Use --status/--stop with optional --pid-file to control it.'

          opts.separator ''
          opts.separator 'General:'

          opts.on('--show-styles', 'Show available ripple styles with visual previews') do
            PrgCLI.show_ripple_styles
            exit
          end

          opts.on('--stop-all', 'Stop all prg ripple processes') do
            success = PrgCLI.stop_subcommand_processes('ripple')
            exit(success ? 0 : 1)
          end

          opts.on('-v', '--version', 'Show version') do
            puts "Ripple version #{RubyProgress::VERSION}"
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
        puts 'Usage: prg ripple [options] [STRING]'
        puts "Run 'prg ripple --help' for more information."
        exit 1
      end

      options
    end
  end
end
