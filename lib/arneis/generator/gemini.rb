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

      def generate(prompt, output_file = nil, system_instruction: nil, timeout: 30)
        puts "  [GEMINI] Generating text for prompt: '#{prompt[0..50]}...'"
        start_time = Time.now
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }
        
        if system_instruction
          payload[:system_instruction] = { parts: [{ text: system_instruction }] }
        end

        begin
          # gemini-ai gem doesn't support timeout per request directly in initialize, 
          # so we use Ruby's Timeout if needed, but for now assuming Faraday handles it.
          response = @client.generate_content(payload)
          duration = Time.now - start_time
          
          # Save metadata if output_file is provided
          if output_file
            receipt_file = "#{output_file}.receipt.json"
            File.write(receipt_file, Config.sanitize(response.to_json))
          end

          # Extract content from response
          content = response['candidates'][0]['content']['parts'][0]['text']
          tokens = response.dig('usageMetadata', 'totalTokenCount') || 0
          
          { 
            content: content,
            tokens: tokens,
            cost: (tokens.to_f / 1000) * Pricing::COST_PER_1K_TOKENS,
            time: duration
          }
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ❌ [GEMINI] Error: #{sanitized_msg}").red
          if output_file
            json_error = { error: sanitized_msg, prompt: prompt }.to_json
            File.write("#{output_file}.error.json", Config.sanitize(json_error))
          end
          raise e
        end
      end
    end
  end
end
