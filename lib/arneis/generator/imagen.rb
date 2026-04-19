=begin
Arneis::Generator::Imagen - Media generator using Google Imagen via gemini-ai gem.
=end

require 'open3'
require 'fileutils'

module Arneis
  module Generator
    class Imagen < Base
      def initialize(options = {})
        super
        @model = Models::IMAGEN_DEFAULT
      end

      def generate(prompt, output_file, timeout: 60, asset_id: nil)
        puts Rainbow("  🎨 [IMAGEN] Starting image generation via Python script...").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "image_#{Time.now.to_i}", model: @model, prompt: prompt)
        
        # Prepare command
        escaped_prompt = prompt.gsub('"', '\"')
        cmd = "uv run #{Config.imagen_script} --prompt \"#{escaped_prompt}\" --filename #{output_file}"
        
        env = {
          'GEMINI_API_KEY' => Config.gemini_api_key,
          'NANOBANANA_OUTPUT_FOLDER' => '' # We want it to use the absolute or relative path provided in --filename
        }

        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Capture output
            t_err = Thread.new do
              while line = stderr.gets
                puts "    [IMAGEN SCRIPT] #{line.strip}"
              end
            end
            
            t_out = Thread.new do
              while line = stdout.gets
                if line =~ /^MEDIA:(.*)$/
                  media_path = $1.strip
                  puts Rainbow("  📥 Captured image path: #{media_path}").blue
                  # Note: the script might save to a different path if NANOBANANA_OUTPUT_FOLDER was set,
                  # but here we pass the exact output_file to --filename.
                  success = true
                end
              end
            end
            
            t_err.join
            t_out.join
            
            success = wait_thr.value.success? if success.nil?
          end

          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [IMAGEN] Image generated successfully!").green
            receipt.complete!(cost_usd: Pricing::COST_PER_IMAGEN_GEN)
            receipt.save!(output_file)
            { tokens: 0, cost: Pricing::COST_PER_IMAGEN_GEN, time: duration_from(receipt.ts_started) }
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [IMAGEN] Script failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_IMAGEN_DATA_FOR: #{prompt}")
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
