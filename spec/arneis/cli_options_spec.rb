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

  describe "apply command options" do
    it "includes --verify option" do
      expect(Arneis::Cli.commands["apply"].options).to have_key(:verify)
    end

    it "includes --open option" do
      expect(Arneis::Cli.commands["apply"].options).to have_key(:open)
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
  end
end
