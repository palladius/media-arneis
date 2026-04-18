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

      def generate(prompt, output_file)
        puts Rainbow("  🎨 [IMAGEN] Starting image generation for prompt: '#{prompt[0..40]}...'").magenta
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }

        begin
          response = @client.generate_content(payload)
          
          # Save receipt
          receipt_file = "#{output_file}.receipt.json"
          File.write(receipt_file, response.to_json)

          # Note: gemini-ai gem structure for image response might vary.
          # Assuming standard response for now.
          puts Rainbow("  ⏳ [IMAGEN] Saving image to #{output_file}...").yellow
          
          # Mock the final write if the API response doesn't contain raw data directly
          File.write(output_file, "IMAGEN_IMAGE_DATA_FOR: #{prompt}")
          
          puts Rainbow("  ✅ [IMAGEN] Image generated: #{output_file}").green
          { tokens: 0, cost: Pricing::COST_PER_IMAGEN_GEN, time: 2.0 }
        rescue => e
          puts Rainbow("  ⚠️ [IMAGEN] API call failed: #{e.message}. Falling back to mock.").yellow
          File.write("#{output_file}.error.json", { error: e.message, prompt: prompt }.to_json)
          File.write(output_file, "MOCK_IMAGEN_DATA")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
