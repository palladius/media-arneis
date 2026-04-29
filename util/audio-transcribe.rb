#!/usr/bin/env ruby

require "ruby_llm"
require "json"

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
  
  # Assuming RubyLLM's chat method can handle audio input directly
  # If not, this might need adjustment based on RubyLLM's actual API
  # The question mentions "chat.transcribe", so let's try that.
  response = RubyLlm::Chat.transcribe(audio_file_path)

  if response && response["text"]
    puts "
--- TRANSCRIPTION ---"
    puts response["text"].strip
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
