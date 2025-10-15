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

  describe 'JobCLI::Options' do
    it 'parses pid-file option' do
      options = JobCLI::Options.parse(['--pid-file', '/tmp/test.pid'])
      expect(options[:pid_file]).to eq('/tmp/test.pid')
    end

    it 'parses daemon-name option' do
      options = JobCLI::Options.parse(['--daemon-name', 'mytask'])
      expect(options[:daemon_name]).to eq('mytask')
    end

    it 'parses message option' do
      options = JobCLI::Options.parse(['--message', 'Done!'])
      expect(options[:message]).to eq('Done!')
    end

    it 'parses checkmark flag' do
      options = JobCLI::Options.parse(['--checkmark'])
      expect(options[:checkmark]).to be true
    end

    it 'parses error flag' do
      options = JobCLI::Options.parse(['--error'])
      expect(options[:error]).to be true
    end

    it 'parses multiple options together' do
      options = JobCLI::Options.parse([
                                        '--daemon-name', 'task1',
                                        '--message', 'Complete',
                                        '--checkmark'
                                      ])
      expect(options[:daemon_name]).to eq('task1')
      expect(options[:message]).to eq('Complete')
      expect(options[:checkmark]).to be true
    end
  end

  describe 'JobCLI.send' do
    it 'exits with error when pid file does not exist' do
      expect do
        JobCLI.send(['--pid-file', '/tmp/nonexistent.pid'])
      end.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'sends stop signal when pid file exists' do
      # Create a mock pid file
      File.write(test_pid_file, '99999')

      # Mock the Daemon module to avoid actually killing processes
      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      expect do
        JobCLI.send(['--pid-file', test_pid_file])
      end.to output(/Stop signal sent/).to_stdout

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: nil,
        checkmark: false,
        error: false
      )
    end

    it 'sends stop signal with message' do
      File.write(test_pid_file, '99999')

      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      expect do
        JobCLI.send(['--pid-file', test_pid_file, '--message', 'Finished!'])
      end.to output(/Stop signal sent/).to_stdout

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: 'Finished!',
        checkmark: false,
        error: false
      )
    end

    it 'sends stop signal with checkmark' do
      File.write(test_pid_file, '99999')

      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      expect do
        JobCLI.send(['--pid-file', test_pid_file, '--checkmark'])
      end.to output(/Stop signal sent/).to_stdout

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        test_pid_file,
        message: nil,
        checkmark: true,
        error: false
      )
    end

    it 'sends stop signal with error flag' do
      File.write(test_pid_file, '99999')

      allow(RubyProgress::Daemon).to receive(:stop_daemon_by_pid_file)

      JobCLI.send(['--pid-file', test_pid_file, '--error'])

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

      expect do
        JobCLI.send(['--daemon-name', 'mytask'])
      end.to output(/Stop signal sent.*mytask/).to_stdout

      expect(RubyProgress::Daemon).to have_received(:stop_daemon_by_pid_file).with(
        daemon_pid_file,
        message: nil,
        checkmark: false,
        error: false
      )

      FileUtils.rm_f(daemon_pid_file)
    end
  end
end
