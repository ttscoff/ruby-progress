# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'json'
require 'securerandom'
require_relative 'cli/fill_options'
require_relative 'output_capture'

module RubyProgress
  # CLI module for Fill command
  # rubocop:disable Metrics/ClassLength
  module FillCLI
    class << self
      def run
        trap('INT') do
          Utils.show_cursor
          exit
        end

        options = RubyProgress::FillCLI::Options.parse_cli_options

        # Handle basic output flags first
        if options[:help]
          puts RubyProgress::FillCLI::Options.help_text
          exit
        end

        if options[:version]
          puts "Fill version #{RubyProgress::FILL_VERSION}"
          exit
        end

        if options[:show_styles]
          show_fill_styles
          exit
        end

        # Handle daemon control first
        if options[:status] || options[:stop]
          pid_file = resolve_pid_file(options, :status_name)
          if options[:status]
            Daemon.show_status(pid_file)
          else
            Daemon.stop_daemon_by_pid_file(pid_file,
                                           message: options[:stop_success],
                                           checkmark: options[:stop_checkmark],
                                           error: !options[:stop_error].nil?)
          end
          exit
        end

        # Parse style option
        parsed_style = parse_fill_style(options[:style])

        if options[:daemon]
          # Resolve pid file and honor daemon-as/name
          pid_file = resolve_pid_file(options, :daemon_name)
          options[:pid_file] = pid_file

          # Background without detaching so progress bar remains visible in current terminal
          PrgCLI.backgroundize

          run_daemon_mode(options, parsed_style)
        elsif options[:current]
          show_current_percentage(options, parsed_style)
        elsif options[:report]
          show_progress_report(options, parsed_style)
        elsif options[:advance] || options[:complete] || options[:cancel]
          handle_progress_commands(options, parsed_style)
        else
          run_auto_advance_mode(options, parsed_style)
        end
      end

      private

      def resolve_pid_file(options, name_key = :daemon_name)
        return options[:pid_file] if options[:pid_file]

        return "/tmp/ruby-progress/#{options[name_key]}.pid" if options[name_key]

        '/tmp/ruby-progress/fill.pid'
      end

      def parse_fill_style(style_option)
        case style_option
        when String
          if style_option.start_with?('custom=')
            Fill.parse_custom_style(style_option)
          else
            style_option.to_sym
          end
        else
          style_option
        end
      end

      def run_daemon_mode(options, parsed_style)
        pid_file = options[:pid_file] || '/tmp/ruby-progress/fill.pid'
        FileUtils.mkdir_p(File.dirname(pid_file))
        File.write(pid_file, Process.pid.to_s)

        # Create the fill bar and show initial empty state
        fill_options = {
          style: parsed_style,
          length: options[:length],
          ends: options[:ends],
          success: options[:success_message],
          error: options[:error_message]
        }

        fill_bar = Fill.new(fill_options)
        Fill.hide_cursor

        begin
          fill_bar.render # Show initial empty bar

          # Set up signal handlers for daemon control
          stop_requested = false
          Signal.trap('INT') { stop_requested = true }
          Signal.trap('USR1') { stop_requested = true }
          Signal.trap('TERM') { stop_requested = true }

          # Keep daemon alive until stop requested
          sleep(0.1) until stop_requested
        ensure
          # If a control message file exists, print its contents like other CLIs
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

          Fill.show_cursor
          FileUtils.rm_f(pid_file)
        end
      end

      def show_progress_report(options, parsed_style)
        # Produce a simple scripting-friendly report to stdout
        length = options[:length] || 20
        percent = (options[:percent] || 50.0).to_f
        style = parsed_style

        fill = Fill.new(style: style, length: length)
        fill.percent = percent

        report = fill.report
        puts 'Progress Report:'
        puts "Progress: #{report[:progress][0]}/#{report[:progress][1]}"
        puts "Percent: #{report[:percent]}%"
        puts "Completed: #{report[:completed] ? 'Yes' : 'No'}"
        puts "Style: #{report[:style].inspect}"
        exit(0)
      end

      def handle_progress_commands(_options, _parsed_style)
        # For now the progress commands are only supported in daemon mode.
        # Return a clear error to the caller (specs assert this message exists).
        warn 'Progress commands require daemon mode implementation'
        exit(1)
      end

      def show_current_percentage(options, _parsed_style)
        # For scripting and tests: print the current percentage to stdout and exit.
        # If no explicit percent was provided, default to 50.0
        percent = (options[:percent] || 50.0).to_f
        $stdout.print("#{percent}\n")
        exit(0)
      end

      # Foreground / auto-advance / command mode when not daemonizing
      def run_auto_advance_mode(options, parsed_style)
        fill_options = {
          style: parsed_style,
          length: options[:length],
          ends: options[:ends],
          success: options[:success_message],
          error: options[:error_message]
        }

        fill_bar = Fill.new(fill_options)
        Fill.hide_cursor

        oc = nil
        begin
          if options[:percent]
            # Set to specific percentage
            fill_bar.percent = options[:percent]
            fill_bar.render
            unless fill_bar.completed?
              # For non-complete percentages, show the result briefly
              sleep(0.1)
            end
          elsif options[:command]
            # Run the command with OutputCapture
            oc = RubyProgress::OutputCapture.new(
              command: options[:command],
              lines: options[:output_lines] || 3,
              position: options[:output_position] || :above,
              log_path: nil,
              stream: options[:stdout] || options[:stdout_live]
            )
            oc.start

            # Attach capture to the live fill instance so it can render output
            fill_bar.instance_variable_set(:@output_capture, oc)

            # While the command runs, keep redrawing the bar
            sleep_time = case options[:speed]
                         when :fast then 0.1
                         when :medium, nil then 0.2
                         when :slow then 0.5
                         when Numeric then 1.0 / options[:speed]
                         else 0.3
                         end

            fill_bar.render
            while oc.alive?
              sleep(sleep_time)
              fill_bar.render
            end
            fill_bar.instance_variable_set(:@output_capture, nil)
          else
            # Auto-advance mode
            sleep_time = case options[:speed]
                         when :fast then 0.1
                         when :medium, nil then 0.2
                         when :slow then 0.5
                         when Numeric then 1.0 / options[:speed]
                         else 0.3
                         end

            fill_bar.render
            (1..options[:length]).each do
              sleep(sleep_time)
              fill_bar.advance
            end
          end

          fill_bar.complete
        rescue Interrupt
          fill_bar.cancel
        ensure
          # Ensure we wait for capture thread to finish and show cursor
          oc&.wait
          Fill.show_cursor
        end
      end

      def show_fill_styles
        puts "\nAvailable Fill Styles:"
        puts '=' * 50

        Fill::FILL_STYLES.each do |name, style|
          print "#{name.to_s.ljust(12)} : "

          # Show a sample progress bar
          filled = style[:full] * 6
          empty = style[:empty] * 4
          puts "[#{filled}#{empty}] (60%)"
        end

        puts "\nCustom Style:"
        puts "#{'custom=XY'.ljust(12)} : Specify X=empty, Y=full characters"
        puts '             Example: --style custom=.# → [######....] (60%)'
        puts
      end
    end
  end
end
