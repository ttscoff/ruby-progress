# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe 'CLI icon propagation' do
  it 'renders custom success and error icons in the completion output' do
    out = StringIO.new

    # success icon
    RubyProgress::Utils.display_completion('All done', success: true, show_checkmark: true, output_stream: out, icons: { success: 'S' })
    out.rewind
    success_output = out.read
    expect(success_output).to include('S')

    out.truncate(0)
    out.rewind

    # error icon
    RubyProgress::Utils.display_completion('Failed', success: false, show_checkmark: true, output_stream: out, icons: { error: 'E' })
    out.rewind
    error_output = out.read
    expect(error_output).to include('E')
  end
end
