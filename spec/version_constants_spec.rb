# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Version Constants Coverage' do
  describe 'RubyProgress version constants' do
    it 'defines main VERSION constant' do
      expect(RubyProgress::VERSION).to be_a(String)
      expect(RubyProgress::VERSION).to match(/\d+\.\d+\.\d+/)
    end

    it 'defines RIPPLE_VERSION constant' do
      expect(RubyProgress::RIPPLE_VERSION).to be_a(String)
      expect(RubyProgress::RIPPLE_VERSION).to match(/\d+\.\d+\.\d+/)
    end

    it 'defines WORM_VERSION constant' do
      expect(RubyProgress::WORM_VERSION).to be_a(String)
      expect(RubyProgress::WORM_VERSION).to match(/\d+\.\d+\.\d+/)
    end

    it 'defines TWIRL_VERSION constant' do
      expect(RubyProgress::TWIRL_VERSION).to be_a(String)
      expect(RubyProgress::TWIRL_VERSION).to match(/\d+\.\d+\.\d+/)
    end

    it 'ensures all version constants are defined and accessible' do
      # This test touches all version constants to ensure coverage
      versions = [
        RubyProgress::VERSION,
        RubyProgress::RIPPLE_VERSION,
        RubyProgress::WORM_VERSION,
        RubyProgress::TWIRL_VERSION
      ]

      expect(versions.all? { |v| v.is_a?(String) && v.match(/\d+\.\d+\.\d+/) }).to be true
    end

    it 'version constants are not empty or nil' do
      expect(RubyProgress::VERSION).not_to be_nil
      expect(RubyProgress::VERSION).not_to be_empty

      expect(RubyProgress::RIPPLE_VERSION).not_to be_nil
      expect(RubyProgress::RIPPLE_VERSION).not_to be_empty

      expect(RubyProgress::WORM_VERSION).not_to be_nil
      expect(RubyProgress::WORM_VERSION).not_to be_empty

      expect(RubyProgress::TWIRL_VERSION).not_to be_nil
      expect(RubyProgress::TWIRL_VERSION).not_to be_empty
    end
  end
end
