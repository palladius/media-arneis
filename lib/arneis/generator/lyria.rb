=begin
Arneis::Generator::Lyria - Media generator using Google Lyria (Music).
Orchestrates generation via the util/generate_music.py script.
=end

require 'thread'
require 'open3'
require 'fileutils'

module Arneis
  module Generator
    class Lyria < Base
      def initialize(options = {})
        super
        @model = Models::LYRIA_CLIP
      end

      def generate(prompt, output_file, timeout: 300, asset_id: nil)
        puts Rainbow("  🎵 [LYRIA] Starting real music generation via Python script...").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "music_#{Time.now.to_i}", model: @model, prompt: prompt)
        start_time = Time.now
        
        # Call Lyria script (uv run)
        escaped_prompt = prompt.gsub('"', '\"')
        cmd = "uv run util/generate_music.py --prompt \"#{escaped_prompt}\" -o #{output_file}"
        
        env = {
          'GOOGLE_CLOUD_PROJECT' => Config.google_cloud_project,
          'GOOGLE_CLOUD_REGION' => Config.google_cloud_region
        }

        begin
          success = false
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            
            # Print stderr to show progress
            t_err = Thread.new do
              while line = stderr.gets
                puts "    [LYRIA SCRIPT] #{line.strip}"
              end
            end
            
            # Script outputs MEDIA:path on success
            t_out = Thread.new do
              while line = stdout.gets
                if line =~ /^MEDIA:(.*)$/
                  success = true
                end
              end
            end
            
            t_err.join
            t_out.join
            
            success = wait_thr.value.success? if success.nil?
          end

          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [LYRIA] Music generated successfully!").green
            receipt.complete!(cost_usd: Pricing::COST_PER_LYRIA_GEN)
            receipt.save!(output_file)
            
            # Validate and Rename
            Validator.validate_and_rename!(output_file, :audio)
            
            { tokens: 0, cost: Pricing::COST_PER_LYRIA_GEN, time: (Time.now - start_time).round(2) }
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [LYRIA] Script failed: #{sanitized_msg}. Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_LYRIA_DATA: #{prompt}")
          return { tokens: 0, cost: 0.0, time: 0 }
        end
      end
    end
  end
end
