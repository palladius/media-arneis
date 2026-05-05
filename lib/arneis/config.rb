# Arneis::Config - Manages configuration and environment variables.

require "dotenv"

module Arneis
  class Config
    def self.load!
      Dotenv.load(".env")
    end

    def self.gemini_api_key
      ENV["GEMINI_API_KEY"] || raise("Missing GEMINI_API_KEY environment variable")
    end

    def self.google_cloud_project
      ENV["GOOGLE_CLOUD_PROJECT"] || raise("Missing GOOGLE_CLOUD_PROJECT environment variable")
    end

    def self.google_cloud_region
      ENV["GOOGLE_CLOUD_REGION"] || "us-central1"
    end

    def self.veo_script
      "util/generate_video.py"
    end

    def self.imagen_script
      "util/generate_image.py"
    end

    def self.lyria_script
      "util/generate_music.py"
    end

    def self.genmedia_bucket
      ENV["GENMEDIA_BUCKET"] || raise("Missing GENMEDIA_BUCKET environment variable")
    end

    def self.max_concurrent_tasks
      (ENV["MAX_CONCURRENT_TASKS"] || 5).to_i
    end

    def self.auth_method_emoji
      (ENV["GOOGLE_APPLICATION_CREDENTIALS"] || system("gcloud auth application-default print-access-token > /dev/null 2>&1")) ? "☁️ (Vertex)" : "🔑 (ApiKey)"
    end

    class << self
      attr_accessor :dryrun
    end

    def self.dryrun?
      !!@dryrun
    end

    def self.no_mock?
      return false if dryrun?
      ENV["ARNEIS_NO_MOCK"] == "true" || ENV["ARNEIS_NO_MOCK"] == "1"
    end

    def self.eval_enabled?(flags = {})
      return flags[:eval] unless flags[:eval].nil?

      env_val = ENV["ARNEIS_EVAL_ENABLED"] || ENV["EVAL"]
      return env_val == "true" unless env_val.nil?

      true # Default
    end

    def self.open_enabled?(flags = {})
      return flags[:open] unless flags[:open].nil?

      env_val = ENV["ARNEIS_OPEN_ENABLED"] || ENV["OPEN"]
      return env_val == "true" unless env_val.nil?

      true # Default
    end

    def self.sanitize(text)
      return text unless text.is_a?(String)

      key = ENV["GEMINI_API_KEY"]
      text = text.gsub(key, "[REDACTED_KEY]") if key && !key.empty?

      project = ENV["GOOGLE_CLOUD_PROJECT"]
      text = text.gsub(project, "[REDACTED_PROJECT]") if project && !project.empty?

      bucket = ENV["GENMEDIA_BUCKET"]
      text = text.gsub(bucket, "[REDACTED_BUCKET]") if bucket && !bucket.empty?

      region = ENV["GOOGLE_CLOUD_REGION"]
      text = text.gsub(region, "[REDACTED_REGION]") if region && !region.empty?

      text
    end
  end
end
