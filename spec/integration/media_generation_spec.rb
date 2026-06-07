# spec/integration/media_generation_spec.rb
# Integration tests validating real media generation and LLM-as-judge evaluations.

require "spec_helper"
require "fileutils"

RSpec.describe "Real Media Generation & LLM-as-Judge Evaluation", :expensive do
  let(:output_dir) { "out/integration_tests" }

  before(:all) do
    FileUtils.rm_rf("out/integration_tests")
    FileUtils.mkdir_p("out/integration_tests")
    
    # Ensure ARNEIS_NO_MOCK is set to true for real generations
    ENV["ARNEIS_NO_MOCK"] = "true"
    # Ensure dryrun is disabled
    Arneis::Config.dryrun = false
  end

  after(:all) do
    # Cleanup env variable
    ENV.delete("ARNEIS_NO_MOCK")
  end

  describe "Imagen Image Generation" do
    let(:output_path) { File.join(output_dir, "test_sphere.png") }
    let(:prompt) { "A small blue sphere on a black background" }

    it "generates a real image and evaluates it using LLM-as-judge" do
      puts "\n🚀 [INTEGRATION] Starting Imagen Test..."
      generator = Arneis::Generator::Imagen.new
      
      result = generator.generate(prompt, output_path)
      
      expect(result[:status]).to eq("done")
      expect(File.exist?(output_path)).to be true
      
      # Use the custom LLM-as-judge matcher
      expect(output_path).to meet_media_criteria(prompt)
    end
  end

  describe "Lyria Music Generation" do
    let(:output_path) { File.join(output_dir, "test_beat.wav") }
    let(:prompt) { "A fast techno electronic beat with drums" }

    it "generates real music and evaluates it using LLM-as-judge" do
      puts "\n🚀 [INTEGRATION] Starting Lyria Test..."
      generator = Arneis::Generator::Lyria.new
      
      result = generator.generate(prompt, output_path)
      
      expect(result[:status]).to eq("done")
      expect(File.exist?(output_path)).to be true
      
      # Use the custom LLM-as-judge matcher
      expect(output_path).to meet_media_criteria(prompt)
    end
  end

  describe "Veo Video Generation" do
    let(:output_path) { File.join(output_dir, "test_bounce.mp4") }
    let(:prompt) { "A red ball bouncing once on the floor" }

    it "generates a real video and evaluates it using LLM-as-judge" do
      puts "\n🚀 [INTEGRATION] Starting Veo Test..."
      generator = Arneis::Generator::Veo.new
      
      # Veo is run synchronously for the integration test
      result = generator.generate(prompt, output_path, async: false)
      
      expect(result[:status]).to eq("done")
      expect(File.exist?(output_path)).to be true
      
      # Use the custom LLM-as-judge matcher
      expect(output_path).to meet_media_criteria(prompt)
    end
  end
end
