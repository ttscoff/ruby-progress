# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Worm style fuzzy matching' do
  let(:worm) { RubyProgress::Worm.new }

  describe 'parse_style method' do
    it 'matches exact style names' do
      expect(worm.send(:parse_style, 'circles')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_style, 'blocks')).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
      expect(worm.send(:parse_style, 'circle_open')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circle_open'])
    end

    it 'matches prefix correctly' do
      expect(worm.send(:parse_style, 'b')).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
      expect(worm.send(:parse_style, 'g')).to eq(RubyProgress::Worm::RIPPLE_STYLES['geometric'])
    end

    it 'performs fuzzy matching with character order priority' do
      # 'co' should match 'circle_open' not 'circles'
      expect(worm.send(:parse_style, 'co')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circle_open'])

      # 'cio' should match 'circle_open'
      expect(worm.send(:parse_style, 'cio')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circle_open'])

      # Single 'c' should still match 'circles' (shortest prefix match)
      expect(worm.send(:parse_style, 'c')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'prioritizes shorter matches when multiple fuzzy matches exist' do
      # This ensures we get the shortest valid match
      style_name = RubyProgress::Worm::RIPPLE_STYLES.key(worm.send(:parse_style, 'circle'))
      expect(style_name).to eq('circles') # shorter than circle_open
    end

    it 'falls back to default for invalid inputs' do
      expect(worm.send(:parse_style, 'xyz')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_style, nil)).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
      expect(worm.send(:parse_style, '')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circles'])
    end

    it 'handles case insensitive matching' do
      expect(worm.send(:parse_style, 'BLOCKS')).to eq(RubyProgress::Worm::RIPPLE_STYLES['blocks'])
      expect(worm.send(:parse_style, 'Circle_Open')).to eq(RubyProgress::Worm::RIPPLE_STYLES['circle_open'])
    end
  end
end
