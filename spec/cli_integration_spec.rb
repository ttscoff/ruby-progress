# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'CLI Integration' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe 'main command' do
    it 'shows help when no arguments provided' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path}")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('prg - Unified Ruby Progress Indicators')
    end

    it 'shows version information' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} --version")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('prg version')
    end

    it 'shows available styles' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} --list-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('== ripple')
      expect(stdout).to include('== worm')
      expect(stdout).to include('== twirl')
    end
  end

  describe 'ripple subcommand' do
    it 'shows help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} ripple --help")
      expect(stdout).to include('Usage: prg ripple')
    end

    it 'runs with basic text' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} ripple 'Test'")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts speed option' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} ripple 'Test' --speed fast")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts style options' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} ripple 'Test' --style rainbow")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end
  end

  describe 'worm subcommand' do
    it 'shows help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} worm --help")
      expect(stdout).to include('Usage: prg worm')
    end

    it 'runs without message (no default text)' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} worm")
      expect(status.exitstatus).to eq(124) # timeout exit code
      # Should not contain "Processing" since we fixed that
      expect(stdout).not_to include('Processing')
    end

    it 'accepts message option' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} worm --message 'Working'")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts style options' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} worm --style blocks")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'executes commands' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} worm --command 'echo test'")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe 'twirl subcommand' do
    it 'shows help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} twirl --help")
      expect(stdout).to include('Usage: prg twirl')
    end

    it 'runs without message (no default text)' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} twirl")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts spinner style options' do
      stdout, stderr, status = Open3.capture3("echo '' | timeout 1s ruby #{bin_path} twirl --style dots")
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'executes commands' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} twirl --command 'echo test'")
      expect(status.exitstatus).to eq(0)
    end
  end

  describe 'error handling' do
    it 'handles invalid subcommands' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} invalid")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include("Unknown subcommand 'invalid'")
      expect(stdout).to include('Run \'prg --help\' for usage information')
    end

    it 'handles invalid options gracefully' do
      _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} worm --invalid-option 2>&1")
      expect(status.exitstatus).not_to eq(0)
    end
  end
end