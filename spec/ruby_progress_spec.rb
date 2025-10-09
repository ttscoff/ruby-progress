# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyProgress do
  it 'has a version number' do
    expect(RubyProgress::VERSION).not_to be nil
  end

  it 'has the correct version format' do
    expect(RubyProgress::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
