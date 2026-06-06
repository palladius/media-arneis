require "spec_helper"
require "arneis/cli"
require "arneis/config"

RSpec.describe Arneis::Cli do
  let(:cli) { Arneis::Cli.new }

  before do
    allow(Arneis::Config).to receive(:load!)
    allow(FileUtils).to receive(:rm_rf)
    allow(FileUtils).to receive(:rm)
    allow(File).to receive(:write)
    allow(Dir).to receive(:exist?).and_return(false)
  end

  describe "cli class options" do
    it "includes --eval option globally" do
      expect(Arneis::Cli.class_options).to have_key(:eval)
    end
  end

  describe "apply command" do
    let(:project_double) { double(initialize_output: true, primary_artifact: "test.mp4", media?: true, process: true) }

    before do
      allow(Arneis).to receive(:load_project).and_return(project_double)
    end

    it "respects the --verify flag" do
      expect(project_double).to receive(:process).with(hash_including(verify: true))

      cli.options = cli.options.merge(verify: true)
      cli.apply("test.yaml")
    end

    it "respects the --open flag" do
      allow(cli).to receive(:open_file)
      expect(cli).to receive(:open_file).with("test.mp4")

      cli.options = cli.options.merge(open: true)
      cli.apply("test.yaml")
    end

    it "passes eval: false when --no-eval is passed" do
      expect(project_double).to receive(:process).with(hash_including(eval: false))

      cli.options = cli.options.merge(eval: false)
      cli.apply("test.yaml")
    end

    it "passes eval: true by default" do
      expect(project_double).to receive(:process).with(hash_including(eval: true))

      cli.apply("test.yaml")
    end
  end

  describe "generate command" do
    let(:project_double) { double(initialize_output: true, primary_artifact: "test.mp4", media?: true, process: true) }

    before do
      allow(Arneis).to receive(:load_project).and_return(project_double)
    end

    it "triggers evaluations by default (verify: true, eval: true)" do
      expect(project_double).to receive(:process).with(hash_including(verify: true, eval: true))

      cli.options = cli.options.merge(prompt: "A character portrait")
      cli.generate("CharacterImage")
    end

    it "skips evaluations when --no-eval is passed (verify: false, eval: false)" do
      expect(project_double).to receive(:process).with(hash_including(verify: false, eval: false))

      cli.options = cli.options.merge(prompt: "A character portrait", eval: false)
      cli.generate("CharacterImage")
    end

    it "handles --retry run_id option by parsing feedback and applying modified spec" do
      allow(Dir).to receive(:exist?).with("run_123").and_return(false)
      allow(Dir).to receive(:exist?).with("out/run_123").and_return(true)

      mock_feedback = {
        original_command: "arnectl generate CharacterImage -c riccardo",
        original_prompt: "cyberpunk",
        eval_errors: ["too dark"],
        previous_image: "out/run_123/dummy.png"
      }
      expect(Arneis::FeedbackLoader).to receive(:load).with("out/run_123").and_return(mock_feedback)

      expect(Dir).to receive(:glob).with("out/run_123/*.yaml").and_return(["out/run_123/spec.yaml"])

      mock_spec = {
        "apiVersion" => "media-arneis.palladius.it/v1",
        "kind" => "CharacterImage",
        "spec" => {
          "prompt" => "cyberpunk"
        }
      }
      expect(YAML).to receive(:load_file).with("out/run_123/spec.yaml").and_return(mock_spec)

      expect(File).to receive(:write).with(starting_with("tmp_retry_"), anything) do |filename, content|
        data = YAML.safe_load(content)
        expect(data["spec"]["feedback"]).to eq(mock_feedback.transform_keys(&:to_s))
      end

      allow(File).to receive(:exist?).with(starting_with("tmp_retry_")).and_return(true)
      expect(cli).to receive(:apply).with(starting_with("tmp_retry_"))
      expect(FileUtils).to receive(:rm).with(starting_with("tmp_retry_"))

      cli.options = cli.options.merge(retry: "run_123")
      cli.generate("CharacterImage")
    end
  end
end
