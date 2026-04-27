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
end
