require "spec_helper"
require "arneis"

RSpec.describe Arneis::CharacterImage do
  let(:yaml_path) { "data/samples/CharacterImage/riccardo_sake.yaml" }
  let(:project) { described_class.new(yaml_path) }

  before do
    # Stub hydration and validation if necessary, or use real files if they exist in worktree
  end

  describe "#initialize" do
    it "loads the character IDs from the YAML" do
      expect(project.character_ids).to include("riccardo")
    end

    it "loads the prompt from the YAML" do
      expect(project.prompt).to include("pouring a cold sake")
    end
  end

  describe "#process" do
    it "initializes an orchestrator with the correct tasks" do
      # This will fail until implemented
      expect(project).to respond_to(:process)
    end
  end
end
