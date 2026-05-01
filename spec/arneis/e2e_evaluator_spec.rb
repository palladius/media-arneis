require "spec_helper"
require "arneis"

RSpec.describe Arneis::Evaluator do
  let(:evaluator) { described_class.new }

  before do
    # Stubbing gemini to avoid real calls in unit tests
    allow(evaluator.instance_variable_get(:@gemini)).to receive(:generate)
  end

  describe "#check_json" do
    it "identifies logic errors in a JSON artifact" do
      json_path = "spec/fixtures/invalid_story.json"
      content = File.read(json_path)
      
      allow(evaluator.instance_variable_get(:@gemini)).to receive(:generate).and_return({
        content: "SUCCESS: false\nREASON: Prompt mentions sunset but detected objects are moon/snow."
      })
      
      # This will fail initially because the method doesn't exist
      result = evaluator.check_json(content)
      expect(result[:success]).to be false
      expect(result[:message]).to include("sunset")
    end
  end
  
  describe "#check_multimodal" do
    it "identifies intent mismatches in media" do
      allow(evaluator.instance_variable_get(:@gemini)).to receive(:generate).and_return({
        content: "SUCCESS: false\nREASON: Image shows a desert but prompt was 'underwater city'."
      })
      
      # This will fail initially because the method doesn't exist
      result = evaluator.check_multimodal("dummy.png", "underwater city")
      expect(result[:success]).to be false
      expect(result[:message]).to include("desert")
    end
  end
end
