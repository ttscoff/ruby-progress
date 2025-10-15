# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require_relative '../lib/ruby-progress/cli/job_cli'

RSpec.describe 'JobCLI' do
  let(:test_pid_dir) { '/tmp/ruby-progress-test-job-cli' }
  let(:test_pid_file) { File.join(test_pid_dir, 'test.pid') }

  before do
    FileUtils.mkdir_p(test_pid_dir)
  end

  after do
    FileUtils.rm_rf(test_pid_dir)
  end

  describe 'JobCLI.run' do
    it 'shows help when no arguments provided' do
      expect do
        JobCLI.run([])
      end.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'shows help with --help flag' do
      expect do
        JobCLI.run(['--help'])
      end.to output(/Usage: prg job/).to_stdout
    end

    it 'handles unknown subcommand' do
      expect do
        JobCLI.run(['unknown'])
      end.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  describe 'JobCLI.stop' do
    it 'exits with error when pid file does not exist' do
      expect do
        JobCLI.stop(['--pid-file', '/tmp/nonexistent.pid'])
      end.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'stops daemon when pid file exists (silent output)' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      # Should NOT output confirmation (silent operation)
      expect do
        JobCLI.stop(['--pid-file', test_pid_file])
      end.not_to output.to_stdout

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: nil,
        checkmark: false,
        error: false
      )
    end

    it 'stops daemon with message' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.stop(['--pid-file', test_pid_file, '--message', 'Finished!'])

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: 'Finished!',
        checkmark: false,
        error: false
      )
    end

    it 'stops daemon with checkmark' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.stop(['--pid-file', test_pid_file, '--checkmark'])

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: nil,
        checkmark: true,
        error: false
      )
    end

    it 'stops daemon with error flag' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.stop(['--pid-file', test_pid_file, '--error'])

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: nil,
        checkmark: false,
        error: true
      )
    end

    it 'resolves daemon name to pid file path' do
      daemon_pid_file = '/tmp/ruby-progress/mytask.pid'
      FileUtils.mkdir_p('/tmp/ruby-progress')
      File.write(daemon_pid_file, '99999')

      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.stop(['--daemon-name', 'mytask'])

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        daemon_pid_file,
        message: nil,
        checkmark: false,
        error: false
      )

      FileUtils.rm_f(daemon_pid_file)
    end
  end

  describe 'JobCLI.status' do
    it 'shows status for running daemon' do
      File.write(test_pid_file, Process.pid.to_s)
      allow(RubyProgress::Daemon).to receive(:show_status)

      JobCLI.status(['--pid-file', test_pid_file])

      expect(RubyProgress::Daemon).to have_received(:show_status).with(test_pid_file)
    end

    it 'resolves daemon name for status check' do
      daemon_pid_file = '/tmp/ruby-progress/statustest.pid'
      FileUtils.mkdir_p('/tmp/ruby-progress')
      File.write(daemon_pid_file, Process.pid.to_s)

      allow(RubyProgress::Daemon).to receive(:show_status)

      JobCLI.status(['--daemon-name', 'statustest'])

      expect(RubyProgress::Daemon).to have_received(:show_status).with(daemon_pid_file)

      FileUtils.rm_f(daemon_pid_file)
    end
  end

  describe 'JobCLI.advance' do
    it 'exits with error when pid file does not exist' do
      expect do
        JobCLI.advance(['--pid-file', '/tmp/nonexistent.pid'])
      end.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'advances progress by default amount (1)' do
      File.write(test_pid_file, '99999')
      control_file = "#{test_pid_file}.msg"

      allow(Process).to receive(:kill)

      # Should NOT output confirmation (silent operation)
      expect do
        JobCLI.advance(['--pid-file', test_pid_file])
      end.not_to output.to_stdout

      expect(File.exist?(control_file)).to be true
      control_data = JSON.parse(File.read(control_file))
      expect(control_data['action']).to eq('advance')
      expect(control_data['amount']).to eq(1)

      FileUtils.rm_f(control_file)
    end

    it 'advances progress by specified amount' do
      File.write(test_pid_file, '99999')
      control_file = "#{test_pid_file}.msg"

      allow(Process).to receive(:kill)

      JobCLI.advance(['--pid-file', test_pid_file, '--amount', '10'])

      control_data = JSON.parse(File.read(control_file))
      expect(control_data['action']).to eq('advance')
      expect(control_data['amount']).to eq(10)

      FileUtils.rm_f(control_file)
    end

    it 'resolves daemon name for advance' do
      daemon_pid_file = '/tmp/ruby-progress/advancetest.pid'
      FileUtils.mkdir_p('/tmp/ruby-progress')
      File.write(daemon_pid_file, '99999')
      control_file = "#{daemon_pid_file}.msg"

      allow(Process).to receive(:kill)

      JobCLI.advance(['--daemon-name', 'advancetest', '--amount', '5'])

      control_data = JSON.parse(File.read(control_file))
      expect(control_data['action']).to eq('advance')
      expect(control_data['amount']).to eq(5)

      FileUtils.rm_f(control_file)
      FileUtils.rm_f(daemon_pid_file)
    end
  end

  describe 'Backward compatibility: JobCLI.send' do
    it 'shows deprecation warning' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      expect do
        JobCLI.send(['--pid-file', test_pid_file])
      end.to output(/deprecated/).to_stderr

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file)
    end

    it 'still functions as stop command' do
      File.write(test_pid_file, '99999')
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.send(['--pid-file', test_pid_file, '--message', 'Done'])

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: 'Done',
        checkmark: false,
        error: false
      )
    end
  end
end
