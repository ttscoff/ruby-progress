# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Twirl CLI' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe 'help and version' do
    it 'shows help message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --help")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Usage: prg twirl')
      expect(stdout).to include('Animation Options:')
      expect(stdout).to include('--speed')
      expect(stdout).to include('--message')
      expect(stdout).to include('--style')
    end

    it 'shows version' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --version")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Twirl version')
      expect(stdout).to match(/\d+\.\d+\.\d+/)
    end

    it 'shows available styles' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Available twirl spinner styles:')
    end
  end

  describe 'basic animation' do
    it 'runs with default settings' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl")
      expect(status.exitstatus).to eq(124) # timeout (animation runs indefinitely)
    end

    it 'runs with custom message' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --message 'Loading'")
      expect(status.exitstatus).to eq(124)
    end

    it 'runs with different speeds' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --speed fast")
      expect(status.exitstatus).to eq(124)

      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --speed 5")
      expect(status.exitstatus).to eq(124)
    end

    it 'runs with different spinner styles' do
      %w[dots line arc arrow].each do |style|
        _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --style #{style}")
        expect(status.exitstatus).to eq(124)
      end
    end

    it 'accepts direction option for API compatibility' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --direction forward")
      expect(status.exitstatus).to eq(124)
    end

    it 'accepts ends option' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --ends '[]'")
      expect(status.exitstatus).to eq(124)
    end
  end

  describe 'command execution' do
    it 'executes a simple command successfully' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo hello'")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('hello')
    end

    it 'executes command with success message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo test' --success 'Done!'")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Done!')
    end

    it 'handles command failures with error message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'exit 1' --error 'Failed!'")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Failed!')
    end

    it 'shows checkmarks when requested' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo ok' --checkmark")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to match(/✅|success/)
    end

    it 'captures and displays command output' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo output_test'")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('output_test')
    end

    it 'uses custom success icon' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo x' --success-icon '🎉' --success 'Yay'")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('🎉')
    end

    it 'uses custom error icon' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'exit 1' --error-icon '💥' --error 'Oops'")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('💥')
    end
  end

  describe 'output control' do
    it 'outputs to stdout when requested' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo stdout_test' --stdout")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('stdout_test')
    end

    it 'accepts output position option' do
      _, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo test' --output-position below")
      expect(status.exitstatus).to eq(0)
    end

    it 'accepts output lines option' do
      _, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo test' --output-lines 5")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe 'error handling' do
    it 'handles invalid style gracefully' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --style nonexistent 2>/dev/null")
      # Should still run (falls back to default)
      expect(status.exitstatus).to eq(124)
    end

    it 'handles invalid speed gracefully' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --speed invalid 2>/dev/null")
      # Should still run (falls back to default)
      expect(status.exitstatus).to eq(124)
    end

    it 'handles odd-length ends parameter' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --ends 'abc' 2>&1")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid --ends value')
    end
  end

  describe 'advanced options combinations' do
    it 'combines multiple options' do
      stdout, _stderr, status = Open3.capture3(
        "ruby #{bin_path} twirl --command 'echo combined' --message 'Testing' --style dots --speed fast --checkmark"
      )
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('combined')
    end

    it 'works with ends and style together' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} twirl --ends '()' --style arc")
      expect(status.exitstatus).to eq(124)
    end
  end
end
