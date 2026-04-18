=begin
Arneis::Generator::Imagen - Media generator using Google Imagen via gemini-ai gem.
=end

require 'gemini-ai'
require 'base64'

module Arneis
  module Generator
    class Imagen < Base
      def initialize(options = {})
        super
        @model = Models::IMAGEN_DEFAULT
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

      def generate(prompt, output_file, timeout: 20, asset_id: nil)
        puts Rainbow("  🎨 [IMAGEN] Starting image generation for prompt: '#{prompt[0..40]}...'").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "image_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }

        begin
          response = @client.generate_content(payload)
          
          # Extract base64 data from response
          inline_data = response.dig('candidates', 0, 'content', 'parts', 0, 'inlineData')
          
          if inline_data && inline_data['data']
            puts Rainbow("  ⏳ [IMAGEN] Decoding and saving binary image to #{output_file}...").yellow
            binary_data = Base64.decode64(inline_data['data'])
            File.write(output_file, binary_data, mode: 'wb')
            puts Rainbow("  ✅ [IMAGEN] Real image generated: #{output_file}").green
            
            tokens = response.dig('usageMetadata', 'totalTokenCount') || 0
            receipt.complete!(input_tokens: response.dig('usageMetadata', 'promptTokenCount') || 0, 
                             output_tokens: response.dig('usageMetadata', 'candidatesTokenCount') || 0, 
                             cost_usd: Pricing::COST_PER_IMAGEN_GEN)
            receipt.save!(output_file)
            
            { tokens: tokens, cost: Pricing::COST_PER_IMAGEN_GEN, time: duration_from(receipt.ts_started) }
          else
            raise "No image data found in response"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [IMAGEN] API call failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_IMAGEN_DATA")
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
