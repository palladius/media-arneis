require 'gemini-ai'
require 'dotenv'
Dotenv.load('.env')

client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GEMINI_API_KEY'],
    version: 'v1beta'
  },
  options: { model: 'gemini-2.5-flash' }
)

begin
  puts "Testing gemini-2.5-flash..."
  response = client.generate_content({
    contents: [{ role: 'user', parts: [{ text: "Hello! Confirm you are working." }] }]
  })
  puts "Response: #{response['candidates'][0]['content']['parts'][0]['text']}"
  puts "Usage: #{response['usageMetadata'].inspect}"
rescue => e
  puts "Error with 2.5 flash: #{e.message}"
end
