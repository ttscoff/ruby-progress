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
      expect(stdout).to include('ripple - Text ripple animation with color effects (v')
      expect(stdout).to include('worm   - Unicode wave animation with customizable styles (v')
      expect(stdout).to include('twirl  - Spinner animation with various indicator styles (v')
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

    it 'handles invalid ripple options with specific error message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple --invalid-flag 2>&1")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid option: --invalid-flag')
      expect(stdout).to include('Usage: prg ripple [options]')
      expect(stdout).to include("Run 'prg ripple --help' for more information")
    end

    it 'handles invalid worm options with specific error message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} worm --invalid-flag 2>&1")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid option: --invalid-flag')
      expect(stdout).to include('Usage: prg worm [options]')
      expect(stdout).to include("Run 'prg worm --help' for more information")
    end

    it 'handles invalid twirl options with specific error message' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} twirl --invalid-flag 2>&1")
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid option: --invalid-flag')
      expect(stdout).to include('Usage: prg twirl [options]')
      expect(stdout).to include("Run 'prg twirl --help' for more information")
    end
  end

  describe 'stop-all functionality' do
    it 'exits silently with code 1 when no processes to stop globally' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} --stop-all")
      expect(stdout).to be_empty
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(1)
    end

    it 'exits silently with code 1 when no ripple processes to stop' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} ripple --stop-all")
      expect(stdout).to be_empty
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(1)
    end

    it 'exits silently with code 1 when no worm processes to stop' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} worm --stop-all")
      expect(stdout).to be_empty
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(1)
    end

    it 'exits silently with code 1 when no twirl processes to stop' do
      stdout, stderr, status = Open3.capture3("ruby #{bin_path} twirl --stop-all")
      expect(stdout).to be_empty
      expect(stderr).to be_empty
      expect(status.exitstatus).to eq(1)
    end
  end

  describe 'show-styles functionality' do
    it 'shows global styles with --show-styles' do
      stdout_stderr, status = Open3.capture2e("ruby #{bin_path} --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout_stderr).to include('== ripple styles')
      expect(stdout_stderr).to include('== worm styles')
      expect(stdout_stderr).to include('== twirl styles')
    end

    it 'shows ripple-specific styles' do
      stdout_stderr, status = Open3.capture2e("ruby #{bin_path} ripple --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout_stderr).to include('== ripple styles')
      expect(stdout_stderr).not_to include('== worm styles')
      expect(stdout_stderr).not_to include('== twirl styles')
    end

    it 'shows worm-specific styles' do
      stdout_stderr, status = Open3.capture2e("ruby #{bin_path} worm --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout_stderr).to include('== worm styles')
      expect(stdout_stderr).not_to include('== ripple styles')
      expect(stdout_stderr).not_to include('== twirl styles')
    end

    it 'shows twirl-specific styles' do
      stdout_stderr, status = Open3.capture2e("ruby #{bin_path} twirl --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout_stderr).to include('== twirl styles')
      expect(stdout_stderr).not_to include('== ripple styles')
      expect(stdout_stderr).not_to include('== worm styles')
    end
  end
end
