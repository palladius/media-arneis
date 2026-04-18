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

      def generate(prompt, _output_file = nil, system_instruction: nil)
        puts "  [GEMINI] Generating text for prompt: '#{prompt[0..50]}...'"
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }
        
        if system_instruction
          payload[:system_instruction] = { parts: [{ text: system_instruction }] }
        end

        response = @client.generate_content(payload)
        
        # Extract content from response
        content = response['candidates'][0]['content']['parts'][0]['text']
        
        { 
          content: content,
          # gemini-ai response structure for tokens/usage
          tokens: response.dig('usageMetadata', 'totalTokenCount') || 0,
          time: 0 # gemini-ai doesn't seem to provide latency directly
        }
      end
    end
  end
end
