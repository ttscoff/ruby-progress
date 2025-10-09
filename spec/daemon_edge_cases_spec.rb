# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'json'

RSpec.describe 'Daemon Module Edge Cases' do
  it 'handles missing PID file when stopping daemon' do
    non_existent_file = '/tmp/non_existent_pid.pid'

    expect do
      RubyProgress::Daemon.stop_daemon_by_pid_file(non_existent_file)
    end.to output(/PID file.*not found/).to_stdout.and raise_error(SystemExit)
  end

  it 'creates control message file with all options' do
    temp_dir = Dir.mktmpdir
    pid_file = File.join(temp_dir, 'test.pid')
    File.write(pid_file, '99999')

    expect do
      RubyProgress::Daemon.stop_daemon_by_pid_file(
        pid_file,
        message: 'Custom message',
        checkmark: true,
        error: false
      )
    end.to raise_error(SystemExit)

    control_file = RubyProgress::Daemon.control_message_file(pid_file)
    expect(File.exist?(control_file)).to be true

    data = JSON.parse(File.read(control_file))
    expect(data['message']).to eq('Custom message')
    expect(data['checkmark']).to be true
    expect(data['success']).to be true

    FileUtils.rm_rf(temp_dir)
  end
end
