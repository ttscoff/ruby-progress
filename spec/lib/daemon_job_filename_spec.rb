# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'json'
require 'securerandom'
require 'timeout'
require_relative '../../lib/ruby-progress/daemon'

RSpec.describe RubyProgress::Daemon do
  it 'processes job files with numeric and UUID filenames' do
    Dir.mktmpdir('rp-jobs') do |tmp|
      # prepare two jobs: one numeric, one UUID
      numeric_id = '12345'
      uuid_id = "job-#{SecureRandom.uuid}"

      job_dir = tmp
      FileUtils.mkdir_p(job_dir)

      num_path = File.join(job_dir, "#{numeric_id}.json")
      uuid_path = File.join(job_dir, "#{uuid_id}.json")

      File.write(num_path, JSON.dump('id' => numeric_id, 'command' => 'echo num'))
      File.write(uuid_path, JSON.dump('id' => uuid_id, 'command' => 'echo uuid'))

      processed = []

      # run process_jobs in background thread and stop after some iterations
      t = Thread.new do
        RubyProgress::Daemon.process_jobs(job_dir, poll_interval: 0.05) do |job|
          processed << job['id']
          # return some metadata to be written into .processing.result
          { 'handled_by' => 'spec' }
        end
      end

      # wait for result files to appear
      Timeout.timeout(5) do
        sleep 0.05 until File.exist?(File.join(job_dir, "#{numeric_id}.json.processing.result")) &&
                         File.exist?(File.join(job_dir, "#{uuid_id}.json.processing.result"))
      end

      # Read and assert results
      num_result = JSON.parse(File.read(File.join(job_dir, "#{numeric_id}.json.processing.result")))
      uuid_result = JSON.parse(File.read(File.join(job_dir, "#{uuid_id}.json.processing.result")))

      expect(num_result['id']).to eq(numeric_id)
      expect(num_result['status']).to eq('done')
      expect(num_result['handled_by']).to eq('spec')

      expect(uuid_result['id']).to eq(uuid_id)
      expect(uuid_result['status']).to eq('done')
      expect(uuid_result['handled_by']).to eq('spec')

      # stop the thread
      t.kill
    end
  end
end
