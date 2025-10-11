# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Fill do
  let(:fill) { described_class.new(length: 10, style: :blocks) }

  describe '#initialize' do
    it 'creates a new fill instance' do
      expect(fill).to be_a(RubyProgress::Fill)
    end

    it 'sets default options' do
      default_fill = described_class.new
      expect(default_fill.length).to eq(20)
      expect(default_fill.current_progress).to eq(0)
    end

    it 'allows custom options' do
      custom_fill = described_class.new(length: 15, style: :bars, success: 'Done!')
      expect(custom_fill.length).to eq(15)
      expect(custom_fill.success_message).to eq('Done!')
    end

    it 'parses ends characters' do
      fill_with_ends = described_class.new(ends: '[]')
      expect(fill_with_ends.start_chars).to eq('[')
      expect(fill_with_ends.end_chars).to eq(']')
    end
  end

  describe '#advance' do
    it 'advances progress by one step by default' do
      initial_progress = fill.current_progress
      fill.advance
      expect(fill.current_progress).to eq(initial_progress + 1)
    end

    it 'advances progress by specified increment' do
      fill.advance(increment: 3)
      expect(fill.current_progress).to eq(3)
    end

    it 'sets progress to specific percentage' do
      fill.advance(percent: 50)
      expect(fill.current_progress).to eq(5) # 50% of 10
    end

    it 'does not exceed maximum length' do
      fill.advance(increment: 15) # More than length
      expect(fill.current_progress).to eq(10)
    end

    it 'returns completion status' do
      result = fill.advance(increment: 10)
      expect(result).to be true
    end
  end

  describe '#percent=' do
    it 'sets progress to percentage' do
      fill.percent = 30
      expect(fill.current_progress).to eq(3) # 30% of 10
    end

    it 'clamps percentage between 0 and 100' do
      fill.percent = 150
      expect(fill.current_progress).to eq(10) # 100% of 10

      fill.percent = -10
      expect(fill.current_progress).to eq(0) # 0% of 10
    end

    it 'returns completion status' do
      result = fill.percent = 100
      expect(result).to be_truthy # Returns completion status (boolean)
    end
  end

  describe '#completed?' do
    it 'returns false when not complete' do
      fill.advance(increment: 5)
      expect(fill.completed?).to be false
    end

    it 'returns true when complete' do
      fill.advance(increment: 10)
      expect(fill.completed?).to be true
    end
  end

  describe '#current' do
    it 'returns current progress as float percentage' do
      fill.advance(increment: 3)
      expect(fill.current).to eq(30.0)
    end

    it 'returns 0.0 for empty progress' do
      expect(fill.current).to eq(0.0)
    end

    it 'returns 100.0 for complete progress' do
      fill.advance(increment: 10)
      expect(fill.current).to eq(100.0)
    end
  end

  describe '#percent' do
    it 'returns current progress as percentage' do
      fill.advance(increment: 3)
      expect(fill.percent).to eq(30.0)
    end
  end

  describe '#report' do
    it 'returns detailed progress information' do
      fill.advance(increment: 3)
      report = fill.report

      expect(report[:progress]).to eq([3, 10])
      expect(report[:percent]).to eq(30.0)
      expect(report[:completed]).to be false
      expect(report[:style]).to be_a(Hash)
    end

    it 'shows completed status when done' do
      fill.advance(increment: 10)
      report = fill.report

      expect(report[:completed]).to be true
      expect(report[:percent]).to eq(100.0)
    end
  end

  describe '#render' do
    it 'outputs progress bar to stderr' do
      fill.advance(increment: 3)
      expect { fill.render }.to output(/▰▰▰▱▱▱▱▱▱▱/).to_stderr
    end

    it 'includes start and end characters' do
      fill_with_ends = described_class.new(length: 5, style: :blocks, ends: '[]')
      fill_with_ends.advance(increment: 2)
      expect { fill_with_ends.render }.to output(/\[▰▰▱▱▱\]/).to_stderr
    end
  end

  describe '#complete' do
    it 'sets progress to maximum' do
      fill.complete
      expect(fill.current_progress).to eq(10)
    end

    it 'displays success message' do
      fill.success_message = 'All done!'
      expect { fill.complete }.to output(/All done!/).to_stderr
    end
  end

  describe '#cancel' do
    it 'clears the progress bar' do
      fill.advance(increment: 5)
      expect { fill.cancel }.to output(/\r\e\[2K/).to_stderr
    end

    it 'displays error message' do
      fill.error_message = 'Failed!'
      expect { fill.cancel }.to output(/Failed!/).to_stderr
    end
  end

  describe '.hide_cursor and .show_cursor' do
    it 'outputs cursor control sequences' do
      expect { described_class.hide_cursor }.to output("\e[?25l").to_stderr
      expect { described_class.show_cursor }.to output("\e[?25h").to_stderr
    end
  end

  describe '.progress' do
    it 'runs a block with progress animation' do
      result = described_class.progress(length: 5, style: :dots) do |bar|
        bar.advance(increment: 2)
        'test_result'
      end

      expect(result).to eq('test_result')
    end

    it 'completes progress bar after block' do
      described_class.progress(length: 3, style: :blocks, success: 'Done!') do |bar|
        bar.advance(increment: 1)
      end
      # Should complete and show success message
    end

    it 'handles exceptions gracefully' do
      expect do
        described_class.progress(length: 3) do |_bar|
          raise StandardError, 'Test error'
        end
      end.to raise_error(StandardError, 'Test error')
    end
  end

  describe 'custom styles' do
    it 'parses custom style strings' do
      custom_style = described_class.parse_custom_style('custom=.#')
      expect(custom_style[:empty]).to eq('.')
      expect(custom_style[:full]).to eq('#')
    end

    it 'handles invalid custom styles' do
      result = described_class.parse_custom_style('invalid')
      expect(result).to eq(described_class::FILL_STYLES[:blocks])
    end

    it 'uses custom styles in rendering' do
      custom_fill = described_class.new(length: 5, style: { empty: '.', full: '#' })
      custom_fill.advance(increment: 2)
      expect { custom_fill.render }.to output(/##\.\.\./).to_stderr
    end
  end

  describe 'built-in styles' do
    it 'includes all expected styles' do
      expect(described_class::FILL_STYLES.keys).to include(
        :blocks, :classic, :dots, :squares, :circles, :ascii, :bars, :arrows, :stars
      )
    end

    it 'each style has empty and full characters' do
      described_class::FILL_STYLES.each_value do |style|
        expect(style).to have_key(:empty)
        expect(style).to have_key(:full)
        expect(style[:empty]).to be_a(String)
        expect(style[:full]).to be_a(String)
      end
    end
  end
end
