require "spec_helper"
require "arneis"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }
  let(:mock_project) { instance_double(Arneis::VideoProject) }

  before do
    allow(Arneis).to receive(:load_project).and_return(mock_project)
    allow(mock_project).to receive(:initialize_output)
    allow(mock_project).to receive(:process)
    allow(mock_project).to receive(:media?).and_return(true)
    allow(mock_project).to receive(:primary_artifact).and_return("test.mp4")
    allow(Arneis::MediaOpener).to receive(:open)
    allow(cli).to receive(:puts)
    # allow(Arneis::Config).to receive(:eval_enabled?).and_return(true)
    allow(Arneis::Config).to receive(:eval_enabled?) { |h| h[:eval] }
    allow(Arneis::Config).to receive(:open_enabled?).and_return(true)
  end

  describe "apply" do
    it "accepts the --verify flag and passes it to project.process" do
      cli.options = { verify: true }
      expect(Arneis::Config).to receive(:eval_enabled?).with(eval: true).and_return(true)
      expect(mock_project).to receive(:process).with(hash_including(verify: true))
      cli.apply("sample.yaml")
    end

    it "defaults verify to false if flag is missing" do
      cli.options = { verify: nil }
      expect(Arneis::Config).to receive(:eval_enabled?).with(eval: nil).and_return(false)
      expect(mock_project).to receive(:process).with(hash_including(verify: false))
      cli.apply("sample.yaml")
    end
  end
end
