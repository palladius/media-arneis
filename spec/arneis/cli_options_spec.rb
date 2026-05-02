require "spec_helper"
require "arneis" # Load everything
require "arneis/cli"
require "arneis/config"

RSpec.describe Arneis::Cli do
  let(:cli) { Arneis::Cli.new }

  before do
    # Clear environment variables
    ENV.delete("ARNEIS_EVAL_ENABLED")
    ENV.delete("ARNEIS_OPEN_ENABLED")
    
    # Mocking external calls to avoid actual file operations/CLI execution
    allow(Arneis::Config).to receive(:load!)
    allow(FileUtils).to receive(:rm_rf)
    allow(FileUtils).to receive(:rm)
    allow(File).to receive(:write)
    allow(Dir).to receive(:exist?).and_return(false)
  end

  describe "global options" do
    it "includes --eval and --no-eval" do
      expect(Arneis::Cli.class_options).to include(:eval)
    end

    it "includes --open and --no-open" do
      expect(Arneis::Cli.class_options).to include(:open)
    end
  end

  describe "apply command" do
    it "respects the --eval flag" do
      # We need to verify that the config is resolved correctly within the CLI
      # and passed to the project.process method.
      project_double = double(initialize_output: true, primary_artifact: "test.mp4")
      allow(Arneis).to receive(:load_project).and_return(project_double)
      
      # Expect project.process to be called with eval: false
      expect(project_double).to receive(:process).with(hash_including(eval: false))
      
      cli.options = { eval: false }
      cli.apply("test.yaml")
    end

    it "respects the --open flag" do
      project_double = double(initialize_output: true, primary_artifact: "test.mp4", process: true)
      allow(Arneis).to receive(:load_project).and_return(project_double)
      allow(File).to receive(:exist?).with("test.mp4").and_return(true)
      
      # Verify that open_file is NOT called when --no-open is provided
      expect(cli).not_to receive(:open_file)
      
      cli.options = { open: false }
      cli.apply("test.yaml")
    end
  end
end
