# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Ripple do
  let(:ripple) { described_class.new('Testing', speed: :fast) }

  describe '#initialize' do
    it 'creates a new ripple instance' do
      expect(ripple).to be_a(RubyProgress::Ripple)
    end

    it 'sets default options' do
      default_ripple = described_class.new('Test')
      expect(default_ripple.instance_variable_get(:@options)[:speed]).to eq(:medium)
    end

    it 'allows custom options' do
      custom_ripple = described_class.new('Test', speed: :slow, rainbow: true)
      expect(custom_ripple.instance_variable_get(:@options)[:speed]).to eq(:slow)
      expect(custom_ripple.instance_variable_get(:@options)[:rainbow]).to be true
    end
  end

  describe '#advance' do
    it 'advances the animation index' do
      initial_index = ripple.index
      ripple.advance
      expect(ripple.index).to be > initial_index
    end

    it 'respects direction changes' do
      # Advance to end to trigger direction change
      string_length = ripple.string.length - 1
      ripple.instance_variable_set(:@index, string_length)
      ripple.advance
      expect(ripple.instance_variable_get(:@direction)).to eq(:backward)
    end
  end

  describe '.hide_cursor and .show_cursor' do
    it 'outputs cursor control sequences' do
      expect { described_class.hide_cursor }.to output("\e[?25l").to_stderr
      expect { described_class.show_cursor }.to output("\e[?25h").to_stderr
    end
  end

  describe '.complete' do
    it 'displays completion message without checkmark' do
      expect { described_class.complete('Test', 'Done', false, true) }
        .to output("\e[2KDone\n").to_stderr
    end

    it 'displays completion message with success checkmark' do
      expect { described_class.complete('Test', 'Done', true, true) }
        .to output("\e[2K✅ Done\n").to_stderr
    end

    it 'displays completion message with failure checkmark' do
      expect { described_class.complete('Test', 'Failed', true, false) }
        .to output("\e[2K🛑 Failed\n").to_stderr
    end
  end

  describe '.progress' do
    it 'runs a block with progress animation' do
      result = described_class.progress('Test') { 'completed' }
      expect(result).to be_nil # Returns nil for error output mode
    end

    it 'handles exceptions gracefully' do
      result = described_class.progress('Test') { raise StandardError, 'test error' }
      expect(result).to be_nil
    end
  end
end
