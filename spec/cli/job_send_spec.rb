# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../lib/ruby-progress/cli/job_cli'
require 'json'

RSpec.describe 'prg job send' do
  it 'writes a job file and prints job id' do
    Dir.mktmpdir('ruby-progress-spec') do |tmp|
      pid_file = File.join(tmp, 'progress.pid')
      File.write(pid_file, '12345')

      job_dir = File.join(File.dirname(pid_file), 'progress.jobs')
      FileUtils.rm_rf(job_dir)

      out = nil
      orig = $stdout
      $stdout = StringIO.new
      begin
        JobCLI.send(['--pid-file', pid_file, '--command', 'echo hi'])
        out = $stdout.string
      ensure
        $stdout = orig
      end

      expect(out.strip).not_to be_empty
      id = out.strip
      final = File.join(job_dir, "#{id}.json")
      tmpf = File.join(job_dir, "#{id}.json.tmp")
      expect(File).to exist(final) or expect(File).to exist(tmpf)
    end
  end

  it 'waits for a result when --wait is used' do
    Dir.mktmpdir('ruby-progress-spec') do |tmp|
      pid_file = File.join(tmp, 'progress.pid')
      File.write(pid_file, '12345')

      job_dir = File.join(File.dirname(pid_file), 'progress.jobs')
      FileUtils.mkdir_p(job_dir)

      # Simulate a processor that will create the result file after a short delay
      Thread.new do
        sleep 0.2
        # find the job file (.json or .json.tmp)
        j = Dir.children(job_dir).grep(/\.json(?:\.tmp)?$/).first
        path = File.join(job_dir, j)
        processing = "#{path}.processing"
        FileUtils.mv(path, processing)
        result = { id: JSON.parse(File.read(processing))['id'], status: 'done' }
        File.write("#{processing}.result", JSON.dump(result))
        FileUtils.mv(processing, File.join(job_dir, "processed-#{j}"))
      end

      # Run send with --wait
      out = nil
      orig = $stdout
      $stdout = StringIO.new
      begin
        JobCLI.send(['--pid-file', pid_file, '--command', 'sleep 0.1', '--wait', '--timeout', '5'])
        out = $stdout.string
      ensure
        $stdout = orig
      end

      expect(out).to include('done')
    end
  end

  it 'writes an action job when --advance is used' do
    Dir.mktmpdir('ruby-progress-spec') do |tmp|
      pid_file = File.join(tmp, 'progress.pid')
      File.write(pid_file, '12345')

      job_dir = File.join(File.dirname(pid_file), 'progress.jobs')
      FileUtils.rm_rf(job_dir)

      out = nil
      orig = $stdout
      $stdout = StringIO.new
      begin
        JobCLI.send(['--pid-file', pid_file, '--advance'])
        out = $stdout.string
      ensure
        $stdout = orig
      end

      id = out.strip
      final = File.join(job_dir, "#{id}.json")
      expect(File).to exist(final)
      payload = JSON.parse(File.read(final))
      expect(payload['action']).to eq('advance')
    end
  end

  it 'writes an action job with value when --percent is used' do
    Dir.mktmpdir('ruby-progress-spec') do |tmp|
      pid_file = File.join(tmp, 'progress.pid')
      File.write(pid_file, '12345')

      job_dir = File.join(File.dirname(pid_file), 'progress.jobs')
      FileUtils.rm_rf(job_dir)

      out = nil
      orig = $stdout
      $stdout = StringIO.new
      begin
        JobCLI.send(['--pid-file', pid_file, '--percent', '42'])
        out = $stdout.string
      ensure
        $stdout = orig
      end

      id = out.strip
      final = File.join(job_dir, "#{id}.json")
      expect(File).to exist(final)
      payload = JSON.parse(File.read(final))
      expect(payload['action']).to eq('percent')
      expect(payload['value']).to eq(42)
    end
  end

  it 'errors when mixing --command and an action flag' do
    Dir.mktmpdir('ruby-progress-spec') do |tmp|
      pid_file = File.join(tmp, 'progress.pid')
      File.write(pid_file, '12345')

      # Capture stderr
      err = nil
      orig_err = $stderr
      $stderr = StringIO.new
      begin
        expect { JobCLI.send(['--pid-file', pid_file, '--command', 'echo hi', '--advance']) }.to raise_error(SystemExit)
        err = $stderr.string
      ensure
        $stderr = orig_err
      end

      expect(err).to include('Cannot specify both')
    end
  end
end
