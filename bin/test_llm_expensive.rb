#!/usr/bin/env ruby
=begin
bin/test_llm_expensive.rb - Entry point for expensive LLM integration tests.
=end

require_relative '../lib/arneis'
require_relative '../lib/arneis/test/expensive_suite'

suite = Arneis::Test::ExpensiveSuite.new

# 1. Image Generation (Imagen)
suite.add_test("Imagen Generation") do
  gen = Arneis::Generator::Imagen.new
  output = "out/tests/expensive/test_image.png"
  # Use ARNEIS_NO_MOCK=true to ensure real gen
  ENV['ARNEIS_NO_MOCK'] = 'true'
  res = gen.generate("A small red cube on a white background", output)
  { cost: res[:cost] }
end

# 2. Audio Generation (Lyria)
suite.add_test("Lyria Music Generation") do
  gen = Arneis::Generator::Lyria.new
  output = "out/tests/expensive/test_music.wav"
  ENV['ARNEIS_NO_MOCK'] = 'true'
  res = gen.generate("A peaceful piano melody", output)
  { cost: res[:cost] }
end

# 3. Video Generation (Veo)
suite.add_test("Veo Video Generation") do
  gen = Arneis::Generator::Veo.new
  output = "out/tests/expensive/test_video.mp4"
  ENV['ARNEIS_NO_MOCK'] = 'true'
  res = gen.generate("A single drop of water falling into a still pool", output, async: false)
  { cost: res[:cost] }
end

suite.run_all
