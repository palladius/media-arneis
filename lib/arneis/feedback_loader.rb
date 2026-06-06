# Arneis::FeedbackLoader - Parses previous run results to extract evaluation feedback.

require "json"
require "yaml"

module Arneis
  class FeedbackLoader
    def self.load(folder_path)
      unless Dir.exist?(folder_path)
        raise "Directory does not exist: #{folder_path}"
      end

      state_file = File.join(folder_path, ".state.yaml")
      state = File.exist?(state_file) ? YAML.load_file(state_file) : {}

      original_command = state["original_command"]
      original_prompt = state["prompt"]

      # Find all *.asset.json files recursively
      asset_jsons = Dir.glob(File.join(folder_path, "**", "*.asset.json"))

      eval_errors = []
      previous_image = nil

      asset_jsons.each do |json_path|
        data = JSON.parse(File.read(json_path))

        # Extract verification errors
        if data["verification"].is_a?(Array)
          failures = data["verification"].reject { |v| v["success"] }
          failures.each do |f|
            eval_errors << f["message"]
          end
        end

        # Grab prompt
        if data["prompt"] && !data["prompt"].empty?
          original_prompt ||= data["prompt"]
        end

        # Identify previous generated image
        asset_path = json_path.sub(/\.asset\.json$/, "")
        if File.exist?(asset_path) && [".png", ".jpg", ".jpeg"].include?(File.extname(asset_path).downcase)
          previous_image ||= asset_path
        end
      rescue
        # Ignore malformed files
      end

      {
        original_command: original_command,
        original_prompt: original_prompt,
        eval_errors: eval_errors,
        previous_image: previous_image
      }
    end
  end
end
