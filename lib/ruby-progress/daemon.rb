# frozen_string_literal: true

require 'json'
require 'fileutils'

module RubyProgress
  module Daemon
    module_function

    def default_pid_file
      '/tmp/ruby-progress/progress.pid'
    end

    def control_message_file(pid_file)
      "#{pid_file}.msg"
    end

    # Resolve a job directory for the daemon based on pid_file or name.
    # If pid_file is '/tmp/ruby-progress/mytask.pid' -> jobs dir '/tmp/ruby-progress/mytask.jobs'
    def job_dir_for_pid(pid_file)
      base = File.basename(pid_file, '.*')
      File.join(File.dirname(pid_file), "#{base}.jobs")
    end

    # Process available job files in job_dir. Each job is a JSON file with {"id","command","meta"}.
    # This method polls the directory and yields each parsed job hash to the provided block.
    def process_jobs(job_dir, poll_interval: 0.2)
      FileUtils.mkdir_p(job_dir)

      loop do
        # Accept any job file ending in .json (UUID filenames are common)
        # Ignore processed-* archives and temporary files (e.g., .tmp)
        files = Dir.children(job_dir).select do |f|
          f.end_with?('.json') && !f.start_with?('processed-')
        end.sort

        files.each do |f|
          path = File.join(job_dir, f)
          processing = "#{path}.processing"

          # Claim the file atomically
          begin
            File.rename(path, processing)
          rescue StandardError
            next
          end

          job = begin
            JSON.parse(File.read(processing))
          rescue StandardError
            FileUtils.rm_f(processing)
            next
          end

          begin
            yielded = yield(job)

            # on success, write .result info and merge any returned info
            result = { 'id' => job['id'], 'status' => 'done', 'time' => Time.now.to_i }
            if yielded.is_a?(Hash)
              # ensure string keys
              extra = yielded.transform_keys(&:to_s)
              result.merge!(extra)
            end
            File.write("#{processing}.result", result.to_json)
          rescue StandardError => e
            result = { 'id' => job['id'], 'status' => 'error', 'error' => e.message }
            File.write("#{processing}.result", result.to_json)
          ensure
            begin
              FileUtils.mv(processing, File.join(job_dir, "processed-#{f}"))
            rescue StandardError
              FileUtils.rm_f(processing)
            end
          end
        end

        sleep(poll_interval)
      end
    end

    def show_status(pid_file)
      if File.exist?(pid_file)
        pid = File.read(pid_file).strip
        running = system("ps -p #{pid} > /dev/null")
        puts(running ? "Daemon running (pid #{pid})" : 'PID file present but process not running')
        exit(running ? 0 : 1)
      else
        puts 'Daemon not running'
        exit 1
      end
    end

    def stop_daemon_by_pid_file(pid_file, message: nil, checkmark: false, error: false)
      unless File.exist?(pid_file)
        puts "PID file #{pid_file} not found"
        exit 1
      end

      pid = File.read(pid_file).strip.to_i

      # Write control message file if provided
      if message || error
        cmf = control_message_file(pid_file)
        payload = { checkmark: checkmark, success: !error }
        payload[:message] = message if message
        File.write(cmf, payload.to_json)
      end

      begin
        Process.kill('USR1', pid)
        sleep 0.5
        FileUtils.rm_f(pid_file)
      rescue Errno::ESRCH
        puts "Process #{pid} not found (may have already stopped)"
        FileUtils.rm_f(pid_file)
        exit 1
      rescue Errno::EPERM
        puts "Permission denied sending signal to process #{pid}"
        exit 1
      end
    end
  end
end
