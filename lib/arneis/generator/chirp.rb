# Arneis::Generator::Chirp - Media generator using Google Chirp (TTS).
# Orchestrates generation via a TTS API call.

require "open3"
require "fileutils"

module Arneis
  module Generator
    class Chirp < Base
      def initialize(options = {})
        super
        @model = Models::CHIRP_2 # Default to Chirp 2
      end

      def generate(text, output_file, language_code: "en-US", voice_id: nil, asset_id: nil)
        puts Rainbow("  🗣️  [CHIRP] Generating audio for language #{language_code}...").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "audio_#{Time.now.to_i}", model: @model, prompt: text[0..100])
        start_time = Time.now

        # For now, we will use a mock implementation if the real script is missing, 
        # or a very simple command.
        
        # Consistent voice mapping
        voice_id ||= case language_code
        when /^en/ then "en-US-Standard-B"
        when /^it/ then "it-IT-Standard-A"
        when /^jp/ then "ja-JP-Standard-C"
        else "en-US-Standard-B"
        end

        # We'll assume there is a util/generate_audio.py similar to others
        escaped_text = text.gsub('"', '\"').gsub("`", '\`').gsub("$", '\$')
        cmd = "uv run util/generate_audio.py --text \"#{escaped_text}\" --lang \"#{language_code}\" --voice \"#{voice_id}\" -o #{output_file}"

        # If util/generate_audio.py doesn't exist, we'll simulate success for now if in development
        unless File.exist?("util/generate_audio.py")
          puts Rainbow("  ⚠️ [CHIRP] util/generate_audio.py missing. Mocking success for development.").yellow
          File.write(output_file, "MOCK AUDIO DATA")
          File.write("#{output_file}.mock", "MOCK_CHIRP_DATA: #{text}")
          return {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end

        env = {
          "GOOGLE_CLOUD_PROJECT" => Config.google_cloud_project,
          "GOOGLE_CLOUD_REGION" => Config.google_cloud_region
        }

        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            t_err = Thread.new { while line = stderr.gets; puts "    [CHIRP SCRIPT] #{line.strip}"; end rescue nil }
            t_out = Thread.new { while line = stdout.gets; success = true if /^MEDIA:(.*)$/.match?(line); end rescue nil }
            t_err.join; t_out.join
            success = wait_thr.value.success? if success.nil?
          end

          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [CHIRP] Audio generated successfully!").green
            receipt.complete!(cost_usd: 0.01) # Approximate cost
            receipt.save!(output_file)
            Validator.validate_and_rename!(output_file, :audio)
            {status: "done", tokens: 0, cost: 0.01, time: (Time.now - start_time).round(2)}
          else
            raise "Chirp script failed"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [CHIRP] Failed: #{sanitized_msg}").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_CHIRP_DATA: #{text}")
          {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end
      end
    end
  end
end
