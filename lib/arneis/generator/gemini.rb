=begin
Arneis::Generator::Gemini - Media generator using Google Gemini via gemini-ai gem.
=end

require 'gemini-ai'

module Arneis
  module Generator
    class Gemini < Base
      def initialize(options = {})
        super
        @client = ::Gemini.new(
          credentials: {
            service: 'generative-language-api',
            api_key: Config.gemini_api_key,
            version: 'v1beta'
          },
          options: { model: 'gemini-2.5-flash', server_sent_events: true }
        )
      end

      def generate(prompt, output_file = nil, system_instruction: nil)
        puts "  [GEMINI] Generating text for prompt: '#{prompt[0..50]}...'"
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }
        
        if system_instruction
          payload[:system_instruction] = { parts: [{ text: system_instruction }] }
        end

        begin
          response = @client.generate_content(payload)
          
          # Save metadata if output_file is provided
          if output_file
            receipt_file = "#{output_file}.receipt.json"
            File.write(receipt_file, response.to_json)
          end

          # Extract content from response
          content = response['candidates'][0]['content']['parts'][0]['text']
          
          { 
            content: content,
            tokens: response.dig('usageMetadata', 'totalTokenCount') || 0,
            time: 0
          }
        rescue => e
          puts Rainbow("  ❌ [GEMINI] Error: #{e.message}").red
          # Save error to receipt if possible
          if output_file
            File.write("#{output_file}.error.json", { error: e.message, prompt: prompt }.to_json)
          end
          raise e
        end
      end
    end
  end
end
