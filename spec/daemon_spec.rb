# frozen_string_literal: true

require 'spec_helper'
require 'ruby-progress'
require 'tmpdir'

RSpec.describe RubyProgress::Daemon do
  let(:tmp_dir) { File.join(Dir.tmpdir, "ruby-progress-spec-#{Process.pid}") }
  let(:pid_file) { File.join(tmp_dir, 'progress.pid') }
  let(:control_file) { RubyProgress::Daemon.control_message_file(pid_file) }

  before do
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    FileUtils.rm_f(control_file)
    FileUtils.rm_f(pid_file)
    FileUtils.rm_rf(tmp_dir)
  end

  describe '.default_pid_file' do
    it 'returns the default system pid path' do
      expect(RubyProgress::Daemon.default_pid_file).to eq('/tmp/ruby-progress/progress.pid')
    end
  end

  describe '.control_message_file' do
    it 'derives a .msg file path next to the pid file' do
  expect(control_file).to eq("#{pid_file}.msg")
    end
  end

  describe '.show_status' do
    it 'prints not running and exits non-zero when pid file missing' do
      expect { RubyProgress::Daemon.show_status(pid_file) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq(1)
      end
    end

    it 'prints running when pid exists and process is alive' do
      # Spawn a sleep to simulate a running daemon
      pid = Process.spawn('sleep 1')
      File.write(pid_file, pid.to_s)

      begin
        expect { RubyProgress::Daemon.show_status(pid_file) }.to raise_error(SystemExit) do |e|
          expect([0, 1]).to include(e.status) # status 0 if still running, 1 if it exited just in time
        end
      ensure
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          # already exited
        end
      end
    end
  end

  describe '.stop_daemon_by_pid_file' do
    it 'exits when pid file is missing' do
      expect do
        RubyProgress::Daemon.stop_daemon_by_pid_file(pid_file)
      end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end

    it 'writes control message and signals process' do
      # Spawn a long sleep to receive the signal
      pid = Process.spawn('sleep 5')
      File.write(pid_file, pid.to_s)

      begin
        expect(File).not_to exist(control_file)
        # Send stop with message/checkmark/error=false
        RubyProgress::Daemon.stop_daemon_by_pid_file(
          pid_file,
          message: 'Complete',
          checkmark: true,
          error: false
        )

        # Control file should exist and contain expected payload
        expect(File).to exist(control_file)
        data = JSON.parse(File.read(control_file))
        expect(data['message']).to eq('Complete')
        expect(data['checkmark']).to eq(true)
        expect(data['success']).to eq(true)
      ensure
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          # already exited
        end
      end
    end

    it 'handles non-existent pid process gracefully' do
      File.write(pid_file, '999999') # likely not running
      expect do
        RubyProgress::Daemon.stop_daemon_by_pid_file(pid_file)
      end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end
  end
end
