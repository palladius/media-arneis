require "spec_helper"
require "arneis/video_project"

RSpec.describe Arneis::VideoProject do
  let(:valid_yaml) { "spec/fixtures/video_plan.yaml" }
  let(:output_dir) { "out/test_project" }

  describe "#initialize" do
    it "correctly hydrates and parses a valid video_plan.yaml" do
      project = described_class.new(valid_yaml)
      expect(project.project_title).to eq("Rubycon Pitch Video")
      expect(project.scenes.size).to eq(2)
      expect(project.metadata["name"]).to eq("test-video-project")
    end

    it "raises an error for invalid YAML kind" do
      invalid_yaml = "invalid.yaml"
      content = {
        "apiVersion" => "media-arneis.palladius.it/v1",
        "kind" => "WrongKind",
        "metadata" => {"name" => "fail", "template" => "VideoProject"}
      }
      template = {"apiVersion" => "media-arneis.palladius.it/v1", "kind" => "VideoProject", "metadata" => {"name" => "VideoProject"}}

      allow(File).to receive(:exist?).with(invalid_yaml).and_return(true)
      allow(YAML).to receive(:load_file).with(invalid_yaml).and_return(content)
      allow(File).to receive(:exist?).with("data/templates/VideoProject.yaml").and_return(true)
      allow(YAML).to receive(:load_file).with("data/templates/VideoProject.yaml").and_return(template)

      expect { described_class.new(invalid_yaml) }.to raise_error(/Unknown project kind/)
    end
  end

  describe "#initialize_output" do
    before do
      FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
    end

    it "creates a deterministic output folder" do
      project = described_class.new(valid_yaml)
      project.initialize_output(output_dir)

      expect(Dir.exist?(output_dir)).to be true
      expect(File.exist?(File.join(output_dir, ".state.yaml"))).to be true
    end
  end
end
