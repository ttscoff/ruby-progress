# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress::Utils do
  describe '.hide_cursor' do
    it 'outputs ANSI hide cursor sequence' do
      expect { RubyProgress::Utils.hide_cursor }.to output("\e[?25l").to_stderr
    end
  end

  describe '.show_cursor' do
    it 'outputs ANSI show cursor sequence' do
      expect { RubyProgress::Utils.show_cursor }.to output("\e[?25h").to_stderr
    end
  end

  describe '.clear_line' do
    it 'outputs ANSI clear line sequence to stderr by default' do
      expect { RubyProgress::Utils.clear_line }.to output("\r\e[K").to_stderr
    end

    it 'outputs ANSI clear line sequence to stdout when specified' do
      expect { RubyProgress::Utils.clear_line(:stdout) }.to output("\r\e[K").to_stdout
    end
  end

  describe '.clear_line_aggressive' do
    it 'outputs aggressive line clearing sequence to stderr' do
      expect { RubyProgress::Utils.clear_line_aggressive }
        .to output("\r\e[2K\e[1A\e[2K\r").to_stderr
    end
  end

  describe '.display_completion' do
    context 'without checkmark' do
      it 'displays plain message to warn by default' do
        expect { RubyProgress::Utils.display_completion('Done!') }.to output("\e[2KDone!\n").to_stderr
      end

      it 'displays plain message to stdout when specified' do
        expect do
          RubyProgress::Utils.display_completion('Done!', output_stream: :stdout)
        end.to output("Done!\n").to_stdout
      end
    end

    context 'with checkmark enabled' do
      it 'displays success message with checkmark' do
        expect do
          RubyProgress::Utils.display_completion('Success!', success: true, show_checkmark: true)
        end.to output("\e[2K✅ Success!\n").to_stderr
      end

      it 'displays failure message with X mark' do
        expect do
          RubyProgress::Utils.display_completion('Failed!', success: false, show_checkmark: true)
        end.to output("\e[2K🛑 Failed!\n").to_stderr
      end
    end

    context 'with nil message' do
      it 'does not output anything' do
        expect { RubyProgress::Utils.display_completion(nil) }.not_to output.to_stderr
      end
    end
  end

  describe '.complete_with_clear' do
    it 'clears line and displays message for non-warn streams' do
      expect { RubyProgress::Utils.complete_with_clear('Done!', output_stream: :stdout) }
        .to output("\r\e[KDone!\n").to_stdout
    end

    it 'does not double-clear for warn stream' do
      expect { RubyProgress::Utils.complete_with_clear('Done!', output_stream: :warn) }
        .to output("\e[2KDone!\n").to_stderr
    end
  end
end
