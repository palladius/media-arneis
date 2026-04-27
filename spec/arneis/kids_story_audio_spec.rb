require "spec_helper"
require "arneis"

RSpec.describe Arneis::KidsStory do
  let(:sample_yaml) { "data/samples/KidsStory/riccardo_story.yaml" }
  let(:output_dir) { "out/test_kids_story_audio" }

  before do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  describe "Audio Configuration" do
    it "correctly parses story_audio from YAML" do
      # Since we updated riccardo_story.yaml to have [it, en]
      project = described_class.new(sample_yaml)
      expect(project.story_audio).to eq(["it", "en"])
    end

    it "defaults to [it, en] if story_audio is missing" do
      # We need a temp YAML without story_audio
      temp_yaml = File.join(output_dir, "no_audio.yaml")
      FileUtils.mkdir_p(output_dir)
      yaml_content = YAML.load_file(sample_yaml)
      yaml_content["spec"].delete("story_audio")
      File.write(temp_yaml, yaml_content.to_yaml)

      project = described_class.new(temp_yaml)
      expect(project.story_audio).to eq(["it", "en"])
    end
  end

  describe "Audio Orchestration" do
    let(:gemini_mock) { instance_double(Arneis::Generator::Gemini) }
    let(:imagen_mock) { instance_double(Arneis::Generator::Imagen) }
    let(:lyria_mock) { instance_double(Arneis::Generator::Lyria) }
    let(:chirp_mock) { instance_double(Arneis::Generator::Chirp) }

    before do
      allow(Arneis::Generator::Gemini).to receive(:new).and_return(gemini_mock)
      allow(Arneis::Generator::Imagen).to receive(:new).and_return(imagen_mock)
      allow(Arneis::Generator::Lyria).to receive(:new).and_return(lyria_mock)
      allow(Arneis::Generator::Chirp).to receive(:new).and_return(chirp_mock)

      allow(gemini_mock).to receive(:generate).and_return({content: "Mocked content", tokens: 10, cost: 0.01})
      allow(imagen_mock).to receive(:generate).and_return({status: "done", cost: 0.05, time: 1.0})
      allow(lyria_mock).to receive(:generate).and_return({status: "done", cost: 0.10, time: 1.0})
      
      # Mock chirp to write the file
      allow(chirp_mock).to receive(:generate) do |text, output_file, options|
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, "mock audio")
        {status: "done", cost: 0.02, time: 0.5}
      end

      allow(Arneis::Validator).to receive(:validate_and_rename!).and_return({success: true})
      allow_any_instance_of(Arneis::Evaluator).to receive(:evaluate_character_consistency).and_return({ success: true, score: 8 })
    end

    it "triggers audio generation for each page and language" do
      project = described_class.new(sample_yaml) # has [it, en]
      project.initialize_output(output_dir)
      
      # 3 for enrichment + 3 for prompt enhancement + 3 for translation
      expect(gemini_mock).to receive(:generate).exactly(9).times

      project.process(async: false)
      
      expect(File.exist?(File.join(output_dir, "pages/page_1/audio_it.wav"))).to be true
      expect(File.exist?(File.join(output_dir, "pages/page_1/audio_en.wav"))).to be true
      expect(File.exist?(File.join(output_dir, "pages/page_2/audio_it.wav"))).to be true
      expect(File.exist?(File.join(output_dir, "pages/page_2/audio_en.wav"))).to be true
      expect(File.exist?(File.join(output_dir, "pages/page_3/audio_it.wav"))).to be true
      expect(File.exist?(File.join(output_dir, "pages/page_3/audio_en.wav"))).to be true
    end
  end
end
