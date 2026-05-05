# Arneis::Generator::Gemini - Media generator using Google Gemini via gemini-ai gem.

require "gemini-ai"
require "base64"

module Arneis
  module Generator
    class Gemini < Base
      def initialize(options = {})
        super
        @model = Models::MAIN
        @client = ::Gemini.new(
          credentials: {
            service: "vertex-ai-api",
            project_id: Config.google_cloud_project,
            region: Config.google_cloud_region,
            version: "v1"
          },
          options: {model: @model, server_sent_events: true}
        )
      end

      def generate(prompt, output_file = nil, system_instruction: nil, images: [], audio: [], timeout: 30, asset_id: nil)
        if dryrun?
          puts Rainbow("  🌵 [DRYRUN] Mocking GEMINI for prompt: #{prompt[0..50]}...").yellow
          return {content: "Mock GEMINI response for: #{prompt}", tokens: 10, cost: 0.0, time: 0.1}
        end
        
        puts "  [GEMINI] Generating #{images.empty? && audio.empty? ? "text" : "multimodal response"} for prompt: '#{prompt[0..100]}#{prompt.length > 100 ? "..." : ""}'"
        receipt = AssetReceipt.new(asset_id: asset_id || "text_#{Time.now.to_i}", model: @model, prompt: prompt)

        parts = [{text: prompt}]
        images.each do |img_path|
          next unless File.exist?(img_path)
          ext = File.extname(img_path).downcase.delete(".")
          mime_type = case ext
          when "png" then "image/png"
          when "jpg", "jpeg" then "image/jpeg"
          else "image/png"
          end
          parts << {inline_data: {mime_type: mime_type, data: Base64.strict_encode64(File.read(img_path))}}
        end

        audio.each do |aud_path|
          next unless File.exist?(aud_path)
          ext = File.extname(aud_path).downcase.delete(".")
          mime_type = case ext
          when "wav" then "audio/wav"
          when "mp3" then "audio/mpeg"
          else "audio/wav"
          end
          parts << {inline_data: {mime_type: mime_type, data: Base64.strict_encode64(File.read(aud_path))}}
        end

        payload = {
          contents: [{role: "user", parts: parts}]
        }

        if system_instruction
          payload[:system_instruction] = {parts: [{text: system_instruction}]}
        end

        begin
          response = with_retry { @client.generate_content(payload) }

          # Extract tokens
          usage = response.dig("usageMetadata") || {}
          in_t = usage["promptTokenCount"] || 0
          out_t = usage["candidatesTokenCount"] || 0
          cost = ((in_t + out_t).to_f / 1000) * Pricing::COST_PER_1K_TOKENS

          receipt.complete!(input_tokens: in_t, output_tokens: out_t, cost_usd: cost)
          receipt.save!(output_file) if output_file

          # Extract content
          content = response["candidates"][0]["content"]["parts"][0]["text"]

          {content: content, tokens: in_t + out_t, cost: cost, time: duration_from(receipt.ts_started)}
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
