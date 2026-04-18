require 'gemini-ai'
require 'dotenv'
Dotenv.load('.env')

client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GEMINI_API_KEY'],
    version: 'v1beta'
  },
  options: { model: 'gemini-1.5-flash' }
)

begin
  models = client.models
  puts "Models response: #{models.inspect}"
rescue => e
  puts "Error: #{e.message}"
end
