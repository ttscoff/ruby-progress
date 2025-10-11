# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Worm CLI new features' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe '--direction flag' do
    it 'accepts forward direction' do
      _, _, status = Open3.capture3(
        "echo '' | timeout 1s ruby #{bin_path} worm --direction forward --message 'Forward test'"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts bidirectional direction' do
      _, _, status = Open3.capture3(
        "echo '' | timeout 1s ruby #{bin_path} worm --direction bidirectional --message 'Bidirectional test'"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'accepts abbreviated directions' do
      _, _, status = Open3.capture3(
        "echo '' | timeout 1s ruby #{bin_path} worm --direction f --message 'Forward abbreviated'"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code

      _, _, status = Open3.capture3(
        "echo '' | timeout 1s ruby #{bin_path} worm --direction b --message 'Bidirectional abbreviated'"
      )
      expect(status.exitstatus).to eq(124) # timeout exit code
    end

    it 'combines direction with other options' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --direction forward --style blocks --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'shows direction option in help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} worm --help")
      expect(stdout).to include('--direction')
      expect(stdout).to include('forward')
      expect(stdout).to include('bidirectional')
    end
  end

  describe '--style custom= flag' do
    it 'accepts custom ASCII styles' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style 'custom=_-=' --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'accepts custom emoji styles' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style 'custom=🟦🟨🟥' --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'accepts mixed character styles' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style 'custom=.🟡*' --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'falls back gracefully for invalid custom patterns' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style 'custom=ab' --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0) # Should not crash, just use default
    end

    it 'combines custom style with direction' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style 'custom=abc' --direction forward --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'shows custom style documentation in help' do
      stdout, _stderr, _status = Open3.capture3("ruby #{bin_path} worm --help")
      expect(stdout).to include('custom=')
      expect(stdout).to include('custom=abc') # Shows example format
    end
  end

  describe 'combined new features' do
    it 'works with both direction and custom style' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --direction forward --style 'custom=🔴🟡🟢' " \
        "--message 'Custom forward animation' --command 'sleep 0.1'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'shows worm styles in show-styles output' do
      stdout_stderr, status = Open3.capture2e("ruby #{bin_path} worm --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout_stderr).to include('== worm styles')
      expect(stdout_stderr).to include('circles')
      # NOTE: custom= is not shown as it's user-generated, and direction is a behavior modifier
    end
  end

  describe 'backward compatibility' do
    it 'still works with existing style names' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style circles --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end

    it 'defaults to bidirectional when no direction specified' do
      _, _, status = Open3.capture3(
        "ruby #{bin_path} worm --style blocks --command 'echo test'"
      )
      expect(status.exitstatus).to eq(0)
    end
  end
end
