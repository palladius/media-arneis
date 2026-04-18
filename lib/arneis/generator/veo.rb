=begin
Arneis::Generator::Veo - Media generator using Google Veo (Video).
Uses gemini-ai gem to interact with Vertex AI / Generative Language API.
=end

require 'gemini-ai'

module Arneis
  module Generator
    class Veo < Base
      @@last_launch_at = nil
      @@launch_mutex = Mutex.new

      def initialize(options = {})
        super
        @model = Models::VEO_2
        @client = ::Gemini.new(
          credentials: {
            service: 'vertex-ai-api',
            project_id: Config.google_cloud_project,
            region: Config.google_cloud_region,
            version: 'v1'
          },
          options: { model: @model }
        )
      end

      def generate(prompt, output_file, timeout: 90)
        # Ensure at least 2 seconds between video launches
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

        puts Rainbow("  🎥 [VEO] Starting video generation for prompt: '#{prompt[0..40]}...'").magenta
        start_time = Time.now
        
        payload = {
          instances: [{ prompt: prompt }],
          parameters: { sampleCount: 1 }
        }

        # Use predict for Veo on Vertex AI
        begin
          response = with_retry { @client.predict(payload) }
          duration = Time.now - start_time
          receipt_file = "#{output_file}.receipt.json"
          File.write(receipt_file, Config.sanitize(response.to_json))
          
          # Veo logic usually involves polling for long-running jobs.
          # For this MVP, we simulate the polling while the request is blocking.
          puts Rainbow("  ⏳ [VEO] Video generation in progress...").yellow
          
          { 
            tokens: 0, 
            cost: Pricing::COST_PER_VEO_GEN, 
            time: duration 
          }
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [VEO] Real API call failed: #{sanitized_msg}. Falling back to mock for this scene.").yellow
          json_error = { error: sanitized_msg, prompt: prompt, model: @model }.to_json
          File.write("#{output_file}.error.json", Config.sanitize(json_error))
          File.write("#{output_file}.mock", "MOCK_VEO_VIDEO_FOR: #{prompt}")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
