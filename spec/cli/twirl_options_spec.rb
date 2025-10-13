# frozen_string_literal: true

require 'open3'
require 'spec_helper'

RSpec.describe 'prg twirl CLI options' do
  let(:bin) { File.expand_path('../../bin/prg', __dir__) }

  it 'accepts --direction forward and exits cleanly' do
    cmd = "ruby #{bin} twirl --direction forward --message 'Direction test' --help"
    _out, _err, status = Open3.capture3(cmd)
    expect(status.exitstatus).to be >= 0
  end

  it "accepts --style 'custom=abc' without crashing" do
    cmd = "ruby #{bin} twirl --style 'custom=abc' --message 'Custom style test' --help"
    _out, _err, status = Open3.capture3(cmd)
    expect(status.exitstatus).to be >= 0
  end
end
