# Arneis::Generator::Gif - Post-production tool using ffmpeg.
# Converts final MP4 videos to high-quality GIFs.

require "fileutils"

require_relative "base"

module Arneis
  module Generator
    class Gif < Base
      def initialize(options = {})
        super
      end

      def generate(input_file, output_file, asset_id: nil)
        puts Rainbow("  🎞️  [GIF] Generating high-quality GIF from #{File.basename(input_file)}...").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "gif_#{Time.now.to_i}", model: "ffmpeg", prompt: "GIF Conversion")
        start_time = Time.now

        unless File.exist?(input_file)
          puts Rainbow("    ⚠️  Input file not found: #{input_file}. Mocking GIF.").yellow
          receipt.fail!(error_msg: "Input file missing")
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_GIF_DATA_FOR: #{input_file}")
          return {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end

        # ffmpeg command for high-quality GIF
        # 1. Generate palette
        # 2. Convert using palette
        palette = "palette.png"
        filters = "fps=15,scale=640:-1:flags=lanczos"

        cmd = "ffmpeg -v warning -i \"#{input_file}\" -vf \"#{filters},palettegen\" -y \"#{palette}\" && " +
          "ffmpeg -v warning -i \"#{input_file}\" -i \"#{palette}\" -lavfi \"#{filters} [x]; [x][1:v] paletteuse\" -y \"#{output_file}\""

        begin
          success = system(cmd)
          FileUtils.rm_f(palette) if File.exist?(palette)

          if success && File.exist?(output_file)
            puts Rainbow("  ✅ [GIF] GIF generated successfully!").green
            receipt.complete!(cost_usd: 0.0)
            receipt.save!(output_file)

            # Validate
            Validator.validate_and_rename!(output_file, :image) # GIFs are validated as images (header checks)

            {status: "done", tokens: 0, cost: 0.0, time: (Time.now - start_time).round(2)}
          else
            raise "ffmpeg execution failed"
          end
        rescue => e
          puts Rainbow("    ⚠️  GIF generation failed: #{e.message}. Falling back to mock.").yellow
          receipt.fail!(error_msg: e.message)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_GIF_DATA")
          {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end
      end
    end
  end
end
