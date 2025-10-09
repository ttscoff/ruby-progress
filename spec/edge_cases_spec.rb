# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Worm Error Handling' do
  let(:worm) { RubyProgress::Worm.new(message: 'Test', speed: 'fast') }

  it 'handles numeric speed parsing edge cases' do
    # Test boundary conditions
    expect(worm.send(:parse_speed, '0')).to eq(0.2) # Should default to medium
    expect(worm.send(:parse_speed, '11')).to eq(0.2) # Should default to medium
    expect(worm.send(:parse_speed, 1)).to eq(0.6) # Numeric input: 0.6 - (1-1) * 0.05 = 0.6
    expect(worm.send(:parse_speed, 10)).to be_within(0.001).of(0.15) # Numeric input: 0.6 - (10-1) * 0.05 = 0.15
  end

  it 'handles position boundaries in animation' do
    worm.instance_variable_set(:@running, true)
    worm.instance_variable_set(:@position, 0)
    worm.instance_variable_set(:@direction, -1)

    allow(worm).to receive(:sleep)
    allow($stdout).to receive(:flush)

    # Should handle position <= 0 case
    expect { worm.send(:animation_loop_step) }.not_to raise_error
    expect(worm.instance_variable_get(:@direction)).to eq(1)
  end

  it 'handles Interrupt during command execution' do
    command_worm = RubyProgress::Worm.new(command: 'echo "test"')
    
    # Mock animate to raise Interrupt
    allow(command_worm).to receive(:animate).and_raise(Interrupt)
    
    # Should handle Interrupt gracefully in run_with_command
    expect { command_worm.run_with_command }.to raise_error(SystemExit)
  end
end