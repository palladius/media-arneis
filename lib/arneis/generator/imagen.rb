# Arneis::Generator::Imagen - Media generator using Google Imagen (Image).
# Orchestrates generation via the util/generate_image.py script.

require "open3"
require "fileutils"
require "shellwords"

module Arneis
  module Generator
    class Imagen < Base
      def initialize(options = {})
        super
        @model = Models::IMAGEN_DEFAULT
      end

      def generate(prompt, output_file, timeout: 300, asset_id: nil, aspect_ratio: "1:1", reference_images: nil)
        return maybe_mock(output_file, :image, prompt) if dryrun?
        
        puts Rainbow("  🎨 [IMAGEN] Starting real image generation via Python script (AR: #{aspect_ratio})...").magenta
        puts Rainbow("  👤 [CONSISTENCY] Using reference images: #{reference_images}").cyan if reference_images
        receipt = AssetReceipt.new(asset_id: asset_id || "image_#{Time.now.to_i}", model: @model, prompt: prompt)
        start_time = Time.now

        # Call Imagen script (uv run)
        cmd_args = ["uv", "run", "util/generate_image.py", "-p", prompt, "-o", output_file, "--aspect-ratio", aspect_ratio, "-m", @model]
        if reference_images&.any?
          cmd_args.concat(["-i", *reference_images])
        end

        env = {
          "GOOGLE_CLOUD_PROJECT" => Config.google_cloud_project,
          "GOOGLE_CLOUD_REGION" => Config.google_cloud_region,
          "GEMINI_API_KEY" => ENV["GEMINI_API_KEY"]
        }

        begin
          success = false
          Open3.popen3(env, *cmd_args) do |stdin, stdout, stderr, wait_thr|
            stdin.close

            # Print stderr to show progress
            t_err = Thread.new do
              begin
                while line = stderr.gets
                  puts "    [IMAGEN SCRIPT] #{line.strip}"
                end
              rescue IOError
              end
            end

            t_out = Thread.new do
              begin
                while line = stdout.gets
                  if /^MEDIA:(.*)$/.match?(line)
                    success = true
                  end
                end
              rescue IOError
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

            # Validate and Rename
            Validator.validate_and_rename!(output_file, :image)

            {status: "done", tokens: 0, cost: Pricing::COST_PER_IMAGEN_GEN, time: (Time.now - start_time).round(2)}
          else
            raise "Python script execution failed or output missing"
          end
        rescue => e
          sanitized_msg = Config.sanitize(e.message)
          puts Rainbow("  ⚠️ [IMAGEN] Script failed: #{sanitized_msg}").yellow

          if Config.no_mock?
            puts Rainbow("  🚫 Mocking disabled. Raising error.").red
            raise e
          end

          puts Rainbow("  🤡 Falling back to mock.").yellow
          receipt.fail!(error_msg: sanitized_msg)
          receipt.save!(output_file)
          File.write("#{output_file}.mock", "MOCK_IMAGEN_DATA: #{prompt}")
          {status: "mocked", tokens: 0, cost: 0.0, time: 0}
        end
      end

      private

      def duration_from(ts)
        (Time.now - Time.parse(ts)).round(2)
      end
    end
  end
end
