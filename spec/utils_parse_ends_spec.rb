# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RubyProgress::Utils.parse_ends' do
  describe 'valid inputs' do
    it 'parses even-length strings correctly' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('[]')
      expect(start_chars).to eq('[')
      expect(end_chars).to eq(']')
    end

    it 'parses longer even-length strings' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('<<>>')
      expect(start_chars).to eq('<<')
      expect(end_chars).to eq('>>')
    end

    it 'handles multi-byte characters' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('🎯🎪')
      expect(start_chars).to eq('🎯')
      expect(end_chars).to eq('🎪')
    end

    it 'handles complex emoji patterns' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('🔥💯🚀⭐')
      expect(start_chars).to eq('🔥💯')
      expect(end_chars).to eq('🚀⭐')
    end

    it 'handles mixed ASCII and emoji' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('[🎯]🎪')
      expect(start_chars).to eq('[🎯')
      expect(end_chars).to eq(']🎪')
    end
  end

  describe 'invalid inputs' do
    it 'returns empty strings for odd-length strings' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('abc')
      expect(start_chars).to eq('')
      expect(end_chars).to eq('')
    end

    it 'returns empty strings for single characters' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('a')
      expect(start_chars).to eq('')
      expect(end_chars).to eq('')
    end

    it 'returns empty strings for empty input' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('')
      expect(start_chars).to eq('')
      expect(end_chars).to eq('')
    end

    it 'returns empty strings for nil input' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends(nil)
      expect(start_chars).to eq('')
      expect(end_chars).to eq('')
    end

    it 'returns empty strings for whitespace-only input' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('  ')
      expect(start_chars).to eq(' ')
      expect(end_chars).to eq(' ')
    end
  end

  describe 'edge cases' do
    it 'handles very long strings' do
      input = 'abcdefghijklmnop'
      start_chars, end_chars = RubyProgress::Utils.parse_ends(input)
      expect(start_chars).to eq('abcdefgh')
      expect(end_chars).to eq('ijklmnop')
    end

    it 'handles special characters' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('|=|=')
      expect(start_chars).to eq('|=')
      expect(end_chars).to eq('|=')
    end

    it 'handles Unicode symbols' do
      start_chars, end_chars = RubyProgress::Utils.parse_ends('▶◀')
      expect(start_chars).to eq('▶')
      expect(end_chars).to eq('◀')
    end
  end
end
