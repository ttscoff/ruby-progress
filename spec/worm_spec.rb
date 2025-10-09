# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Worm do
  let(:worm) { described_class.new(length: 3, message: 'Testing') }

  describe '#initialize' do
    it 'creates a new worm instance' do
      expect(worm).to be_a(RubyProgress::Worm)
    end

    it 'sets default options' do
      default_worm = described_class.new
      expect(default_worm.instance_variable_get(:@length)).to eq(3)
      expect(default_worm.instance_variable_get(:@message)).to be_nil
    end

    it 'allows custom options' do
      custom_worm = described_class.new(length: 5, message: 'Custom', speed: 'fast')
      expect(custom_worm.instance_variable_get(:@length)).to eq(5)
      expect(custom_worm.instance_variable_get(:@message)).to eq('Custom')
    end
  end

  describe '#parse_speed' do
    it 'handles string speeds' do
      expect(worm.send(:parse_speed, 'fast')).to eq(0.1)
      expect(worm.send(:parse_speed, 'medium')).to eq(0.2)
      expect(worm.send(:parse_speed, 'slow')).to eq(0.5)
    end

    it 'handles abbreviated speeds' do
      expect(worm.send(:parse_speed, 'f')).to eq(0.1)
      expect(worm.send(:parse_speed, 'm')).to eq(0.2)
      expect(worm.send(:parse_speed, 's')).to eq(0.5)
    end

    it 'handles numeric speeds' do
      expect(worm.send(:parse_speed, '1')).to eq(0.6)
      expect(worm.send(:parse_speed, '10')).to be_within(0.01).of(0.15)
    end

    it 'defaults to medium for invalid input' do
      expect(worm.send(:parse_speed, 'invalid')).to eq(0.2)
    end
  end

  describe '#parse_style' do
    it 'returns correct style for valid input' do
      expect(worm.send(:parse_style, 'circles')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_style, 'blocks')).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
      expect(worm.send(:parse_style, 'geometric')).to eq(RubyProgress::Worm::RIPPLE_STYLES['geometric'])
    end

    it 'handles abbreviated style names' do
      expect(worm.send(:parse_style, 'c')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_style, 'b')).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
      expect(worm.send(:parse_style, 'g')).to eq(RubyProgress::Worm::RIPPLE_STYLES['geometric'])
    end

    it 'defaults to circles for invalid input' do
      expect(worm.send(:parse_style, 'invalid')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end
  end

  describe '#generate_dots' do
    it 'generates correct dot pattern' do
      dots = worm.send(:generate_dots, 1, 1)
      expect(dots).to be_a(String)
      expect(dots.length).to eq(3)
    end

    it 'includes peak character at position' do
      dots = worm.send(:generate_dots, 1, 1)
      expect(dots[1]).to eq('⬤') # peak character for circles style
    end
  end

  describe '#display_completion_message' do
    context 'without checkmark' do
      it 'displays plain message' do
        expect { worm.send(:display_completion_message, 'Done!', true) }
          .to output("Done!\n").to_stdout
      end
    end

    context 'with checkmark enabled' do
      let(:checkmark_worm) { described_class.new(checkmark: true) }

      it 'displays success message with checkmark' do
        expect { checkmark_worm.send(:display_completion_message, 'Success!', true) }
          .to output("✅ Success!\n").to_stdout
      end

      it 'displays failure message with checkmark' do
        expect { checkmark_worm.send(:display_completion_message, 'Failed!', false) }
          .to output("🛑 Failed!\n").to_stdout
      end
    end
  end

  describe '#stop' do
    it 'stops the animation' do
      worm.instance_variable_set(:@running, true)
      worm.stop
      expect(worm.instance_variable_get(:@running)).to be false
    end
  end
end
