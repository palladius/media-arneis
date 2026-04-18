=begin
Arneis::Generator::Gemini - Media generator using Google Gemini via gemini-ai gem.
=end

require 'gemini-ai'

module Arneis
  module Generator
    class Gemini < Base
      def initialize(options = {})
        super
        @model = Models::GEMINI_FLASH
        @client = ::Gemini.new(
          credentials: {
            service: 'vertex-ai-api',
            project_id: Config.google_cloud_project,
            region: Config.google_cloud_region,
            version: 'v1'
          },
          options: { model: @model, server_sent_events: true }
        )
      end

      def generate(prompt, output_file = nil, system_instruction: nil, timeout: 30, asset_id: nil)
        puts "  [GEMINI] Generating text for prompt: '#{prompt[0..50]}...'"
        receipt = AssetReceipt.new(asset_id: asset_id || "text_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        payload = {
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
        }
        
        if system_instruction
          payload[:system_instruction] = { parts: [{ text: system_instruction }] }
        end

        begin
          response = with_retry { @client.generate_content(payload) }
          
          # Extract tokens
          usage = response.dig('usageMetadata') || {}
          in_t = usage['promptTokenCount'] || 0
          out_t = usage['candidatesTokenCount'] || 0
          cost = ((in_t + out_t).to_f / 1000) * Pricing::COST_PER_1K_TOKENS

          receipt.complete!(input_tokens: in_t, output_tokens: out_t, cost_usd: cost)
          receipt.save!(output_file) if output_file

          # Extract content
          content = response['candidates'][0]['content']['parts'][0]['text']
          
          { content: content, tokens: in_t + out_t, cost: cost, time: duration_from(receipt.ts_started) }
        rescue => e
          receipt.fail!(error_msg: e.message)
          receipt.save!(output_file) if output_file
          raise e
        end
      end

      private

      def duration_from(ts)
        (Time.now - Time.parse(ts)).round(2)
      end
    end
  end
end
