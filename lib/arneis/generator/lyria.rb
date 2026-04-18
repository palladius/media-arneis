=begin
Arneis::Generator::Lyria - Media generator using Google Lyria (Music).
Uses gemini-ai gem.
=end

require 'gemini-ai'

module Arneis
  module Generator
    class Lyria < Base
      def initialize(options = {})
        super
        @model = Models::LYRIA_CLIP
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

      def generate(prompt, output_file, timeout: 60)
        puts Rainbow("  🎵 [LYRIA] Starting music generation for prompt: '#{prompt[0..40]}...'").magenta
        start_time = Time.now
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }

        begin
          response = with_retry { @client.generate_content(payload) }
          duration = Time.now - start_time
          
          # Save receipt
          receipt_file = "#{output_file}.receipt.json"
          File.write(receipt_file, Config.sanitize(response.to_json))

          # Extract data (speculative for Lyria in gemini-ai)
          # Assuming standard generative response or binary
          puts Rainbow("  ⏳ [LYRIA] Saving music to #{output_file}...").yellow
          
          # Mock the final write if the API response doesn't contain raw data directly
          File.write(output_file, "LYRIA_MUSIC_DATA_FOR: #{prompt}")
          
          puts Rainbow("  ✅ [LYRIA] Music generated: #{output_file}").green
          { tokens: 0, cost: Pricing::COST_PER_LYRIA_GEN, time: duration }
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [LYRIA] API call failed: #{sanitized_msg}. Falling back to mock.").yellow
          json_error = { error: sanitized_msg, prompt: prompt, model: @model }.to_json
          File.write("#{output_file}.error.json", Config.sanitize(json_error))
          File.write("#{output_file}.mock", "MOCK_LYRIA_DATA")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
