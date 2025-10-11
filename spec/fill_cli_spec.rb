# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'Fill CLI Integration' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  describe 'fill subcommand' do
    it 'shows help' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --help")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Usage: prg fill [options]')
      expect(stdout).to include('Progress Bar Options:')
      expect(stdout).to include('Progress Control:')
      expect(stdout).to include('--current')
      expect(stdout).to include('--report')
    end

    it 'shows version' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --version")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Fill version 1.0.0')
    end

    it 'shows available fill styles' do
      stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --show-styles")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include('Available Fill Styles:')
      expect(stdout).to include('blocks')
      expect(stdout).to include('classic')
      expect(stdout).to include('dots')
      expect(stdout).to include('Custom Style:')
    end

    it 'runs auto-advance mode by default' do
      _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --length 5 --speed fast --style ascii")
      expect(status.exitstatus).to eq(0)
      # Should complete quickly and show checkmark
    end

    it 'accepts percentage setting' do
      _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --percent 75 --length 8 --style blocks")
      expect(status.exitstatus).to eq(0)
      # Should set to 75% and complete
    end

    it 'accepts custom styles' do
      _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --style custom=.# --length 6 --percent 50")
      expect(status.exitstatus).to eq(0)
      # Should use custom dots and hashes
    end

    it 'accepts custom ends' do
      _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --ends '[]' --length 4 --percent 25")
      expect(status.exitstatus).to eq(0)
      # Should show progress bar with brackets
    end

    it 'shows success message' do
      _stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --length 3 --success 'All done!' --speed fast")
      expect(status.exitstatus).to eq(0)
      expect(stderr).to include('All done!')
    end

    describe '--current flag' do
      it 'returns current percentage as float' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --current --percent 75")
        expect(status.exitstatus).to eq(0)
        expect(stdout.strip).to eq('75.0')
      end

      it 'returns default 50% when no percent specified' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --current")
        expect(status.exitstatus).to eq(0)
        expect(stdout.strip).to eq('50.0')
      end

      it 'works with custom percentage values' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --current --percent 42.8")
        expect(status.exitstatus).to eq(0)
        expect(stdout.strip).to eq('42.8')
      end

      it 'outputs only to stdout for scripting' do
        stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --current --percent 33")
        expect(status.exitstatus).to eq(0)
        expect(stdout.strip).to eq('33.0')
        expect(stderr).to be_empty
      end
    end

    describe '--report flag' do
      it 'shows detailed progress report' do
        stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --report --percent 60 --length 10 --style bars")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('Progress Report:')
        expect(stdout).to include('Progress: 6/10')
        expect(stdout).to include('Percent: 60.0%')
        expect(stdout).to include('Completed: No')
        expect(stdout).to include('Style:')
      end

      it 'shows completed status when at 100%' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --report --percent 100 --length 5")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('Completed: Yes')
      end

      it 'works with custom styles' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --report --percent 40 --style custom=oO")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('Style: {empty: "o", full: "O"}')
      end

      it 'includes visual progress bar' do
        _stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --report --percent 25 --style dots --length 8")
        expect(status.exitstatus).to eq(0)
        # Should show visual progress bar with dots
        expect(stderr).to match(/●●····/)
      end
    end

    describe 'error handling' do
      it 'handles invalid options gracefully' do
        _stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --invalid-option")
        expect(status.exitstatus).to eq(1)
        expect(stderr).to include('Invalid option: --invalid-option')
        expect(stderr).to include('Usage: prg fill [options]')
      end

      it 'shows error for unimplemented progress commands' do
        _stdout, stderr, status = Open3.capture3("ruby #{bin_path} fill --advance")
        expect(status.exitstatus).to eq(1)
        expect(stderr).to include('Progress commands require daemon mode implementation')
      end
    end

    describe 'speed options' do
      it 'accepts fast speed' do
        _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --speed fast --length 3")
        expect(status.exitstatus).to eq(0)
      end

      it 'accepts medium speed' do
        _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --speed medium --length 3")
        expect(status.exitstatus).to eq(0)
      end

      it 'accepts slow speed' do
        _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --speed slow --length 3")
        expect(status.exitstatus).to eq(0)
      end

      it 'accepts numeric speed' do
        _stdout, _stderr, status = Open3.capture3("ruby #{bin_path} fill --speed 5 --length 3")
        expect(status.exitstatus).to eq(0)
      end
    end

    describe 'integration with main command' do
      it 'appears in main help' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} --help")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('fill      Determinate progress bar with customizable fill styles')
      end

      it 'appears in version output' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} --version")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('fill   - Determinate progress bar with customizable styles (v1.0.0)')
      end

      it 'appears in style listings' do
        stdout, _stderr, status = Open3.capture3("ruby #{bin_path} --show-styles")
        expect(status.exitstatus).to eq(0)
        expect(stdout).to include('== fill ==')
      end
    end
  end
end
