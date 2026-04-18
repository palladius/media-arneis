#!/usr/bin/env ruby
require 'bundler/setup'
require 'zeitwerk'
require 'rainbow'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/../lib")
loader.setup

require 'arneis'

Arneis::Config.load!
puts Rainbow("🎨 Generating project logo...").magenta
Arneis::Generator::Imagen.new.generate(
  "A stunning, colorful and stylish logo for a software project named Arneis. The logo should blend a crystalline ruby gemstone with high-tech circuitry. Palette: ruby red, electric blue, gold. 8k, photorealistic, vector style.",
  "logo.png"
)
