#!/usr/bin/env ruby

require "ruby_llm"
require "json"
require "dotenv"
Dotenv.load 

# This script transcribes an audio file using RubyLLM (which uses Google Gemini behind the scenes).
#
# Usage:
#   ruby util/audio-transcribe.rb <path_to_audio_file>
#
# Example:
#   ruby util/audio-transcribe.rb out/sample_it-IT.wav

audio_file_path = ARGV[0]

unless audio_file_path
  puts "Usage: ruby util/audio-transcribe.rb <path_to_audio_file>"
  exit 1
end

unless File.exist?(audio_file_path)
  puts "Error: Audio file not found at '#{audio_file_path}'"
  exit 1
end

begin
  puts "🧠 Transcribing #{audio_file_path} using RubyLLM (Gemini)..."
  
  # Configure RubyLLM for Gemini
  RubyLLM.configure do |config|
    config.gemini_api_key = ENV['GEMINI_API_KEY']
  end

  # Transcribe using RubyLLM.transcribe directly
  # The model needs to be specified as it defaults to whisper-1 (OpenAI)
  response = RubyLLM.transcribe(audio_file_path, model: "gemini-2.5-flash")

  if response && response.text
    puts "
--- TRANSCRIPTION ---"
    puts response.text.strip
    puts "----------------------"
  elsif response
    puts "⚠️ No text found in response: #{response.inspect}"
  else
    puts "⚠️ Empty response from RubyLLM."
  end

rescue => e
  puts "❌ Error during transcription: #{e.message}"
  exit 1
end
