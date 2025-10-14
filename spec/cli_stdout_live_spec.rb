# frozen_string_literal: true

require 'spec_helper'
require 'pty'
require 'tempfile'

RSpec.describe 'CLI stdout/live flags' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  # Helper: run a command in a PTY and capture incremental output until exit
  def run_in_pty(cmd, timeout: 5)
    out = String.new
    PTY.spawn(cmd) do |r, _w, pid|
      start_time = Time.now

      loop do
        begin
          chunk = r.read_nonblock(4096)
          out << chunk if chunk
        rescue IO::WaitReadable
          # no data right now
        rescue Errno::EIO
          # PTY finished
          break
        end

        break if (Time.now - start_time) > timeout

        # short sleep to avoid busy loop
        sleep 0.01

        # if process has exited, try to drain remaining data
        begin
          pid_val = Process.waitpid(pid, Process::WNOHANG)
          break if pid_val
        rescue Errno::ECHILD
          break
        end
      end

      # Ensure process is reaped
      begin
        Process.wait(pid)
      rescue StandardError
        nil
      end
    end

    out
  end

  it 'does not print captured output during run with --stdout (non-live) but prints at end' do
    script = Tempfile.new(['nonlive', '.sh'])
    script.write("#!/usr/bin/env bash\nfor i in 1 2 3; do echo nonlive_ok:$i; sleep 0.12; done\n")
    script.close
    File.chmod(0o700, script.path)

    cmd = "ruby #{bin_path} worm --length 6 --speed 0.05 --command #{script.path} --stdout --output-lines 2 --output-position top"

    out = run_in_pty(cmd, timeout: 4)

    # With --output-lines 2 the capture only retains the last two lines,
    # so we expect the final output to include nonlive_ok:2 and nonlive_ok:3.
    expect(out).not_to include('nonlive_ok:1')
    expect(out).to include('nonlive_ok:2')
    expect(out).to include('nonlive_ok:3')
  end

  it 'prints captured output during run when --stdout-live is used' do
    script = Tempfile.new(['live', '.sh'])
    script.write("#!/usr/bin/env bash\nfor i in 1 2 3; do echo live_ok:$i; sleep 0.12; done\n")
    script.close
    File.chmod(0o700, script.path)

    cmd = "ruby #{bin_path} worm --length 6 --speed 0.05 --command #{script.path} --stdout-live --output-lines 2 --output-position top"

    out = run_in_pty(cmd, timeout: 4)

    # For live streaming we expect the live markers to be present in the PTY
    # output (they will be emitted during the run via redraw).
    expect(out).to include('live_ok:1')
    expect(out).to include('live_ok:2')
    expect(out).to include('live_ok:3')
  end
end
# frozen_string_literal: true

RSpec.describe 'CLI stdout/live flags' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  # Helper: run a command in a PTY and capture incremental output until exit
  def run_in_pty(cmd, timeout: 5)
    out = String.new
    PTY.spawn(cmd) do |r, _w, pid|
      start_time = Time.now
      loop do
        begin
          chunk = r.read_nonblock(4096)
          out << chunk if chunk
        rescue IO::WaitReadable
          # no data right now
        rescue Errno::EIO
          # PTY finished
          break
        end

        break if (Time.now - start_time) > timeout

        # short sleep to avoid busy loop
        sleep 0.01

        # if process has exited, try to drain remaining data
        begin
          pid_val = Process.waitpid(pid, Process::WNOHANG)
          break if pid_val
        rescue Errno::ECHILD
          break
        end
      end

      # Ensure process is reaped
      begin
        Process.wait(pid)
      rescue StandardError
        nil
      end
    end

    out
  end

  it 'does not print captured output during run with --stdout (non-live) but prints at end' do
    require 'tempfile'
    script = Tempfile.new(['nonlive', '.sh'])
    script.write("#!/usr/bin/env bash\nfor i in 1 2 3; do echo nonlive_ok:$i; sleep 0.12; done\n")
    script.close
    File.chmod(0o700, script.path)

    cmd = "ruby #{bin_path} worm --length 6 --speed 0.05 --command #{script.path} --stdout --output-lines 2 --output-position top"

    out = run_in_pty(cmd, timeout: 4)

    # With --output-lines 2 the capture only retains the last two lines,
    # so we expect the final output to include nonlive_ok:2 and nonlive_ok:3.
    expect(out).not_to include('nonlive_ok:1')
    expect(out).to include('nonlive_ok:2')
    expect(out).to include('nonlive_ok:3')
  end

  it 'prints captured output during run when --stdout-live is used' do
    script = Tempfile.new(['live', '.sh'])
    script.write("#!/usr/bin/env bash\nfor i in 1 2 3; do echo live_ok:$i; sleep 0.12; done\n")
    script.close
    File.chmod(0o700, script.path)

    cmd = "ruby #{bin_path} worm --length 6 --speed 0.05 --command #{script.path} --stdout-live --output-lines 2 --output-position top"

    out = run_in_pty(cmd, timeout: 4)

    # For live streaming we expect the live markers to be present in the PTY
    # output (they will be emitted during the run via redraw).
    expect(out).to include('live_ok:1')
    expect(out).to include('live_ok:2')
    expect(out).to include('live_ok:3')
  end
end
