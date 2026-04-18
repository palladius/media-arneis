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
      ENV['GOOGLE_CLOUD_PROJECT'] || 'ric-cccwiki'
    end

    def self.sanitize(text)
      return text unless text.is_a?(String)
      key = ENV['GEMINI_API_KEY']
      return text if key.nil? || key.empty?
      text.gsub(key, "[REDACTED]")
    end
  end
end
