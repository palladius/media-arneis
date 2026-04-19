=begin
Arneis::Config - Manages configuration and environment variables.
=end

require 'dotenv'

module Arneis
  class Config
    def self.load!
      Dotenv.load('.env')
    end

    def self.gemini_api_key
      ENV['GEMINI_API_KEY'] || raise("Missing GEMINI_API_KEY environment variable")
    end

    def self.google_cloud_project
      ENV['GOOGLE_CLOUD_PROJECT'] || raise("Missing GOOGLE_CLOUD_PROJECT environment variable")
    end

    def self.google_cloud_region
      ENV['GOOGLE_CLOUD_REGION'] || 'us-central1'
    end

    def self.veo_script
      'util/generate_video.py'
    end

    def self.lyria_script
      'util/generate_music.py'
    end

    def self.genmedia_bucket
      ENV['GENMEDIA_BUCKET'] || raise("Missing GENMEDIA_BUCKET environment variable")
    end

    def self.auth_method_emoji
      ENV['GOOGLE_APPLICATION_CREDENTIALS'] || system("gcloud auth application-default print-access-token > /dev/null 2>&1") ? "☁️ (Vertex)" : "🔑 (ApiKey)"
    end

    def self.sanitize(text)
      return text unless text.is_a?(String)
      
      key = ENV['GEMINI_API_KEY']
      text = text.gsub(key, "[REDACTED_KEY]") if key && !key.empty?
      
      project = ENV['GOOGLE_CLOUD_PROJECT']
      text = text.gsub(project, "[REDACTED_PROJECT]") if project && !project.empty?

      bucket = ENV['GENMEDIA_BUCKET']
      text = text.gsub(bucket, "[REDACTED_BUCKET]") if bucket && !bucket.empty?

      region = ENV['GOOGLE_CLOUD_REGION']
      text = text.gsub(region, "[REDACTED_REGION]") if region && !region.empty?
      
      text
    end
  end
end
