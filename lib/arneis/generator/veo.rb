=begin
Arneis::Generator::Veo - Media generator using Google Veo (Video).
Orchestrates generation via Hussain's Python script.
=end

require 'thread'
require 'open3'

module Arneis
  module Generator
    class Veo < Base
      @@last_launch_at = nil
      @@launch_mutex = Mutex.new

      def initialize(options = {})
        super
        @model = Models::VEO_DEFAULT
      end

      def generate(prompt, output_file, timeout: 600, asset_id: nil)
        receipt = AssetReceipt.new(asset_id: asset_id || "video_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        # Ensure at least 2 seconds between video launches to avoid rate limits
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

        puts Rainbow("  🎥 [VEO] Starting real video generation via Python script...").magenta
        
        # Call Hussain's script
        escaped_prompt = prompt.gsub('"', '\"')
        cmd = "python3 #{Config.veo_script} \"#{escaped_prompt}\""
        
        env = {
          'GOOGLE_CLOUD_PROJECT' => Config.google_cloud_project,
          'GOOGLE_CLOUD_REGION' => Config.google_cloud_region,
          'GENMEDIA_BUCKET' => Config.genmedia_bucket
        }

        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Print stderr to show polling progress
            Thread.new do
              while line = stderr.gets
                puts "    [VEO SCRIPT] #{line.strip}"
              end
            end
            
            # Look for MEDIA: path in stdout
            while line = stdout.gets
              if line =~ /^MEDIA:(.*)$/
                media_path = $1.strip
                puts Rainbow("  📥 Captured media path: #{media_path}").blue
                FileUtils.mkdir_p(File.dirname(output_file))
                FileUtils.mv(media_path, output_file)
                success = true
              end
            end
            
            success = wait_thr.value.success? if success.nil?
          end

          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [VEO] Video generated successfully!").green
            receipt.complete!(cost_usd: Pricing::COST_PER_VEO_GEN)
            receipt.save!(output_file)
            { tokens: 0, cost: Pricing::COST_PER_VEO_GEN, time: duration_from(receipt.ts_started) }
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [VEO] Script failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_VEO_VIDEO_FOR: #{prompt}")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end

      private

      def duration_from(ts)
        (Time.now - Time.parse(ts)).round(2)
      end
    end
  end
end
