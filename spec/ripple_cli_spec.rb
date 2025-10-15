# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Ripple CLI' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe 'help and version' do
    it 'shows help message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple --help")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Usage: prg ripple')
      expect(stdout).to include('Animation Options:')
    end

    it 'shows version' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple --version")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Ripple version')
      expect(stdout).to match(/\d+\.\d+\.\d+/)
    end

    it 'shows available styles' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('== ripple styles')
    end
  end

  describe 'basic animation' do
    it 'requires text argument' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Error: Please provide text')
    end

    it 'runs with text argument' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Loading'")
      expect(status.exitstatus).to eq(124) # timeout
    end

    it 'runs with message flag' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple --message 'Testing'")
      expect(status.exitstatus).to eq(124)
    end

    it 'runs with different speeds' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --speed fast")
      expect(status.exitstatus).to eq(124)

      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --speed 7")
      expect(status.exitstatus).to eq(124)
    end

    it 'runs with style options' do
      %w[rainbow inverse caps].each do |style|
        _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --style #{style}")
        expect(status.exitstatus).to eq(124)
      end
    end

    it 'runs with multiple styles' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --style rainbow --style caps")
      expect(status.exitstatus).to eq(124)
    end

    it 'accepts ends parameter' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --ends '[]'")
      expect(status.exitstatus).to eq(124)
    end
  end

  describe 'command execution' do
    it 'executes commands successfully' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'echo success' --stdout")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('success')
    end

    it 'handles command failures' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'exit 1' --success 'OK' --error 'Failed' --stdout")
      expect(status.exitstatus).to eq(1)
      expect(stderr).to include('Failed')
    end

    it 'shows checkmarks' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'echo ok' --checkmark --stdout")
      expect(status.exitstatus).to eq(0)
      expect(stderr).to match(/✅/)
    end

    it 'outputs to stdout when requested' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'echo stdout' --stdout")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('stdout')
    end
  end

  describe 'error handling' do
    it 'handles odd-length ends parameter' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Test' --ends 'abc' 2>&1")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid --ends value')
    end

    it 'handles invalid speed gracefully' do
      _stdout, _stderr, status = run_with_timeout("echo '' | ruby #{bin_path} ripple 'Test' --speed invalid 2>/dev/null")
      # Should still run with default speed
      expect(status.exitstatus).to eq(124)
    end
  end

  describe 'advanced features' do
    it 'combines multiple options' do
      stdout, _stderr, status = Open3.capture3(
        "ruby #{bin_path} ripple 'Combined' --command 'echo test' --style rainbow --speed fast --checkmark --stdout"
      )
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('test')
    end

    it 'works with custom icons' do
      stdout, stderr, status = Open3.capture3(
        "ruby #{bin_path} ripple 'Test' --command 'echo x' --success-icon '🎉' --success 'Yay' --stdout"
      )
      expect(status.exitstatus).to eq(0)
      expect(stderr).to include('🎉')
    end
  end
end
