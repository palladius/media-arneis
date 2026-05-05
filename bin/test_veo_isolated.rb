#!/usr/bin/env ruby

require_relative "../lib/arneis"
require "rainbow"
require "fileutils"

# Ensure environment is loaded
Arneis::Config.load!

puts Rainbow("🎬 Starting ISOLATED Veo Generation Test...").cyan

generator = Arneis::Generator::Veo.new
output_file = "out/isolated_veo_test.mp4"
prompt = "A simple 3D cube rotating on a white background, high quality, minimalist."

FileUtils.rm_f(output_file)
FileUtils.mkdir_p("out")

begin
  puts Rainbow("🚀 Calling generator.generate(async: false)...").yellow
  # We run it synchronously to see the full polling and retrieval in one go
  result = generator.generate(prompt, output_file, async: false)
  
  if result[:status] == "done" && File.exist?(output_file)
    puts Rainbow("✅ SUCCESS! Video generated and saved to #{output_file}").green
    puts Rainbow("📊 Result: #{result.inspect}").blue
  else
    puts Rainbow("❌ FAILURE! Result: #{result.inspect}").red
    exit 1
  end
rescue => e
  puts Rainbow("💥 CRASH! #{e.class}: #{e.message}").red
  puts e.backtrace.first(10).join("\n")
  exit 1
end
