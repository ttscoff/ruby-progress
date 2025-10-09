# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Ripple, 'integration tests' do
  let(:ripple) { described_class.new('Hello World', speed: :fast, rainbow: true) }

  describe '#printout' do
    it 'prints animation frames to stderr with ANSI codes' do
      rainbow_ripple = described_class.new('Test', rainbow: true)
      expect { rainbow_ripple.send(:printout) }.to output(/\e\[2K.*T.*e.*st.*\r/).to_stderr
    end

    it 'prints without rainbow when disabled' do
      plain_ripple = described_class.new('Test', rainbow: false)
      expect { plain_ripple.send(:printout) }.to output(/\e\[2K.*T.*e.*st.*\r/).to_stderr
    end

    it 'handles caps transformation' do
      caps_ripple = described_class.new('test', caps: true)
      expect { caps_ripple.send(:printout) }.to output(/\e\[2K.*TE.*\r/).to_stderr
    end

    it 'handles inverse highlighting' do
      inverse_ripple = described_class.new('Test', inverse: true)
      expect { inverse_ripple.send(:printout) }.not_to raise_error
    end
  end

  describe 'String extensions' do
    it 'has rainbow method on strings' do
      test_string = 'Hello'
      expect(test_string.respond_to?(:rainbow)).to be true
    end

    it 'rainbow method returns colored string' do
      test_string = 'Hello'
      result = test_string.rainbow
      expect(result).to include("\e[")
      # Rainbow method splits each character and adds colors, so "Hello" becomes separate colored chars
      expect(result).to include('H')
      expect(result).to include('e')
    end

    it 'normalize_type works on strings' do
      test_string = 'dots'
      result = test_string.normalize_type
      expect(result).to be_a(Symbol)
    end
  end

  describe 'option handling' do
    it 'properly initializes with all options' do
      full_ripple = described_class.new('test', {
                                          speed: :slow,
                                          format: :forward,
                                          rainbow: true,
                                          inverse: true,
                                          caps: true,
                                          spinner: :dots
                                        })
      expect(full_ripple.instance_variable_get(:@options)[:speed]).to eq(:slow)
      expect(full_ripple.instance_variable_get(:@options)[:rainbow]).to be true
      expect(full_ripple.instance_variable_get(:@caps)).to be true
      expect(full_ripple.instance_variable_get(:@inverse)).to be true
    end

    it 'handles spinner option' do
      spinner_ripple = described_class.new('Test', spinner: :dots)
      expect(spinner_ripple.instance_variable_get(:@spinner)).to eq(:dots)
    end

    it 'handles format option properly' do
      forward_ripple = described_class.new('Test', format: :forward_only)
      expect(forward_ripple.instance_variable_get(:@options)[:format]).to eq(:forward_only)
    end
  end

  describe 'animation behavior' do
    it 'handles non-empty strings without errors' do
      short_ripple = described_class.new('AB', speed: :fast)
      expect { short_ripple.advance }.not_to raise_error
    end

    it 'handles normal strings gracefully' do
      normal_ripple = described_class.new('Test', speed: :fast)
      expect { normal_ripple.advance }.not_to raise_error
    end

    it 'handles very long strings' do
      long_text = 'A' * 100
      long_ripple = described_class.new(long_text, speed: :fast)
      expect { long_ripple.advance }.not_to raise_error
    end

    it 'changes direction at string boundaries in bidirectional mode' do
      ripple = described_class.new('Test', format: :bidirectional)
      # Start at index 0, advance to end (should be index 3 for "Test")
      initial_direction = ripple.instance_variable_get(:@direction)
      expect(initial_direction).to eq(:forward)
      
      # Advance to the end
      4.times { ripple.advance }
      
      # Should have changed direction by now
      final_direction = ripple.instance_variable_get(:@direction)
      expect(final_direction).to eq(:backward)
    end

    it 'resets to beginning in forward_only mode' do
      ripple = described_class.new('Test', format: :forward_only)
      # Advance beyond the end
      6.times { ripple.advance }
      # Should reset to beginning, not change direction
      expect(ripple.instance_variable_get(:@direction)).to eq(:forward)
    end
  end

  describe '.progress with different options' do
    it 'works with success callback' do
      result = described_class.progress('Test', success: 'Done!') { 'result' }
      expect(result).to be_nil
    end

    it 'works with error callback' do
      result = described_class.progress('Test', error: 'Failed!') do
        raise StandardError, 'test'
      end
      expect(result).to be_nil
    end

    it 'works with checkmark option' do
      result = described_class.progress('Test', checkmark: true) { 'result' }
      expect(result).to be_nil
    end

    it 'captures block return value but returns nil for stderr mode' do
      result = described_class.progress('Test') { 'block_result' }
      expect(result).to be_nil
    end
  end
end