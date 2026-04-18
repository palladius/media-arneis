require 'ruby_llm'

RubyLLM.configure do |config|
  config.gemini_api_key = ENV['GEMINI_API_KEY']
end

begin
  RubyLLM.models.refresh!
  models = RubyLLM.models.all
  gemini_models = models.select { |m| m.provider == :google }
  puts "Available Gemini models:"
  gemini_models.each do |m|
    puts "- #{m.id}"
  end
rescue => e
  puts "Error: #{e.message}"
end
