require "spec_helper"
require "arneis"
require "tempfile"
require "yaml"

RSpec.describe Arneis::PowerColon do
  let(:temp_slide1) { Tempfile.new(["slide01", ".md"]) }
  let(:temp_slide2) { Tempfile.new(["slide02", ".md"]) }
  let(:output_dir) { "out/test_power_colon" }

  let(:valid_yaml_content) do
    {
      "apiVersion" => "media-arneis.palladius.it/v1",
      "kind" => "PowerColon",
      "metadata" => {
        "name" => "openclaw-vs-hermes",
        "template" => "PowerColon"
      },
      "spec" => {
        "presentation_title" => "Openclaw vs Hermes",
        "slides" => [
          {
            "file" => temp_slide1.path,
            "style" => "title_slide"
          },
          {
            "file" => temp_slide2.path,
            "style" => "left_image",
            "image" => {
              "filename" => "slide02_illus.png",
              "aspect_ratio" => "3:4",
              "prompt" => "A sleek messenger god and a mechanical lobster"
            }
          }
        ]
      }
    }.to_yaml
  end

  let(:temp_yaml) do
    file = Tempfile.new(["presentation", ".yaml"])
    file.write(valid_yaml_content)
    file.close
    file
  end

  before do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
    # Write some dummy Markdown content
    File.write(temp_slide1.path, "# Openclaw vs Hermes\nAn architectural comparison")
    File.write(temp_slide2.path, "# Architecture Comparison\n- Openclaw is agentic\n- Hermes is message-driven")
  end

  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
    temp_slide1.unlink
    temp_slide2.unlink
    temp_yaml.unlink
  end

  describe "#initialize" do
    it "correctly hydrates and parses the presentation yaml" do
      project = described_class.new(temp_yaml.path)
      expect(project.presentation_title).to eq("Openclaw vs Hermes")
      expect(project.slides.size).to eq(2)
      expect(project.slides.first["style"]).to eq("title_slide")
    end

    context "with a grounded presentation (inline title and content)" do
      let(:grounded_yaml_content) do
        {
          "apiVersion" => "media-arneis.palladius.it/v1",
          "kind" => "PowerColon",
          "metadata" => {
            "name" => "grounded-pres",
            "template" => "PowerColon"
          },
          "spec" => {
            "presentation_title" => "Grounded Deck",
            "slides" => [
              {
                "title" => "Slide 1 Title",
                "content" => "- Point A\n- Point B",
                "style" => "default"
              }
            ]
          }
        }.to_yaml
      end

      let(:temp_grounded_yaml) do
        file = Tempfile.new(["grounded", ".yaml"])
        file.write(grounded_yaml_content)
        file.close
        file
      end

      after { temp_grounded_yaml.unlink }

      it "successfully parses without requiring external slide markdown files" do
        project = described_class.new(temp_grounded_yaml.path)
        expect(project.presentation_title).to eq("Grounded Deck")
        expect(project.slides.size).to eq(1)
        expect(project.slides.first["title"]).to eq("Slide 1 Title")
        expect(project.slides.first["content"]).to eq("- Point A\n- Point B")
      end
    end

    context "with an ideation presentation (topic-based, no slides array)" do
      let(:ideation_yaml_content) do
        {
          "apiVersion" => "media-arneis.palladius.it/v1",
          "kind" => "PowerColon",
          "metadata" => {
            "name" => "ideation-pres",
            "template" => "PowerColon"
          },
          "spec" => {
            "presentation_title" => "Ideation Deck",
            "topic" => "Agentic AI workflows",
            "slides_count" => 3
          }
        }.to_yaml
      end

      let(:temp_ideation_yaml) do
        file = Tempfile.new(["ideation", ".yaml"])
        file.write(ideation_yaml_content)
        file.close
        file
      end

      after { temp_ideation_yaml.unlink }

      it "runs inline ideation in dry-run mode and populates slides" do
        allow(Arneis::Config).to receive(:dryrun?).and_return(true)
        project = described_class.new(temp_ideation_yaml.path)
        expect(project.presentation_title).to eq("Ideation Deck")
        expect(project.slides.size).to eq(3)
        expect(project.slides.first["title"]).to eq("Slide 1 Title")
      end
    end
  end

  describe "#initialize_output" do
    it "creates the output directory and state file" do
      project = described_class.new(temp_yaml.path)
      project.initialize_output(output_dir)

      expect(Dir.exist?(output_dir)).to be true
      expect(File.exist?(File.join(output_dir, ".state.yaml"))).to be true

      state = YAML.load_file(File.join(output_dir, ".state.yaml"))
      expect(state["presentation_title"]).to eq("Openclaw vs Hermes")
      expect(state["status"]).to eq("initialized")
      expect(state["slides"].size).to eq(2)
      expect(state["slides"].last["image"]["filename"]).to eq("slide02_illus.png")
    end
  end

  describe "#process" do
    let(:imagen_mock) { instance_double(Arneis::Generator::Imagen) }

    before do
      allow(Arneis::Generator::Imagen).to receive(:new).and_return(imagen_mock)
      allow(imagen_mock).to receive(:generate).and_return({status: "mocked", cost: 0.0, time: 0.1})
      allow(Arneis::Validator).to receive(:validate_and_rename!).and_return({success: true})
    end

    it "orchestrates presentation generation correctly" do
      project = described_class.new(temp_yaml.path)
      project.initialize_output(output_dir)

      # Run process in sync mode
      project.process(async: false)

      expect(File.exist?(File.join(output_dir, "presentation.html"))).to be true
      expect(File.exist?(File.join(output_dir, "slides_export.json"))).to be true
      state = YAML.load_file(File.join(output_dir, ".state.yaml"))
      expect(state["status"]).to eq("done")
      expect(project.primary_artifact).to eq(File.join(output_dir, "presentation.html"))
    end
  end

  describe "CLI generate integration" do
    let(:cli) { Arneis::Cli.new }
    let(:gemini_mock) { instance_double(Arneis::Generator::Gemini) }

    before do
      allow(Arneis::Generator::Gemini).to receive(:new).and_return(gemini_mock)
      allow(gemini_mock).to receive(:generate).and_return({
        content: {
          "presentation_title" => "Hermes vs Openclaw",
          "slides" => [
            {
              "style" => "title_slide",
              "title" => "Showdown",
              "content" => "Hermes vs Openclaw"
            }
          ]
        }.to_json
      })
      allow(cli).to receive(:apply)
      # Mock file system operations
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
    end

    it "ideates and drafts slides correctly" do
      cli.options = {topic: "Hermes vs Openclaw", slides: 1, fun: true}
      expect(cli).to receive(:apply).with("data/presentations/hermes_vs_openclaw.yaml")

      cli.generate("PowerColon")
    end
  end
end
