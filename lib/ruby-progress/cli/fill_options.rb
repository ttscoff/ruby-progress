# frozen_string_literal: true

require 'optparse'

module RubyProgress
  module FillCLI
    # Option parsing extracted to reduce module length in FillCLI
    module Options
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

            opts.on('--pid-file FILE', 'PID file location (default: /tmp/ruby-progress/fill.pid)') do |file|
              options[:pid_file] = file
            end

            opts.on('--stop', 'Stop daemon') do
              options[:stop] = true
            end

            opts.on('--status', 'Show daemon status') do
              options[:status] = true
            end

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
    end
  end
end
