# Arneis::Generator::Marketing - Orchestrates platform-specific marketing asset generation.
# Uses MarketingConfig for prompts and Imagen for creation.

require "fileutils"

module Arneis
  module Generator
    class Marketing < Base
      def initialize(options = {})
        super
        @imagen = Imagen.new
      end

      def generate_all(project_title, context, output_dir)
        FileUtils.mkdir_p(output_dir)
        results = {}

        MarketingConfig::PLATFORMS.each_key do |platform|
          output_file = File.join(output_dir, "#{MarketingConfig::PLATFORMS[platform][:suffix]}.png")
          prompt = MarketingConfig.prompt_for(platform, project_title, context)
          aspect_ratio = MarketingConfig::PLATFORMS[platform][:aspect_ratio]

          puts Rainbow("  📢 [MARKETING] Generating #{platform} asset...").cyan
          res = @imagen.generate(prompt, output_file, asset_id: "Marketing.#{platform}", aspect_ratio: aspect_ratio)
          results[platform] = res
        end

        results
      end
    end
  end
end
