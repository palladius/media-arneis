require "spec_helper"
require "arneis"

RSpec.describe Arneis::KidsStory do
  let(:sample_yaml) { "data/samples/KidsStory/riccardo_story.yaml" }
  let(:output_dir) { "out/test_kids_story" }

  before do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  describe "#initialize" do
    it "correctly hydrates and parses the riccardo_story.yaml" do
      project = described_class.new(sample_yaml)
      expect(project.story_title).to eq("Riccardo's Galactic Pizza Quest")
      expect(project.pages.size).to eq(3)
      expect(project.character_id).to eq("riccardo")
    end
  end

  describe "#initialize_output" do
    it "creates the output directory and state file" do
      project = described_class.new(sample_yaml)
      project.initialize_output(output_dir)

      expect(Dir.exist?(output_dir)).to be true
      expect(File.exist?(File.join(output_dir, ".state.yaml"))).to be true

      state = YAML.load_file(File.join(output_dir, ".state.yaml"))
      expect(state["story_title"]).to eq("Riccardo's Galactic Pizza Quest")
      expect(state["final_story_assembly"]["status"]).to eq("pending")
    end
  end

  describe "#process" do
    let(:gemini_mock) { instance_double(Arneis::Generator::Gemini) }
    let(:imagen_mock) { instance_double(Arneis::Generator::Imagen) }
    let(:lyria_mock) { instance_double(Arneis::Generator::Lyria) }
    let(:chirp_mock) { instance_double(Arneis::Generator::Chirp) }

    before do
      allow(Arneis::Generator::Gemini).to receive(:new).and_return(gemini_mock)
      allow(Arneis::Generator::Imagen).to receive(:new).and_return(imagen_mock)
      allow(Arneis::Generator::Lyria).to receive(:new).and_return(lyria_mock)
      allow(Arneis::Generator::Chirp).to receive(:new).and_return(chirp_mock)

      allow(gemini_mock).to receive(:generate).and_return({content: "Enhanced Prompt", tokens: 10, cost: 0.01})
      allow(imagen_mock).to receive(:generate).and_return({status: "done", cost: 0.05, time: 1.0})
      allow(lyria_mock).to receive(:generate).and_return({status: "done", cost: 0.10, time: 1.0})
      allow(chirp_mock).to receive(:generate) do |text, output_file, options|
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, "mock audio")
        {status: "done", cost: 0.02, time: 0.5}
      end

      # Mock validation to avoid real file checks
      allow(Arneis::Validator).to receive(:validate_and_rename!).and_return({success: true})
      # Mock evaluation to return a low score (3/10)
      allow_any_instance_of(Arneis::Evaluator).to receive(:evaluate_character_consistency).and_return({success: false, score: 3, message: "Too different"})
    end

    it "orchestrates the story generation correctly" do
      project = described_class.new(sample_yaml)
      project.initialize_output(output_dir)

      # Run sync for testing
      project.process(async: false)

      expect(File.exist?(File.join(output_dir, "STORY.md"))).to be true

      state = YAML.load_file(File.join(output_dir, ".state.yaml"))
      expect(state["status"]).to eq("done")
      expect(state["final_story_assembly"]["status"]).to eq("done")
      # Since we mocked a low score, they should be done_with_warnings
      expect(state["pages"].all? { |p| p["status"] == "done_with_warnings" }).to be true
    end
  end
end
