# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require_relative 'cli/fill_options'

module RubyProgress
  # CLI module for Fill command
  module FillCLI
    class << self
      def run
        trap('INT') do
          Utils.show_cursor
          exit
        end

        options = RubyProgress::FillCLI::Options.parse_cli_options

        # Handle daemon control first
        if options[:status] || options[:stop]
          pid_file = options[:pid_file] || '/tmp/ruby-progress/fill.pid'
          if options[:status]
            Daemon.show_status(pid_file)
          else
            Daemon.stop_daemon_by_pid_file(pid_file)
          end
          exit
        end

        # Parse style option
        parsed_style = parse_fill_style(options[:style])

        if options[:daemon]
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
        # For daemon mode, detach the process
        PrgCLI.daemonize

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
          Fill.show_cursor
          FileUtils.rm_f(pid_file)
        end
      end

      def show_current_percentage(options, _parsed_style)
        # Just output the percentage for scripting (default to 50% for demonstration)
        percentage = options[:percent] || 50
        puts percentage.to_f
      end

      def show_progress_report(options, parsed_style)
        # Create a fill bar to demonstrate current progress
        fill_options = {
          style: parsed_style,
          length: options[:length],
          ends: options[:ends]
        }

        fill_bar = Fill.new(fill_options)

        # Set percentage (default to 50% for demonstration)
        fill_bar.percent = options[:percent] || 50

        # Get detailed report
        report = fill_bar.report

        # Display the current progress bar and detailed status
        fill_bar.render
        puts "\nProgress Report:"
        puts "  Progress: #{report[:progress][0]}/#{report[:progress][1]}"
        puts "  Percent: #{report[:percent]}%"
        puts "  Completed: #{report[:completed] ? 'Yes' : 'No'}"
        puts "  Style: #{report[:style]}"
      end

      def handle_progress_commands(_options, _parsed_style)
        # For progress commands, we assume there's a daemon running
        # This is a simplified version - in a real implementation,
        # we'd need IPC to communicate with the daemon
        warn 'Progress commands require daemon mode implementation'
        warn "Run 'prg fill --daemon' first, then use progress commands"
        exit 1
      end

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

        begin
          if options[:percent]
            # Set to specific percentage
            fill_bar.percent = options[:percent]
            fill_bar.render
            unless fill_bar.completed?
              # For non-complete percentages, show the result briefly
              sleep(0.1)
            end
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
