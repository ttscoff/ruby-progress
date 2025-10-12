# frozen_string_literal: true

require 'timeout'
require 'json'
require 'fileutils'
require 'tmpdir'
require 'open3'
require 'stringio'
require 'securerandom'

RSpec.describe 'daemon job processing (integration)' do
  it 'starts a daemon, accepts a job, writes log and result' do
    Dir.mktmpdir('ruby-progress-integ') do |_tmp|
      daemon_name = "rp-integ-#{SecureRandom.hex(4)}"
      pid_file = "/tmp/ruby-progress/#{daemon_name}.pid"

      # Start daemon (this process detaches)
      bin = File.join(Dir.pwd, 'bin', 'prg')
      start_cmd = [bin, 'worm', '--daemon-as', daemon_name, '--message', 'Integ']
      spawn(*start_cmd, out: '/dev/null', err: '/dev/null')

      begin
        # Wait for pid file
        Timeout.timeout(5) do
          sleep 0.05 until File.exist?(pid_file)
        end

        # Send job
        out = nil
        orig = $stdout
        $stdout = StringIO.new
        begin
          require File.join(Dir.pwd, 'lib', 'ruby-progress', 'cli', 'job_cli')
          JobCLI.send(['--daemon-name', daemon_name, '--command', 'echo integ-output'])
          out = $stdout.string
        ensure
          $stdout = orig
        end

        job_id = out.strip
        expect(job_id).not_to be_empty

        job_dir = File.join(File.dirname(pid_file), "#{File.basename(pid_file, '.*')}.jobs")
        result_path = File.join(job_dir, "#{job_id}.json.processing.result")

        # wait for result
        Timeout.timeout(8) do
          sleep 0.05 until File.exist?(result_path)
        end

        result = JSON.parse(File.read(result_path))
        expect(result['status']).to eq('done')
        expect(result['id']).to eq(job_id)

        # verify log_path exists and contains output
        log_path = result['log_path']
        expect(log_path).not_to be_nil
        expect(File).to exist(log_path)
        content = File.read(log_path)
        expect(content).to include('integ-output')
      ensure
        # Stop daemon
        system(bin, 'worm', '--stop-success', 'Integration done', '--stop-checkmark', '--daemon-name', daemon_name)
        # fallback cleanup
        FileUtils.rm_f(pid_file)
      end
    end
  end
end
