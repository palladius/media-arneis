=begin
Arneis::Generator::Veo - Media generator using Google Veo (Video).
Orchestrates generation via Hussain's Python script.
Supports asynchronous polling.
=end

require 'thread'
require 'open3'
require 'fileutils'

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
          'GOOGLE_CLOUD_PROJECT' => Config.google_cloud_project,
          'GOOGLE_CLOUD_REGION' => Config.google_cloud_region
        }

        success = false
        Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          
          t_err = Thread.new do
            while line = stderr.gets
              puts "    [VEO SCRIPT] #{line.strip}"
            end
          end

          t_out = Thread.new do
            while line = stdout.gets
              if line =~ /^MEDIA:(.*)$/
                success = true
              end
            end
          end

          t_err.join
          t_out.join
          wait_thr.join
        end

        if success && File.exist?(output_file)
          puts Rainbow("  ✅ [VEO] Video retrieved successfully!").green
          { status: 'done', file: output_file }
        else
          { status: 'polling' }
        end
      end

      def generate(prompt, output_file, timeout: 600, asset_id: nil, async: false)
        receipt = AssetReceipt.new(asset_id: asset_id || "video_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        # Throttling
        @@launch_mutex.synchronize do
          if @@last_launch_at
            elapsed = Time.now - @@last_launch_at
            if elapsed < 2.0
              wait_time = 2.0 - elapsed
              puts Rainbow("  ⏳ [THROTTLE] Waiting #{wait_time.round(2)}s for next video launch...").yellow
              sleep(wait_time)
            end
          end
          @@last_launch_at = Time.now
        end

        puts Rainbow("  🎥 [VEO] Starting real video generation via Python script (Async: #{async})...").magenta
        
        # Call script
        escaped_prompt = prompt.gsub('"', '\"').gsub('`', '\`').gsub('$', '\$')
        async_flag = async ? "--async-only" : ""
        cmd = "uv run #{Config.veo_script} \"#{escaped_prompt}\" -o #{output_file} #{async_flag}"
        
        env = {
          'GOOGLE_CLOUD_PROJECT' => Config.google_cloud_project,
          'GOOGLE_CLOUD_REGION' => Config.google_cloud_region,
          'GENMEDIA_BUCKET' => Config.genmedia_bucket
        }

        operation_id = nil
        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Print stderr to show progress
            t_err = Thread.new do
              begin
                while line = stderr.gets
                  puts "    [VEO SCRIPT] #{line.strip}"
                end
              rescue IOError
                # Stream closed
              end
            end
            
            # Script outputs MEDIA:path on success or OPERATION_ID:id
            t_out = Thread.new do
              begin
                while line = stdout.gets
                  if line =~ /^MEDIA:(.*)$/
                    media_path = $1.strip
                    FileUtils.mkdir_p(File.dirname(output_file))
                    FileUtils.mv(media_path, output_file)
                    success = true
                  elsif line =~ /^OPERATION_ID:(.*)$/
                    operation_id = $1.strip
                    success = true
                  end
                end
              rescue IOError
                # Stream closed
              end
            end
            
            t_err.join
            t_out.join
            # Wait for process to exit
            success = wait_thr.value.success? if success.nil?
          end

          if async && operation_id
            puts Rainbow("  🔵 [VEO] Async operation started: #{operation_id}").blue
            return { status: 'polling', operation_id: operation_id }
          elsif success && File.exist?(output_file)
            puts Rainbow("  ✅ [VEO] Video generated successfully!").green
            receipt.complete!(cost_usd: Pricing::COST_PER_VEO_GEN)
            receipt.save!(output_file)
            return { status: 'done', tokens: 0, cost: Pricing::COST_PER_VEO_GEN, time: (Time.now - Time.parse(receipt.ts_started)).round(2) }
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [VEO] Script failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_VEO_VIDEO_FOR: #{prompt}")
          return { status: 'mocked', tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
