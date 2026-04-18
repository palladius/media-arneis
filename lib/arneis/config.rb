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
  end
end
