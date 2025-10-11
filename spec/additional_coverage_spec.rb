# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Additional edge cases for coverage' do
  describe 'RubyProgress::Utils error output stream' do
    it 'handles different output streams for clear_line' do
      expect { RubyProgress::Utils.clear_line(:stderr) }.to output("\r\e[K").to_stderr
      expect { RubyProgress::Utils.clear_line(:stdout) }.to output("\r\e[K").to_stdout
      expect { RubyProgress::Utils.clear_line(:other) }.to output("\r\e[K").to_stderr # defaults to stderr
    end

    it 'handles display_completion with different streams' do
      expect { RubyProgress::Utils.display_completion('test', output_stream: :stdout) }
        .to output("test\n").to_stdout

      expect { RubyProgress::Utils.display_completion('test', output_stream: :stderr) }
        .to output("test\n").to_stderr

      expect { RubyProgress::Utils.display_completion('test', output_stream: :warn) }
        .to output("\r\e[2Ktest\n").to_stderr

      expect { RubyProgress::Utils.display_completion('test', output_stream: :other) }
        .to output("\r\e[2Ktest\n").to_stderr # defaults to warn behavior
    end

    it 'handles display_completion with checkmarks' do
      expect { RubyProgress::Utils.display_completion('Success', show_checkmark: true, success: true, output_stream: :stdout) }
        .to output("✅ Success\n").to_stdout

      expect { RubyProgress::Utils.display_completion('Failed', show_checkmark: true, success: false, output_stream: :stdout) }
        .to output("🛑 Failed\n").to_stdout
    end
  end

  describe 'Worm class edge cases' do
    let(:worm) { RubyProgress::Worm.new }

    it 'handles direction changes at boundaries' do
      worm.instance_variable_set(:@position, 9) # near boundary
      worm.instance_variable_set(:@direction, 1)
      worm.instance_variable_set(:@length, 10)
      worm.instance_variable_set(:@running, true)

      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)

      worm.send(:animation_loop_step)
      expect(worm.instance_variable_get(:@direction)).to eq(-1)
    end

    it 'handles direction changes at start boundary' do
      worm.instance_variable_set(:@position, 0)
      worm.instance_variable_set(:@direction, -1)
      worm.instance_variable_set(:@running, true)

      allow(worm).to receive(:sleep)
      allow($stderr).to receive(:print)
      allow($stderr).to receive(:flush)

      worm.send(:animation_loop_step)
      expect(worm.instance_variable_get(:@direction)).to eq(1)
    end
  end

  describe 'Ripple class edge cases' do
    it 'handles empty string input' do
      empty_ripple = RubyProgress::Ripple.new('')
      expect { empty_ripple.printout }.not_to raise_error
    end

    it 'handles very long strings' do
      long_string = 'A' * 100
      long_ripple = RubyProgress::Ripple.new(long_string)
      expect { long_ripple.printout }.not_to raise_error
    end

    it 'handles special characters in string' do
      special_ripple = RubyProgress::Ripple.new('Test 🌈 Special! @#$%')
      expect { special_ripple.printout }.not_to raise_error
    end
  end
end
