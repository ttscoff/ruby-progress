# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Daemon do
  let(:test_pid_file) { '/tmp/test_daemon.pid' }
  let(:test_control_file) { '/tmp/test_daemon.pid.msg' }

  before do
    # Clean up any existing test files
    FileUtils.rm_f(test_pid_file)
    FileUtils.rm_f(test_control_file)
  end

  after do
    # Clean up test files
    FileUtils.rm_f(test_pid_file)
    FileUtils.rm_f(test_control_file)
  end

  describe '.default_pid_file' do
    it 'returns a default path in tmp directory' do
      expect(described_class.default_pid_file).to include('/tmp/')
      expect(described_class.default_pid_file).to end_with('.pid')
    end
  end

  describe '.control_message_file' do
    it 'returns control file path based on pid file' do
      control_file = described_class.control_message_file(test_pid_file)
      expect(control_file).to eq('/tmp/test_daemon.pid.msg')
    end
  end

  describe '.show_status' do
    context 'when PID file does not exist' do
      it 'shows daemon not running message' do
        expect { described_class.show_status(test_pid_file) }
          .to output("Daemon not running\n").to_stdout
      end
    end

    context 'when PID file exists with valid PID' do
      it 'shows daemon running status' do
        # Use current process PID for testing
        File.write(test_pid_file, Process.pid.to_s)

        expect { described_class.show_status(test_pid_file) }
          .to output("Daemon running (pid #{Process.pid})\n").to_stdout
      end
    end

    context 'when PID file exists with invalid PID' do
      it 'shows PID file not found message' do
        File.write(test_pid_file, '999999')

        expect { described_class.show_status(test_pid_file) }
          .to output("PID file #{test_pid_file} not found\n").to_stdout
      end
    end
  end

  describe '.stop_daemon_by_pid_file' do
    context 'when PID file does not exist' do
      it 'shows PID file not found message and exits with status 1' do
        expect { described_class.stop_daemon_by_pid_file(test_pid_file) }
          .to output("PID file #{test_pid_file} not found\n").to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'when process does not exist' do
      it 'shows process not found message and exits with status 1' do
        File.write(test_pid_file, '999999')

        expect { described_class.stop_daemon_by_pid_file(test_pid_file) }
          .to output("Process 999999 not found (may have already stopped)\n").to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'with success message' do
      it 'writes control message file before stopping' do
        File.write(test_pid_file, '999999')

        expect do
          described_class.stop_daemon_by_pid_file(test_pid_file, message: 'Success!', checkmark: true)
        rescue SystemExit
          # Expected to exit
        end

        expect(File.exist?(test_control_file)).to be true
        control_data = JSON.parse(File.read(test_control_file))
        expect(control_data['message']).to eq('Success!')
        expect(control_data['checkmark']).to be true
        expect(control_data['success']).to be true
      end
    end

    context 'with error message' do
      it 'writes control message file with error flag' do
        File.write(test_pid_file, '999999')

        expect do
          described_class.stop_daemon_by_pid_file(test_pid_file, message: 'Error!', error: true)
        rescue SystemExit
          # Expected to exit
        end

        expect(File.exist?(test_control_file)).to be true
        control_data = JSON.parse(File.read(test_control_file))
        expect(control_data['message']).to eq('Error!')
        expect(control_data['success']).to be false
      end
    end
  end
end
