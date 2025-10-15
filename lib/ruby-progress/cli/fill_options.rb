# frozen_string_literal: true

require 'optparse'

module RubyProgress
  module FillCLI
    # Option parsing extracted to reduce module length in FillCLI
    # rubocop:disable Metrics/AbcSize
    module Options
      # rubocop :disable Metrics/MethodLength
      def self.parse_cli_options
        options = {
          style: :blocks,
          length: 20,
          speed: :medium,
          percent: nil,
          advance: false,
          complete: false,
          cancel: false,
          success_message: nil,
          error_message: nil,
          checkmark: false,
          daemon: false,
          pid_file: nil,
          stop: false,
          status: false,
          current: false,
          output_position: :above,
          output_lines: 3,
          report: false
        }

        begin
          OptionParser.new do |opts|
            opts.banner = 'Usage: prg fill [options]'
            opts.separator ''
            opts.separator 'Progress Bar Options:'

            opts.on('-l', '--length LENGTH', Integer, 'Progress bar length (default: 20)') do |length|
              options[:length] = length
            end

            opts.on('-s', '--style STYLE', 'Progress bar style (blocks, classic, dots, etc. or custom=XY)') do |style|
              options[:style] = style
            end

            opts.on('--ends CHARS', 'Start/end characters (even number of chars, split in half)') do |chars|
              options[:ends] = chars
            end

            opts.separator 'Output capture:'

            opts.on('-c', '--command COMMAND', 'Command to run and capture output (optional)') do |cmd|
              options[:command] = cmd
            end

            opts.on('--output-position POSITION', 'Position to render captured output: above or below (default: above)') do |pos|
              options[:output_position] = pos.to_sym
            end

            opts.on('--output-lines N', Integer, 'Number of output lines to reserve for captured output (default: 3)') do |n|
              options[:output_lines] = n
            end

            opts.on('--stdout-live', 'Stream captured output to STDOUT as it arrives (non-blocking)') do
              options[:stdout_live] = true
            end

            opts.separator ''
            opts.separator 'Progress Control:'

            opts.on('-p', '--percent PERCENT', Float, 'Set progress to percentage (0-100)') do |percent|
              options[:percent] = percent
            end

            opts.on('--advance', 'Advance progress by one step') do
              options[:advance] = true
            end

            opts.on('--complete', 'Complete the progress bar') do
              options[:complete] = true
            end

            opts.on('--cancel', 'Cancel the progress bar') do
              options[:cancel] = true
            end

            opts.on('--current', 'Show current progress percentage (0-100 float)') do
              options[:current] = true
            end

            opts.on('--report', 'Show detailed progress report') do
              options[:report] = true
            end

            opts.separator ''
            opts.separator 'Auto-advance Mode:'

            opts.on('--speed SPEED', 'Auto-advance speed (fast/medium/slow or numeric)') do |speed|
              options[:speed] = case speed.downcase
                                when /^f/ then :fast
                                when /^m/ then :medium
                                when /^s/ then :slow
                                else speed.to_f.positive? ? speed.to_f : :medium
                                end
            end

            opts.separator ''
            opts.separator 'Messages:'

            opts.on('--success MESSAGE', 'Success message to display on completion') do |msg|
              options[:success_message] = msg
            end

            opts.on('--success-icon ICON', 'Custom success icon to show with completion messages') do |ic|
              options[:success_icon] = ic
            end

            opts.on('--error-icon ICON', 'Custom error icon to show with failure messages') do |ic|
              options[:error_icon] = ic
            end

            opts.on('--error MESSAGE', 'Error message to display on cancellation') do |msg|
              options[:error_message] = msg
            end

            opts.on('--checkmark', 'Show checkmarks (✅ success, 🛑 failure)') do
              options[:checkmark] = true
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

            # Accept --daemon-name as alias for --daemon-as
            opts.on('--daemon-name NAME', 'Alias for --daemon-as (compat)') do |name|
              options[:daemon] = true
              options[:daemon_name] = name
            end

            opts.on('--pid-file FILE', 'PID file location (default: /tmp/ruby-progress/fill.pid)') do |file|
              options[:pid_file] = file
            end

            opts.on('--stop', 'Stop daemon') do
              options[:stop] = true
            end

            opts.on('--stop-id NAME', 'Stop daemon by name (implies --stop)') do |name|
              # Backwards-compatible shorthand used in demos: set stop flag
              options[:stop] = true
              # Normalize to canonical keys used by FillCLI (daemon_name/status_name)
              options[:stop_name] = name
              options[:daemon_name] = name
              options[:status_name] = name
            end

            opts.on('--status', 'Show daemon status') do
              options[:status] = true
            end

            opts.on('--status-id NAME', 'Show daemon status by name') do |name|
              options[:status] = true
              # Normalize to canonical key
              options[:status_name] = name
              options[:daemon_name] = name
            end

            opts.on('--stop-success MESSAGE', 'Stop daemon with success message (implies --stop)') do |msg|
              options[:stop] = true
              options[:stop_success] = msg
            end
            opts.on('--stop-error MESSAGE', 'Stop daemon with error message (implies --stop)') do |msg|
              options[:stop] = true
              options[:stop_error] = msg
            end
            opts.on('--stop-checkmark', 'When stopping, include a success checkmark') { options[:stop_checkmark] = true }

            opts.separator ''
            opts.separator 'General:'

            opts.on('--show-styles', 'Show available fill styles with visual previews') do
              options[:show_styles] = true
            end

            opts.on('-v', '--version', 'Show version') do
              options[:version] = true
            end

            opts.on('-h', '--help', 'Show this help') do
              options[:help] = true
            end
          end.parse!
        rescue OptionParser::InvalidOption => e
          warn "Invalid option: #{e.args.first}"
          warn ''
          warn 'Usage: prg fill [options]'
          warn "Run 'prg fill --help' for more information."
          exit 1
        end
        options
      end
      # rubocop :enable Metrics/MethodLength

      def self.help_text
        opts = OptionParser.new

        opts.banner = 'Usage: prg fill [options]'
        opts.separator ''
        opts.separator 'Progress Bar Options:'

        opts.on('-l', '--length LENGTH', Integer, 'Progress bar length (default: 20)')
        opts.on('-s', '--style STYLE', 'Progress bar style (blocks, classic, dots, etc. or custom=XY)')
        opts.on('--ends CHARS', 'Start/end characters (even number of chars, split in half)')

        opts.separator ''
        opts.separator 'Progress Control:'
        opts.on('-p', '--percent PERCENT', Float, 'Set progress to percentage (0-100)')
        opts.on('--advance', 'Advance progress by one step')
        opts.on('--complete', 'Complete the progress bar')
        opts.on('--cancel', 'Cancel the progress bar')
        opts.on('--current', 'Show current progress percentage (0-100 float)')
        opts.on('--report', 'Show detailed progress report')

        opts.separator ''
        opts.separator 'Auto-advance Mode:'
        opts.on('--speed SPEED', 'Auto-advance speed (fast/medium/slow or numeric)')

        opts.separator ''
        opts.separator 'Messages:'
        opts.on('--success MESSAGE', 'Success message to display on completion')
        opts.on('--error MESSAGE', 'Error message to display on cancellation')
        opts.on('--checkmark', 'Show checkmarks (✅ success, 🛑 failure)')

        opts.separator ''
        opts.separator ''
        opts.separator 'Output capture:'
        opts.on('--output-position POSITION', 'Position to render captured output: above or below (default: above)')
        opts.on('--output-lines N', Integer, 'Number of output lines to reserve for captured output (default: 3)')

        opts.separator ''
        opts.separator 'Daemon Mode:'
        opts.on('--daemon', 'Run in background daemon mode')
        opts.on('--pid-file FILE', 'PID file location (default: /tmp/ruby-progress/fill.pid)')
        opts.on('--stop', 'Stop daemon')
        opts.on('--status', 'Show daemon status')

        opts.separator ''
        opts.separator 'General:'
        opts.on('--show-styles', 'Show available fill styles with visual previews')
        opts.on('-v', '--version', 'Show version')
        opts.on('-h', '--help', 'Show this help')

        opts.to_s
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
