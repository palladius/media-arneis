#!/usr/bin/env ruby

=begin
Arneis Model Test Script - Verifies all default models.
Generates one text, one image, and one video.
=end

require 'bundler/setup'
require 'zeitwerk'
require 'fileutils'
require 'rainbow'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib")
loader.setup

require 'arneis'

module Arneis
  class ModelTester
    def self.run
      puts Rainbow("🧪 Starting Full Model Test Suite...").cyan.bold
      
      test_dir = "out/test_models_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
      FileUtils.mkdir_p(test_dir)
      Config.load!

      # 1. Test Gemini (Text)
      puts Rainbow("\n1. Testing Gemini Text Generation...").yellow
      gemini = Generator::Gemini.new
      text_result = gemini.generate("Write a short slogan for a Ruby project named Arneis.", "#{test_dir}/slogan.txt")
      puts "Result: #{text_result[:content]}"
      Validator.verify("#{test_dir}/slogan.txt", :text)

      # 2. Test Imagen (Image)
      puts Rainbow("\n2. Testing Imagen Image Generation...").yellow
      imagen = Generator::Imagen.new
      image_result = imagen.generate("A stylish logo for 'Arneis' project, ruby gemstone meets tech.", "#{test_dir}/logo.png")
      Validator.verify("#{test_dir}/logo.png", :image)

      # 3. Test Veo (Video)
      puts Rainbow("\n3. Testing Veo Video Generation...").yellow
      veo = Generator::Veo.new
      veo_result = veo.generate("A cinematic sweep of the Rimini coast at sunset.", "#{test_dir}/test_video.mp4")
      Validator.verify("#{test_dir}/test_video.mp4", :video)

      puts Rainbow("\n✅ Model tests completed! Artifacts in #{test_dir}").green.bold
    end
  end
end

Arneis::ModelTester.run
