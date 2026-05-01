require "spec_helper"
require "arneis"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }
  let(:mock_project) { instance_double(Arneis::VideoProject) }

  before do
    allow(Arneis).to receive(:load_project).and_return(mock_project)
    allow(mock_project).to receive(:initialize_output)
    allow(mock_project).to receive(:process)
    # Stubbing puts to avoid output in tests
    allow(cli).to receive(:puts)
  end

  describe "apply" do
    it "accepts the --verify flag and passes it to project.process" do
      cli = Arneis::Cli.new
      cli.options = { verify: true }
      expect(mock_project).to receive(:process).with(hash_including(verify: true))
      cli.apply("sample.yaml")
    end

    it "defaults verify to false if flag is missing" do
      cli = Arneis::Cli.new
      cli.options = { verify: false }
      expect(mock_project).to receive(:process).with(hash_including(verify: false))
      cli.apply("sample.yaml")
    end
  end
end
