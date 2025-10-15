# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RubyProgress Version Constants' do
  it 'defines VERSION constant' do
    expect(RubyProgress::VERSION).to be_a(String)
    expect(RubyProgress::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'defines WORM_VERSION constant' do
    expect(RubyProgress::WORM_VERSION).to be_a(String)
    expect(RubyProgress::WORM_VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'defines TWIRL_VERSION constant' do
    expect(RubyProgress::TWIRL_VERSION).to be_a(String)
    expect(RubyProgress::TWIRL_VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'defines RIPPLE_VERSION constant' do
    expect(RubyProgress::RIPPLE_VERSION).to be_a(String)
    expect(RubyProgress::RIPPLE_VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'defines FILL_VERSION constant' do
    expect(RubyProgress::FILL_VERSION).to be_a(String)
    expect(RubyProgress::FILL_VERSION).to match(/^\d+\.\d+\.\d+$/)
  end

  it 'has component versions that are compatible with main version' do
    main_major = RubyProgress::VERSION.split('.').first.to_i

    [
      RubyProgress::WORM_VERSION,
      RubyProgress::TWIRL_VERSION,
      RubyProgress::RIPPLE_VERSION,
      RubyProgress::FILL_VERSION
    ].each do |component_version|
      component_major = component_version.split('.').first.to_i
      expect(component_major).to be <= main_major
    end
  end
end
