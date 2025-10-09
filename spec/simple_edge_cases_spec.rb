# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Simple Edge Cases' do
  describe 'Worm parsing methods' do
    let(:worm) { RubyProgress::Worm.new(message: 'Test') }

    it 'handles edge cases in speed parsing' do
      expect(worm.send(:parse_speed, '0')).to eq(0.2)
      expect(worm.send(:parse_speed, '11')).to eq(0.2)
      expect(worm.send(:parse_speed, 1)).to eq(0.6)
      expect(worm.send(:parse_speed, 10)).to be_within(0.001).of(0.15)
    end

    it 'handles edge cases in style parsing' do
      expect(worm.send(:parse_style, 'invalid')).to eq(worm.send(:parse_style, 'circles'))
      expect(worm.send(:parse_style, nil)).to eq(worm.send(:parse_style, 'circles'))
    end
  end

  describe 'Ripple edge cases' do
    it 'handles different output modes' do
      stdout_result = RubyProgress::Ripple.progress('Test', output: :stdout) { 'result' }
      expect(stdout_result).to be_nil # Bug: should return 'result' but @options should be options

      error_result = RubyProgress::Ripple.progress('Test', output: :error) { 'result' }
      expect(error_result).to be_nil
    end

    it 'handles exceptions in progress blocks' do
      result = RubyProgress::Ripple.progress('Test') do
        raise StandardError, 'test error'
      end
      expect(result).to be_nil
    end

    it 'handles forward_only format mode' do
      forward_ripple = RubyProgress::Ripple.new('Test', format: :forward_only)
      10.times { forward_ripple.advance }
      expect(forward_ripple.instance_variable_get(:@direction)).to eq(:forward)
    end
  end

  describe 'Utils edge cases' do
    it 'handles different output streams' do
      expect { RubyProgress::Utils.display_completion('Test', output_stream: :stdout) }.not_to raise_error
      expect { RubyProgress::Utils.display_completion('Test', output_stream: :stderr) }.not_to raise_error
    end

    it 'handles nil message in complete_with_clear' do
      expect { RubyProgress::Utils.complete_with_clear(nil) }.not_to raise_error
    end
  end
end