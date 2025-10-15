# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Ripple do
  describe '.complete with custom icons' do
    it 'prints provided success icon even without checkmark' do
      expect do
        described_class.complete('Test', 'Yay', false, true, icons: { success: '🎉' })
      end.to output("\r\e[2K🎉 Yay\n").to_stderr
    end

    it 'prints provided error icon even without checkmark' do
      expect do
        described_class.complete('Test', 'Nope', false, false, icons: { error: '💥' })
      end.to output("\r\e[2K💥 Nope\n").to_stderr
    end
  end
end
