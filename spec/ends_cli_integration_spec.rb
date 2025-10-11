# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'CLI --ends flag integration' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe 'ripple --ends' do
    it 'accepts basic bracket ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} ripple 'Test' --ends '[]' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts complex ends patterns' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} ripple 'Test' --ends '<<>>' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'handles emoji ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} ripple 'Test' --ends '🎯🎪' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'works with other ripple options' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} ripple 'Test' --ends '()' --style rainbow --speed fast 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end
  end

  describe 'worm --ends' do
    it 'accepts basic bracket ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} worm --message 'Test' --ends '[]' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts parentheses ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} worm --message 'Test' --ends '()' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'handles emoji ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} worm --message 'Test' --ends '🔥💯' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'works with other worm options' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} worm --message 'Test' --ends '{}' --style blocks --direction forward 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'works with custom styles' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} worm --message 'Test' --ends '||' --style 'custom=abc' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end
  end

  describe 'twirl --ends' do
    it 'accepts basic bracket ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} twirl --message 'Test' --ends '[]' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts angle bracket ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} twirl --message 'Test' --ends '<<>>' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'handles emoji ends' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} twirl --message 'Test' --ends '🚀⭐' 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'works with other twirl options' do
      _stdout, _stderr, status = Open3.capture3(
        "timeout 1s ruby #{bin_path} twirl --message 'Test' --ends '{}' --style dots --speed fast 2>/dev/null"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end
  end

  describe 'error handling' do
    it 'handles odd-length ends gracefully for ripple' do
      stdout, _, status = Open3.capture3(
        "ruby #{bin_path} ripple 'Test' --ends 'abc'"
      )
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid --ends value')
    end

    it 'handles odd-length ends gracefully for worm' do
      stdout, _, status = Open3.capture3(
        "ruby #{bin_path} worm --message 'Test' --ends 'abc'"
      )
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid --ends value')
    end

    it 'handles odd-length ends gracefully for twirl' do
      stdout, _, status = Open3.capture3(
        "ruby #{bin_path} twirl --message 'Test' --ends 'abc'"
      )
      expect(status.exitstatus).to eq(1)
      expect(stdout).to include('Invalid --ends value')
    end
  end

  describe 'help documentation' do
    it 'shows --ends option in ripple help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} ripple --help")
      expect(stdout).to include('--ends')
      expect(stdout).to include('Start/end characters')
    end

    it 'shows --ends option in worm help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} worm --help")
      expect(stdout).to include('--ends')
      expect(stdout).to include('Start/end characters')
    end

    it 'shows --ends option in twirl help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} twirl --help")
      expect(stdout).to include('--ends')
      expect(stdout).to include('Start/end characters')
    end

    it 'mentions --ends in main help as common option' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} --help")
      expect(stdout).to include('COMMON OPTIONS')
      expect(stdout).to include('--ends CHARS')
    end
  end
end
