#!/usr/bin/env ruby
require_relative '../lib/arneis'
require 'rainbow'
require 'fileutils'

# Ensure output directory exists
FileUtils.mkdir_p('out/tests/cc/')

puts Rainbow("--- Character Consistency Probability Test (N-1 vs 1) ---").cyan.bold

# 1. Load Character
char_id = 'riccardo'
character = Arneis::Character.find(char_id)

unless character
  puts Rainbow("❌ Character #{char_id} not found!").red
  exit 1
end

images = character.consistency_images
if images.size < 2
  puts Rainbow("❌ Not enough images for N-1 test (found #{images.size})").red
  exit 1
end

# 2. Split into N-1 training and 1 test
test_image = images.last
train_images = images[0...-1]

puts Rainbow("👤 Character: #{character.name}").yellow
puts "  - Total images: #{images.size}"
puts "  - Using #{train_images.size} images for generation."
puts "  - Using 1 image as ground truth: #{File.basename(test_image)}"

# 3. Generate new image
puts Rainbow("\n🚀 Generating Riccardo as an astronaut...").magenta
gen = Arneis::Generator::Imagen.new
output_path = "out/tests/cc/riccardo_astronaut_test.png"

# Enforce real generation
ENV['ARNEIS_NO_MOCK'] = 'true'

prompt = "A highly detailed, close-up portrait of Riccardo as a brave astronaut. 
He is wearing a sleek white space suit with a gold-tinted visor open, showing his face clearly. 
The background is a swirling cosmic nebula. Pixar-style, cinematic lighting, ultra-realistic features."

begin
  res = gen.generate(prompt, output_path, reference_images: train_images.join(','))
  puts Rainbow("✅ Generation finished.").green
rescue => e
  puts Rainbow("❌ Generation failed: #{e.message}").red
  exit 1
end

# 4. Evaluate with 0-100 probability
puts Rainbow("\n⚖️  Evaluating similarity probability...").cyan
evaluator = Arneis::Evaluator.new
result = evaluator.detailed_probability_eval(output_path, test_image, character.name)

puts "\n" + Rainbow("📊 Final CC Test Result").cyan.bold
puts "----------------------------"
puts "  Probability: " + Rainbow("#{result[:probability]}%").yellow.bold
puts "  Reasoning:   " + Rainbow(result[:message]).white
puts "----------------------------"

if result[:probability] >= 80
  puts Rainbow("✨ High Consistency Detected!").green.bold
elsif result[:probability] >= 50
  puts Rainbow("🤔 Moderate Consistency. Some features match.").yellow.bold
else
  puts Rainbow("💀 Low Consistency. Character looks different.").red.bold
end
