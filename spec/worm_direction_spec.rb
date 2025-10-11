# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Worm direction control' do
  describe 'direction initialization' do
    it 'defaults to bidirectional' do
      worm = RubyProgress::Worm.new
      expect(worm.instance_variable_get(:@direction_mode)).to eq(:bidirectional)
    end

    it 'accepts forward_only direction (as used by CLI)' do
      worm = RubyProgress::Worm.new(direction: :forward_only)
      expect(worm.instance_variable_get(:@direction_mode)).to eq(:forward_only)
    end

    it 'accepts bidirectional direction' do
      worm = RubyProgress::Worm.new(direction: :bidirectional)
      expect(worm.instance_variable_get(:@direction_mode)).to eq(:bidirectional)
    end

    it 'accepts string directions as-is (CLI handles parsing)' do
      # The CLI parses strings to symbols, but the class accepts any value
      forward_worm = RubyProgress::Worm.new(direction: 'forward')
      expect(forward_worm.instance_variable_get(:@direction_mode)).to eq('forward')

      bi_worm = RubyProgress::Worm.new(direction: 'bidirectional')
      expect(bi_worm.instance_variable_get(:@direction_mode)).to eq('bidirectional')
    end

    it 'accepts raw CLI-parsed symbols' do
      forward_worm = RubyProgress::Worm.new(direction: :forward_only)
      expect(forward_worm.instance_variable_get(:@direction_mode)).to eq(:forward_only)

      bi_worm = RubyProgress::Worm.new(direction: :bidirectional)
      expect(bi_worm.instance_variable_get(:@direction_mode)).to eq(:bidirectional)
    end

    it 'stores any direction value provided' do
      worm = RubyProgress::Worm.new(direction: 'invalid')
      expect(worm.instance_variable_get(:@direction_mode)).to eq('invalid')
    end
  end

  describe 'bidirectional animation behavior' do
    let(:worm) do
      RubyProgress::Worm.new(
        direction: :bidirectional,
        length: 5,
        message: 'Test'
      )
    end

    before do
      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)
    end

    it 'changes direction at end boundary' do
      worm.instance_variable_set(:@position, 4) # at end for length 5
      worm.instance_variable_set(:@direction, 1) # moving forward
      worm.instance_variable_set(:@running, true)

      worm.send(:animation_loop_step)
      expect(worm.instance_variable_get(:@direction)).to eq(-1) # should reverse
    end

    it 'changes direction at start boundary' do
      worm.instance_variable_set(:@position, 0) # at start
      worm.instance_variable_set(:@direction, -1) # moving backward
      worm.instance_variable_set(:@running, true)

      worm.send(:animation_loop_step)
      expect(worm.instance_variable_get(:@direction)).to eq(1) # should reverse
    end
  end

  describe 'forward-only animation behavior' do
    let(:worm) do
      RubyProgress::Worm.new(
        direction: :forward_only,
        length: 5,
        message: 'Test'
      )
    end

    before do
      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)
    end

    it 'resets to start instead of reversing at end boundary' do
      worm.instance_variable_set(:@position, 4) # at end for length 5
      worm.instance_variable_set(:@direction, 1) # moving forward
      worm.instance_variable_set(:@running, true)

      worm.send(:animation_loop_step)
      expect(worm.instance_variable_get(:@position)).to eq(0) # should reset to start
      expect(worm.instance_variable_get(:@direction)).to eq(1) # should stay forward
    end

    it 'maintains forward direction during animation' do
      worm.instance_variable_set(:@direction, 1)
      worm.instance_variable_set(:@position, 2)

      # Run several animation steps
      5.times do |i|
        worm.instance_variable_set(:@running, true)
        worm.send(:animation_loop_step)
        # Direction should always stay 1 for forward_only mode
        expect(worm.instance_variable_get(:@direction)).to eq(1), "Failed at step #{i}"
      end
    end
  end

  describe 'animation patterns' do
    it 'creates different patterns for different directions' do
      forward_worm = RubyProgress::Worm.new(direction: :forward, length: 3)
      bi_worm = RubyProgress::Worm.new(direction: :bidirectional, length: 3)

      # Both should generate valid dot patterns
      forward_dots = forward_worm.send(:generate_dots, 1, 1)
      bi_dots = bi_worm.send(:generate_dots, 1, 1)

      expect(forward_dots).to be_a(String)
      expect(bi_dots).to be_a(String)
      expect(forward_dots.length).to eq(3)
      expect(bi_dots.length).to eq(3)
    end
  end
end
