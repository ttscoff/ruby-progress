#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'json'
require_relative '../utils'
require_relative '../output_capture'

# Runtime helper methods for RubyProgress::Worm
#
# These methods implement the interactive runtime behavior (animation
# loop, command execution, daemon mode, etc.) and were extracted from
# RubyProgress::Worm to reduce class length and improve readability.
module WormRunner
  def animate(message: nil, success: nil, error: nil)
    @message = message if message
    @success_text = success if success
    @error_text = error if error
    @running = true

    original_int_handler = Signal.trap('INT') do
      @running = false
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor
      exit 130
    end

    RubyProgress::Utils.hide_cursor
    animation_thread = Thread.new { animation_loop }

    begin
      if block_given?
        result = yield
        @running = false
        animation_thread.join
        display_completion_message(@success_text, true)
        result
      else
        animation_thread.join
      end
    rescue StandardError => e
      @running = false
      animation_thread.join
      display_completion_message(@error_text || "Error: #{e.message}", false)
      nil
    ensure
      $stderr.print "\r\e[2K"
      RubyProgress::Utils.show_cursor
      Signal.trap('INT', original_int_handler) if original_int_handler
    end
  end

  def run_with_command
    return unless @command

    exit_code = 0
    stdout_content = nil

    begin
      stdout_content = if $stdout.tty? && (@output_stdout || @output_live)
                         oc = RubyProgress::OutputCapture.new(
                           command: @command,
                           lines: @output_lines || 3,
                           position: @output_position || :above,
                           stream: @output_live || false
                         )
                         oc.start
                         @output_capture = oc
                         animate do
                           oc.wait
                         end
                         @output_capture = nil
                         oc.lines.join("\n")
                       else
                         animate do
                           Open3.popen3(@command) do |_stdin, stdout, stderr, wait_thr|
                             captured_stdout = stdout.read
                             stderr_content = stderr.read
                             exit_code = wait_thr.value.exitstatus

                             unless wait_thr.value.success?
                               error_msg = @error_text || "Command failed with exit code #{exit_code}"
                               error_msg += ": #{stderr_content.strip}" if stderr_content && !stderr_content.empty?
                               raise StandardError, error_msg
                             end

                             captured_stdout
                           end
                         end
                       end

      puts stdout_content if @output_stdout && stdout_content
    rescue StandardError
      exit exit_code.nonzero? || 1
    rescue Interrupt
      exit 130
    end
  end

  def run_indefinitely
    original_int_handler = Signal.trap('INT') do
      @running = false
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor
      exit 130
    end

    @running = true
    RubyProgress::Utils.hide_cursor

    begin
      animation_loop
    ensure
      RubyProgress::Utils.show_cursor
      Signal.trap('INT', original_int_handler) if original_int_handler
    end
  end

  def stop
    @running = false
  end

  def run_daemon_mode(success_message: nil, show_checkmark: false, control_message_file: nil, icons: {})
    @running = true
    stop_requested = false

    original_int_handler = Signal.trap('INT') { stop_requested = true }
    Signal.trap('USR1') { stop_requested = true }
    Signal.trap('TERM') { stop_requested = true }
    Signal.trap('HUP')  { stop_requested = true }

    RubyProgress::Utils.hide_cursor

    begin
      animation_loop_daemon_mode(stop_requested_proc: -> { stop_requested })
    ensure
      RubyProgress::Utils.clear_line
      RubyProgress::Utils.show_cursor

      final_message = success_message
      final_checkmark = show_checkmark ? true : false
      final_success = true

      if control_message_file && File.exist?(control_message_file)
        begin
          data = JSON.parse(File.read(control_message_file))
          final_message = data['message'] if data['message']
          final_checkmark = data['checkmark'] if data.key?('checkmark')
          final_success = data['success'] if data.key?('success')
        rescue StandardError
          # ignore parse errors
        ensure
          begin
            File.delete(control_message_file)
          rescue StandardError
            nil
          end
        end
      end

      if final_message
        RubyProgress::Utils.display_completion(
          final_message,
          success: final_success,
          show_checkmark: final_checkmark,
          output_stream: :stdout,
          icons: icons
        )
      end

      Signal.trap('INT', original_int_handler) if original_int_handler
    end
  end

  def animation_loop_step
    return unless @running

    @position ||= 0
    @direction ||= 1

    message_part = @message && !@message.empty? ? "#{@message} " : ''
    @output_capture&.redraw($stderr)
    $stderr.print "\r\e[2K#{@start_chars}#{message_part}#{generate_dots(@position, @direction)}#{@end_chars}"
    $stderr.flush

    sleep @speed

    @position += @direction
    if @position >= @length - 1
      if @direction_mode == :forward_only
        @position = 0
      else
        @direction = -1
      end
    elsif @position <= 0
      @direction = 1
    end
  end

  def animation_loop
    position = 0
    direction = 1

    while @running
      message_part = @message && !@message.empty? ? "#{@message} " : ''
      @output_capture&.redraw($stderr)
      $stderr.print "\r\e[2K#{@start_chars}#{message_part}#{generate_dots(position, direction)}#{@end_chars}"
      $stderr.flush

      sleep @speed

      position += direction
      if position >= @length - 1
        if @direction_mode == :forward_only
          position = 0
        else
          direction = -1
        end
      elsif position <= 0
        direction = 1
      end
    end
  end

  def animation_loop_daemon_mode(stop_requested_proc: -> { false })
    position = 0
    direction = 1
    frame_count = 0

    while @running && !stop_requested_proc.call
      message_part = @message && !@message.empty? ? "#{@message} " : ''
      @output_capture&.redraw($stderr)

      $stderr.print "\r\e[2K"

      if (frame_count % 10).zero?
        # Use ANSI save/restore to clear the previous line without moving the
        # global cursor position. This prevents the animation from erasing
        # reserved output lines that we draw elsewhere.
        $stderr.print "\e7"    # save
        $stderr.print "\e[1A\e[2K\r"
        $stderr.print "\e8"    # restore
      end

      $stderr.print "#{message_part}#{generate_dots(position, direction)}"
      $stderr.flush

      sleep @speed
      frame_count += 1

      position += direction
      if position >= @length - 1
        if @direction_mode == :forward_only
          position = 0
        else
          direction = -1
        end
      elsif position <= 0
        direction = 1
      end
    end
  end

  def generate_dots(ripple_position, direction)
    dots = Array.new(@length) { @style[:baseline] }

    (0...@length).each do |i|
      distance = (i - ripple_position).abs
      case distance
      when 0
        dots[i] = @style[:peak]
      when 1
        if direction == -1
          dots[i] = @style[:midline] if i > ripple_position
        elsif i < ripple_position
          dots[i] = @style[:midline]
        end
      else
        dots[i] = @style[:baseline]
      end
    end

    dots.join
  end
end
