# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Worm, 'integration tests' do
  let(:worm) { described_class.new(length: 3, message: 'Testing', speed: 'fast') }

  describe '#animate' do
    it 'executes a block and returns result' do
      result = worm.animate(message: 'Working') { 'block_result' }
      expect(result).to eq('block_result')
    end

    it 'handles exceptions in block' do
      expect do
        worm.animate { raise StandardError, 'test error' }
      end.not_to raise_error
    end

    it 'updates message when provided' do
      worm.animate(message: 'New message') {}
      expect(worm.instance_variable_get(:@message)).to eq('New message')
    end

    it 'updates success and error text when provided' do
      worm.animate(success: 'Success!', error: 'Failed!') {}
      expect(worm.instance_variable_get(:@success_text)).to eq('Success!')
      expect(worm.instance_variable_get(:@error_text)).to eq('Failed!')
    end
  end

  describe '#run_with_command' do
    before do
      allow(worm).to receive(:animate).and_yield
    end

    it 'executes simple commands' do
      command_worm = described_class.new(command: 'echo "test"')
      expect { command_worm.run_with_command }.not_to raise_error
    end

    it 'handles command failures gracefully' do
      command_worm = described_class.new(command: 'false') # Command that always fails
      expect { command_worm.run_with_command }.not_to raise_error
    end

    it 'does nothing when no command is set' do
      expect(worm.run_with_command).to be_nil
    end
  end

  describe '#animation_loop_step' do
    before do
      worm.instance_variable_set(:@running, true)
      allow(worm).to receive(:sleep) # Don't actually sleep in tests
      allow($stdout).to receive(:flush)
    end

    it 'prints animation frame when running' do
      expect { worm.send(:animation_loop_step) }.to output(/Testing/).to_stdout
    end

    it 'does nothing when not running' do
      worm.instance_variable_set(:@running, false)
      expect { worm.send(:animation_loop_step) }.not_to output.to_stdout
    end

    it 'handles nil message gracefully' do
      nil_worm = described_class.new(message: nil)
      nil_worm.instance_variable_set(:@running, true)
      allow(nil_worm).to receive(:sleep)
      allow($stdout).to receive(:flush)

      expect { nil_worm.send(:animation_loop_step) }.not_to raise_error
    end

    it 'handles empty message gracefully' do
      empty_worm = described_class.new(message: '')
      empty_worm.instance_variable_set(:@running, true)
      allow(empty_worm).to receive(:sleep)
      allow($stdout).to receive(:flush)

      expect { empty_worm.send(:animation_loop_step) }.not_to raise_error
    end
  end

  describe '#run_indefinitely' do
    it 'sets up signal handling' do
      expect(Signal).to receive(:trap).with('INT').and_return(nil)
      allow(worm).to receive(:animation_loop)
      allow(RubyProgress::Utils).to receive(:hide_cursor)
      allow(RubyProgress::Utils).to receive(:show_cursor)

      worm.run_indefinitely
    end
  end

  describe 'style constants' do
    it 'has all required style definitions' do
      styles = RubyProgress::Worm::RIPPLE_STYLES
      expect(styles).to have_key('circles')
      expect(styles).to have_key('blocks')
      expect(styles).to have_key('geometric')

      # Each style should have baseline, midline, and peak
      styles.each do |name, style|
        expect(style).to have_key(:baseline), "#{name} missing baseline"
        expect(style).to have_key(:midline), "#{name} missing midline"
        expect(style).to have_key(:peak), "#{name} missing peak"
      end
    end
  end
end
