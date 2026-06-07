# Arneis::Generator::Veo - Media generator using Google Veo (Video).
# Orchestrates generation via Hussain's Python script.
# Supports asynchronous polling.

require "open3"
require "fileutils"
require "shellwords"

module Arneis
  module Generator
    class Veo < Base
      @@last_launch_at = nil
      @@launch_mutex = Mutex.new

      def initialize(options = {})
        super
        @model = Models::VEO_DEFAULT
      end

      def check_status(operation_id, output_file)
        puts Rainbow("  🔍 [VEO] Checking status for operation: #{operation_id}").cyan
        cmd = "uv run #{Config.veo_script} -o #{output_file} --check-status \"#{operation_id}\""

        env = {
          "GOOGLE_CLOUD_PROJECT" => Config.google_cloud_project,
          "GOOGLE_CLOUD_REGION" => Config.google_cloud_region
        }

        success = false
        Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
          stdin.close

          t_err = Thread.new do
            while line = stderr.gets
              puts "    [VEO SCRIPT] #{line.strip}"
            end
          rescue IOError
          end

          t_out = Thread.new do
            while line = stdout.gets
              if /^MEDIA:(.*)$/.match?(line)
                success = true
              end
            end
          rescue IOError
          end

          t_err.join
          t_out.join
          success = wait_thr.value.success? if success == false
        end

        if success && File.exist?(output_file)
          puts Rainbow("  ✅ [VEO] Video retrieved successfully!").green
          {status: "done", file: output_file}
        else
          {status: "polling"}
        end
      end

      def generate(prompt, output_file, timeout: 600, asset_id: nil, async: false)
        return maybe_mock(output_file, :video, prompt) if dryrun?

        receipt = AssetReceipt.new(asset_id: asset_id || "video_#{Time.now.to_i}", model: @model, prompt: prompt)

        # Throttling
        @@launch_mutex.synchronize do
          if @@last_launch_at
            elapsed = Time.now - @@last_launch_at
            if elapsed < 2.0
              wait_time = 2.0 - elapsed
              unless ENV["RSPEC_RUNNING"] == "true"
                puts Rainbow("  ⏳ [THROTTLE] Waiting #{wait_time.round(2)}s for next video launch...").yellow
                sleep(wait_time)
              end
            end
          end
          @@last_launch_at = Time.now
        end

        puts Rainbow("  🎥 [VEO] Starting real video generation via Python script (Async: #{async})...").magenta

        # Call script
        escaped_prompt = Shellwords.escape(prompt)
        async_flag = async ? "--async-only" : ""
        cmd = "uv run #{Config.veo_script} #{escaped_prompt} -o #{output_file} #{async_flag}"

        env = {
          "GOOGLE_CLOUD_PROJECT" => Config.google_cloud_project,
          "GOOGLE_CLOUD_REGION" => Config.google_cloud_region,
          "GENMEDIA_BUCKET" => Config.genmedia_bucket
        }

        operation_id = nil
        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close

            # Print stderr to show progress
            t_err = Thread.new do
              while line = stderr.gets
                puts "    [VEO SCRIPT] #{line.strip}"
              end
            rescue IOError
            end

            # Script outputs MEDIA:path on success or OPERATION_ID:id
            t_out = Thread.new do
              while line = stdout.gets
                if line =~ /^MEDIA:(.*)$/
                  media_path = $1.strip
                  unless File.expand_path(media_path) == File.expand_path(output_file)
                    FileUtils.mkdir_p(File.dirname(output_file))
                    FileUtils.mv(media_path, output_file)
                  end
                  success = true
                elsif line =~ /^OPERATION_ID:(.*)$/
                  operation_id = $1.strip
                  success = true
                end
              end
            rescue IOError
            end

            t_err.join
            t_out.join
            # Wait for process to exit
            success = wait_thr.value.success? if success.nil?
          end

          if async && operation_id
            puts Rainbow("  🔵 [VEO] Async operation started: #{operation_id}").blue
            {status: "polling", operation_id: operation_id}
          elsif success && File.exist?(output_file)
            puts Rainbow("  ✅ [VEO] Video generated successfully!").green
            receipt.complete!(cost_usd: Pricing::COST_PER_VEO_GEN)
            receipt.save!(output_file)
            {status: "done", tokens: 0, cost: Pricing::COST_PER_VEO_GEN, time: (Time.now - Time.parse(receipt.ts_started)).round(2)}
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [VEO] Script failed: #{sanitized_msg}").yellow

          if Config.no_mock?
            puts Rainbow("  🚫 Mocking disabled. Raising error.").red
            raise e
          end

          puts Rainbow("  🤡 Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_VEO_VIDEO_FOR: #{prompt}")
          {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end
      end
    end
  end
end
