# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Utils do
  describe '.display_completion' do
    it 'prints custom success icon without checkmark when provided' do
      expect do
        described_class.display_completion('Yay', success: true, show_checkmark: false, output_stream: :warn, icons: { success: '🎉' })
      end.to output("\r\e[2K🎉 Yay\n").to_stderr
    end

    it 'prints custom error icon without checkmark when provided' do
      expect do
        described_class.display_completion('Nope', success: false, show_checkmark: false, output_stream: :warn, icons: { error: '💥' })
      end.to output("\r\e[2K💥 Nope\n").to_stderr
    end

    it 'respects stdout output_stream' do
      expect do
        described_class.display_completion('Done', success: true, show_checkmark: true, output_stream: :stdout)
      end.to output("Done\n").to_stdout
    end
  end
end
