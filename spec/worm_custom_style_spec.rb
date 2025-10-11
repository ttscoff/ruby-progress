# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Worm custom styles' do
  let(:worm) { RubyProgress::Worm.new }

  describe 'parse_custom_style method' do
    it 'parses valid 3-character ASCII custom styles' do
      style = worm.send(:parse_custom_style, 'abc')
      expect(style).to eq({
                            baseline: 'a',
                            midline: 'b',
                            peak: 'c'
                          })
    end

    it 'parses valid 3-character Unicode custom styles' do
      style = worm.send(:parse_custom_style, '▫▪■')
      expect(style).to eq({
                            baseline: '▫',
                            midline: '▪',
                            peak: '■'
                          })
    end

    it 'parses valid 3-character emoji custom styles' do
      style = worm.send(:parse_custom_style, '🟦🟨🟥')
      expect(style).to eq({
                            baseline: '🟦',
                            midline: '🟨',
                            peak: '🟥'
                          })
    end

    it 'parses mixed ASCII and emoji custom styles' do
      style = worm.send(:parse_custom_style, '.🟡*')
      expect(style).to eq({
                            baseline: '.',
                            midline: '🟡',
                            peak: '*'
                          })
    end

    it 'falls back to circles for styles with too few characters' do
      expect(worm.send(:parse_custom_style, 'ab')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_custom_style, 'a')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_custom_style, '')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'falls back to circles for styles with too many characters' do
      expect(worm.send(:parse_custom_style, 'abcd')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_custom_style, 'abcde')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'handles nil input gracefully' do
      expect { worm.send(:parse_custom_style, nil) }.to raise_error(NoMethodError)
    end

    it 'handles complex emoji sequences properly' do
      # Test with different types of emojis
      style = worm.send(:parse_custom_style, '👍🔥💯')
      expect(style).to eq({
                            baseline: '👍',
                            midline: '🔥',
                            peak: '💯'
                          })
    end
  end

  describe 'parse_style method with custom styles' do
    it 'detects and parses custom= format' do
      style = worm.send(:parse_style, 'custom=abc')
      expect(style).to eq({
                            baseline: 'a',
                            midline: 'b',
                            peak: 'c'
                          })
    end

    it 'detects and parses custom_format with underscores' do
      style = worm.send(:parse_style, 'custom_xyz')
      expect(style).to eq({
                            baseline: 'x',
                            midline: 'y',
                            peak: 'z'
                          })
    end

    it 'falls back to circles for unsupported custom formats like square brackets' do
      style = worm.send(:parse_style, 'custom[_-=]')
      expect(style).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'falls back to circles for invalid custom patterns' do
      style = worm.send(:parse_style, 'custom=ab') # too few chars
      expect(style).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'falls back to circles for malformed custom syntax' do
      style = worm.send(:parse_style, 'custom') # no pattern
      expect(style).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'still handles regular style names when custom not specified' do
      style = worm.send(:parse_style, 'blocks')
      expect(style).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
    end
  end

  describe 'custom style integration' do
    it 'uses custom style in animation' do
      custom_worm = RubyProgress::Worm.new(style: 'custom=_-=')

      dots = custom_worm.send(:generate_dots, 1, 1) # peak at position 1
      expect(dots).to include('=') # peak character
      expect(dots).to include('_') # baseline character
    end

    it 'uses custom emoji style in animation' do
      emoji_worm = RubyProgress::Worm.new(style: 'custom=🟦🟨🟥')

      dots = emoji_worm.send(:generate_dots, 1, 1) # peak at position 1
      expect(dots).to include('🟥') # peak character
      expect(dots).to include('🟦') # baseline character
    end

    it 'combines custom style with direction control' do
      custom_forward_worm = RubyProgress::Worm.new(
        style: 'custom=abc',
        direction: :forward
      )

      expect(custom_forward_worm.instance_variable_get(:@direction_mode)).to eq(:forward)

      dots = custom_forward_worm.send(:generate_dots, 1, 1)
      expect(dots).to include('c') # peak character
      expect(dots).to include('a') # baseline character
    end
  end

  describe 'multi-byte character handling' do
    it 'correctly counts emoji characters' do
      # These should be treated as single characters
      test_cases = [
        '🔴🟡🟢', # colored circles
        '👍👎💯', # thumbs and number
        '🎯🎪🎨', # various objects
        '🟦🟨🟥'  # colored squares
      ]

      test_cases.each do |pattern|
        style = worm.send(:parse_custom_style, pattern)
        expect(style).not_to be_nil, "Failed to parse #{pattern}"
        expect(style[:baseline]).to eq(pattern[0])
        expect(style[:midline]).to eq(pattern[1])
        expect(style[:peak]).to eq(pattern[2])
      end
    end

    it 'handles mixed character types correctly' do
      pattern = 'a🟡z'
      style = worm.send(:parse_custom_style, pattern)

      expect(style).to eq({
                            baseline: 'a',
                            midline: '🟡',
                            peak: 'z'
                          })
    end
  end
end
