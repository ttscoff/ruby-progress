# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CLI icon propagation' do
  let(:bin_path) { File.join(File.dirname(__dir__), '..', 'bin', 'prg') }

  it 'parses and propagates --success-icon and --error-icon' do
    _out, err, st = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'true' --success 'OK' --success-icon '✨' --stdout")
    expect(st.exitstatus).to eq(0)
    expect(err).to include('✨')

    _out, err2, st2 = Open3.capture3("ruby #{bin_path} ripple 'Test' --command 'false' --success 'OK' --error 'No' --error-icon '❌' --stdout")
    expect(st2.exitstatus).to eq(1)
    expect(err2).to include('❌')
  end
end
