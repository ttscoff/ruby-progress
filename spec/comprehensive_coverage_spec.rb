# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comprehensive Coverage Tests' do
  describe 'Worm class uncovered paths' do
    let(:worm) { RubyProgress::Worm.new(message: 'Testing') }

    it 'covers error handling in animate' do
      worm = RubyProgress::Worm.new(message: 'Test', success: 'Done!', error: 'Failed!')

      # Test the error path by raising an exception in the block
      result = worm.animate do
        raise StandardError, 'Test error'
      end

      expect(result).to be_nil
    end

    it 'covers success path in animate' do
      worm = RubyProgress::Worm.new(message: 'Test', success: 'Success!')

      result = worm.animate do
        'test_result'
      end

      expect(result).to eq('test_result')
    end

    it 'covers animation_loop_daemon_mode method' do
      worm = RubyProgress::Worm.new(message: 'Daemon test')

      # Create a stop proc that will terminate the loop
      stop_proc = proc { true }

      # Mock the file operations and sleep
      allow(File).to receive(:exist?).and_return(false)
      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)

      # This should run once and exit due to stop_proc
      expect { worm.send(:animation_loop_daemon_mode, stop_requested_proc: stop_proc) }.not_to raise_error
    end

    it 'covers daemon mode method' do
      worm = RubyProgress::Worm.new(message: 'Daemon test')

      stop_proc = proc { true }

      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)

      worm.send(:animation_loop_daemon_mode, stop_requested_proc: stop_proc)
    end

    it 'covers signal trap setup in animate' do
      worm = RubyProgress::Worm.new(message: 'Signal test')

      expect(Signal).to receive(:trap).with('INT').and_return(nil)
      allow(Signal).to receive(:trap).with('INT', anything)
      allow(Thread).to receive(:new).and_return(double('thread', join: nil))

      worm.animate { 'test' }
    end
  end

  describe 'Utils module uncovered methods' do
    it 'covers clear_line_aggressive method' do
      expect($stderr).to receive(:print).with("\r\e[2K")
      expect($stderr).to receive(:print).with("\e[1A\e[2K")
      expect($stderr).to receive(:print).with("\r")

      RubyProgress::Utils.clear_line_aggressive
    end

    it 'covers complete_with_clear with warn stream' do
      # This should NOT call clear_line since warn stream already includes clear
      expect(RubyProgress::Utils).not_to receive(:clear_line)
      expect { RubyProgress::Utils.complete_with_clear('Test', output_stream: :warn) }
        .to output("\e[2KTest\n").to_stderr
    end

    it 'covers complete_with_clear with non-warn streams' do
      expect(RubyProgress::Utils).to receive(:clear_line).with(:stdout)
      expect { RubyProgress::Utils.complete_with_clear('Test', output_stream: :stdout) }
        .to output("Test\n").to_stdout
    end
  end

  describe 'Daemon module edge cases' do
    let(:test_pid_file) { '/tmp/test_coverage_daemon.pid' }
    let(:test_control_file) { '/tmp/test_coverage_daemon.pid.msg' }

    before do
      FileUtils.rm_f(test_pid_file)
      FileUtils.rm_f(test_control_file)
    end

    after do
      FileUtils.rm_f(test_pid_file)
      FileUtils.rm_f(test_control_file)
    end

    it 'covers permission denied error in stop_daemon_by_pid_file' do
      File.write(test_pid_file, '1') # Use PID 1 which we can't kill

      expect { RubyProgress::Daemon.stop_daemon_by_pid_file(test_pid_file) }
        .to output("Permission denied sending signal to process 1\n").to_stdout
        .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end
  end

  describe 'Ripple class uncovered methods' do
    it 'covers self.complete class method' do
      expect { RubyProgress::Ripple.complete('Test', 'Done!', true, true) }
        .to output("\e[2K✅ Done!\n").to_stderr
    end

    it 'covers self.complete with failure' do
      expect { RubyProgress::Ripple.complete('Test', 'Failed!', true, false) }
        .to output("\e[2K🛑 Failed!\n").to_stderr
    end

    it 'covers advance method with different directions' do
      ripple = RubyProgress::Ripple.new('Test', format: :forward_only)

      # Mock stdout to capture output
      allow($stdout).to receive(:print)
      allow($stdout).to receive(:flush)
      allow(ripple).to receive(:sleep)

      expect { ripple.advance }.not_to raise_error
    end

    it 'covers ripple with caps and inverse options' do
      ripple = RubyProgress::Ripple.new('test', caps: true, inverse: true)

      allow($stdout).to receive(:print)
      allow($stdout).to receive(:flush)
      allow(ripple).to receive(:sleep)

      expect { ripple.advance }.not_to raise_error
    end
  end
end
