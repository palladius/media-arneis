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

    def self.sanitize(text)
      return text unless text.is_a?(String)
      
      key = ENV['GEMINI_API_KEY']
      text = text.gsub(key, "[REDACTED_KEY]") if key && !key.empty?
      
      project = ENV['GOOGLE_CLOUD_PROJECT']
      text = text.gsub(project, "[REDACTED_PROJECT]") if project && !project.empty?
      
      text
    end
  end
end
