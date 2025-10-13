# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/ruby-progress/cli/twirl_spinner'

RSpec.describe TwirlSpinner do
  let(:spinner) { described_class.new('msg', style: 'custom=⭐🌙☀') }

  it 'builds frames from custom= characters' do
    # Access private @frames via instance_variable_get for test purposes
    frames = spinner.instance_variable_get(:@frames)
    expect(frames).to be_an(Array)
    expect(frames.length).to eq(3)
    expect(frames).to include('⭐', '🌙', '☀')
  end
end
