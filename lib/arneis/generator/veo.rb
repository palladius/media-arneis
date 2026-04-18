=begin
Arneis::Generator::Veo - Media generator using Google Veo (Video).
Orchestrates generation via Hussain's Python script.
=end

require 'thread'

module Arneis
  module Generator
    class Veo < Base
      @@last_launch_at = nil
      @@launch_mutex = Mutex.new

      def initialize(options = {})
        super
        @model = Models::VEO_DEFAULT
      end

      def generate(prompt, output_file, timeout: 600)
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
        start_time = Time.now
        
        # Call Hussain's script
        # Escape double quotes in prompt
        escaped_prompt = prompt.gsub('"', '\"')
        cmd = "python3 #{Config.veo_script} \"#{escaped_prompt}\""
        
        env = {
          'GOOGLE_CLOUD_PROJECT' => Config.google_cloud_project,
          'GOOGLE_CLOUD_REGION' => Config.google_cloud_region,
          'GENMEDIA_BUCKET' => Config.genmedia_bucket
        }

        begin
          # Use popen3 to capture stdout separately from stderr (which has polling logs)
          require 'open3'
          
          # The script expects prompt as first argument
          # We don't use -o as it's not supported, but we'll move the result
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Print stderr to show polling progress in real-time
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

          duration = Time.now - start_time
          
          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [VEO] Video generated successfully!").green
            { tokens: 0, cost: Pricing::COST_PER_VEO_GEN, time: duration }
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [VEO] Script failed: #{sanitized_msg}. Falling back to mock.").yellow
          json_error = { error: sanitized_msg, prompt: prompt, model: @model }.to_json
          File.write("#{output_file}.error.json", Config.sanitize(json_error))
          File.write("#{output_file}.mock", "MOCK_VEO_VIDEO_FOR: #{prompt}")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
