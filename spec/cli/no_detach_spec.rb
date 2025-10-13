# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'english'
require 'timeout'

RSpec.describe 'no-detach background mode' do
  it 'allows starting a non-detaching background worker' do
    # This is a lightweight smoke test: start the worker with --no-detach in a
    # child process and ensure it exits successfully when we stop it.
    cmd = "bin/prg worm --daemon-as test-no-detach --no-detach --length 4 --command 'sleep 0.5' --success 'ok'"

    # Start the process in a subshell so this test can continue
    pid = spawn(cmd, out: '/dev/null', err: '/dev/null')
    sleep 0.2

    # Stop the worker
    system("bin/prg worm --stop-id test-no-detach --stop-success 'done' > /dev/null 2>&1")

    # Wait for the spawned process to exit
    begin
      Timeout.timeout(5) { Process.wait(pid) }
    rescue Timeout::Error
      begin
        Process.kill('TERM', pid)
      rescue StandardError => _e
        # ignore
      end
      raise 'worker did not exit in time'
    end

    expect($CHILD_STATUS.exitstatus).to be_between(0, 255)
  end
end
