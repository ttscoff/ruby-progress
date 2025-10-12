# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'CLI ripple output capture' do
  let(:bin_path) { File.join(File.dirname(__dir__), 'bin', 'prg') }

  it 'captures command output and prints it when --stdout is used' do
    stdout, _stderr, status = Open3.capture3("ruby #{bin_path} ripple 'Loading' --command 'echo ripple_ok' --stdout --output-lines 2")
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include('ripple_ok')
  end
end
