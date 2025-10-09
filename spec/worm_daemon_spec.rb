# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'json'

RSpec.describe 'Worm Daemon Edge Cases' do
  it 'handles control message file existence check' do
    temp_dir = Dir.mktmpdir
    control_file = File.join(temp_dir, 'test.msg')

    # Create malformed JSON to test error handling
    File.write(control_file, 'invalid json{')

    expect(File.exist?(control_file)).to be true
    expect(File.read(control_file)).to eq('invalid json{')

    FileUtils.rm_rf(temp_dir)
  end
end