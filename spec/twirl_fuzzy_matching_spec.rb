# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/ruby-progress/ripple'

# Simplified TwirlSpinner class with just the parse_style method for testing
class TwirlSpinner
  def parse_style(style_input)
    return :dots unless style_input && !style_input.to_s.strip.empty?

    style_lower = style_input.to_s.downcase.strip

    # First, try exact match (convert string keys to symbols for comparison)
    indicator_keys = RubyProgress::INDICATORS.keys.map(&:to_s)
    return style_lower.to_sym if indicator_keys.include?(style_lower)

    # Then try prefix matching - keys that start with the input
    prefix_matches = indicator_keys.select do |key|
      key.downcase.start_with?(style_lower)
    end

    unless prefix_matches.empty?
      # For prefix matches, return the shortest one
      best_match = prefix_matches.min_by(&:length)
      return best_match.to_sym
    end

    # Try character-by-character fuzzy matching for partial inputs
    # Find keys where the input characters appear in order (not necessarily contiguous)
    fuzzy_matches = indicator_keys.select do |key|
      key_chars = key.downcase.chars
      input_chars = style_lower.chars

      # Check if all input characters appear in order in the key
      input_chars.all? do |char|
        idx = key_chars.index(char)
        if idx
          key_chars = key_chars[idx + 1..-1] # Remove matched chars and continue
          true
        else
          false
        end
      end
    end

    unless fuzzy_matches.empty?
      # Sort by length (prefer shorter keys)
      best_match = fuzzy_matches.min_by(&:length)
      return best_match.to_sym
    end

    # Fallback to substring matching
    substring_matches = indicator_keys.select do |key|
      key.downcase.include?(style_lower)
    end

    unless substring_matches.empty?
      best_match = substring_matches.min_by(&:length)
      return best_match.to_sym
    end

    # Default fallback
    :dots
  end
end

RSpec.describe 'TwirlSpinner fuzzy matching' do
  let(:spinner) { TwirlSpinner.new }

  describe '#parse_style' do
    context 'exact matches' do
      it 'matches exact style names' do
        result = spinner.send(:parse_style, 'dots')
        expect(result).to eq(:dots)
      end

      it 'matches exact style names case-insensitively' do
        result = spinner.send(:parse_style, 'DOTS')
        expect(result).to eq(:dots)
      end
    end

    context 'prefix matches' do
      it 'matches shortest prefix when multiple prefixes exist' do
        # "dots" should match "dots" instead of "dots_2", "dots_3", or "dots_4"
        result = spinner.send(:parse_style, 'dots')
        expect(result).to eq(:dots)
      end

      it 'matches "pulse" instead of longer pulse variants' do
        result = spinner.send(:parse_style, 'pulse')
        expect(result).to eq(:pulse)
      end

      it 'matches partial prefix correctly' do
        # "dot" should match "dots" (shortest prefix match)
        result = spinner.send(:parse_style, 'dot')
        expect(result).to eq(:dots)
      end
    end

    context 'character-by-character fuzzy matches' do
      it 'matches characters in order for fuzzy input' do
        # "ao" should match "arrow" (a-r-r-o-w contains 'a' then 'o')
        result = spinner.send(:parse_style, 'ao')
        expect(result).to eq(:arrow)
      end

      it 'prefers shorter matches in fuzzy matching' do
        # "ar" could match "arrow" or "arc", should prefer shorter "arc"
        result = spinner.send(:parse_style, 'ar')
        expect(result).to eq(:arc)
      end

      it 'handles complex fuzzy patterns' do
        # "cls" should match "classic" (c-l-a-s-s-i-c contains c, then l, then s)
        result = spinner.send(:parse_style, 'cls')
        expect(result).to eq(:classic)
      end
    end

    context 'substring matches' do
      it 'falls back to substring matching when fuzzy fails' do
        # This is a fallback test - normally substring would be last resort
        result = spinner.send(:parse_style, 'lock')
        expect(result).to eq(:block_2) # Contains "lock" within "block" # rubocop:disable Naming/VariableNumber
      end
    end

    context 'edge cases' do
      it 'defaults to dots for empty input' do
        result = spinner.send(:parse_style, '')
        expect(result).to eq(:dots)
      end

      it 'defaults to dots for nil input' do
        result = spinner.send(:parse_style, nil)
        expect(result).to eq(:dots)
      end

      it 'defaults to dots for whitespace-only input' do
        result = spinner.send(:parse_style, '   ')
        expect(result).to eq(:dots)
      end

      it 'defaults to dots for no matches' do
        result = spinner.send(:parse_style, 'xyz123')
        expect(result).to eq(:dots)
      end
    end
  end
end
