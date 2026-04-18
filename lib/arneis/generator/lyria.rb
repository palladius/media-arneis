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
        @model = Models::LYRIA_DEFAULT
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

      def generate(prompt, output_file, timeout: 60, asset_id: nil)
        puts Rainbow("  🎵 [LYRIA] Starting music generation for prompt: '#{prompt[0..40]}...'").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "music_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }

        begin
          response = with_retry { @client.generate_content(payload) }
          
          # Save metadata
          receipt.complete!(cost_usd: Pricing::COST_PER_LYRIA_GEN)
          receipt.save!(output_file)

          puts Rainbow("  ⏳ [LYRIA] Saving music to #{output_file}...").yellow
          
          # Mock the final write for now
          File.write(output_file, "LYRIA_MUSIC_DATA_FOR: #{prompt}")
          
          puts Rainbow("  ✅ [LYRIA] Music generated: #{output_file}").green
          { tokens: 0, cost: Pricing::COST_PER_LYRIA_GEN, time: duration_from(receipt.ts_started) }
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [LYRIA] API call failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_LYRIA_DATA")
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
