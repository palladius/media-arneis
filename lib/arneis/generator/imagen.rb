=begin
Arneis::Generator::Imagen - Media generator using Google Imagen via gemini-ai gem.
=end

require 'gemini-ai'

module Arneis
  module Generator
    class Imagen < Base
      def initialize(options = {})
        super
        @client = ::Gemini.new(
          credentials: {
            service: 'generative-language-api',
            api_key: Config.gemini_api_key,
            version: 'v1beta'
          },
          options: { model: Models::IMAGEN_DEFAULT }
        )
      end

      def generate(prompt, output_file, timeout: 20)
        puts Rainbow("  🎨 [IMAGEN] Starting image generation for prompt: '#{prompt[0..40]}...'").magenta
        start_time = Time.now
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }

        begin
          response = @client.generate_content(payload)
          duration = Time.now - start_time
          
          # Save receipt
          receipt_file = "#{output_file}.receipt.json"
          File.write(receipt_file, Config.sanitize(response.to_json))

          # Extract base64 data from response
          inline_data = response.dig('candidates', 0, 'content', 'parts', 0, 'inlineData')
          
          if inline_data && inline_data['data']
            puts Rainbow("  ⏳ [IMAGEN] Decoding and saving binary image to #{output_file}...").yellow
            binary_data = Base64.decode64(inline_data['data'])
            File.write(output_file, binary_data, mode: 'wb')
            puts Rainbow("  ✅ [IMAGEN] Real image generated: #{output_file}").green
          else
            puts Rainbow("  ⚠️ [IMAGEN] No image data found. Falling back to mock.").yellow
            File.write(output_file, "MOCK_IMAGEN_DATA")
          end
          
          tokens = response.dig('usageMetadata', 'totalTokenCount') || 0
          { 
            tokens: tokens,
            cost: Pricing::COST_PER_IMAGEN_GEN,
            time: duration
          }
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [IMAGEN] API call failed: #{sanitized_msg}. Falling back to mock.").yellow
          json_error = { error: sanitized_msg, prompt: prompt }.to_json
          File.write("#{output_file}.error.json", Config.sanitize(json_error))
          File.write(output_file, "MOCK_IMAGEN_DATA")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
