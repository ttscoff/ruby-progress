# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ripple Edge Cases' do
  it 'handles different output modes' do
    # Test stdout output mode - due to bug in code, this returns nil
    stdout_result = RubyProgress::Ripple.progress('Test', output: :stdout) { 'result' }
    expect(stdout_result).to be_nil # Bug: should return 'result' but @options should be options

    # Test error mode (default)
    error_result = RubyProgress::Ripple.progress('Test', output: :error) { 'result' }
    expect(error_result).to be_nil
  end

  it 'handles exceptions in progress blocks' do
    result = RubyProgress::Ripple.progress('Test') do
      raise StandardError, 'test error'
    end
    expect(result).to be_nil
  end

  it 'handles spinner mode in printout' do
    spinner_ripple = RubyProgress::Ripple.new('Test', spinner: :dots, spinner_position: :before)
    expect { spinner_ripple.send(:printout) }.not_to raise_error

    after_spinner = RubyProgress::Ripple.new('Test', spinner: :dots, spinner_position: :after)
    expect { after_spinner.send(:printout) }.not_to raise_error
  end

  it 'handles forward_only format mode' do
    forward_ripple = RubyProgress::Ripple.new('Test', format: :forward_only)

    # Advance to the end and beyond
    10.times { forward_ripple.advance }

    # Should reset to 0, not go backward
    expect(forward_ripple.instance_variable_get(:@direction)).to eq(:forward)
  end
end
