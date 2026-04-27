require "spec_helper"
require "arneis"

RSpec.describe Arneis::Evaluator do
  let(:evaluator) { described_class.new }
  let(:audio_path) { "spec/fixtures/test_audio.wav" }
  let(:expected_text) { "Riccardo wanted to find the best pizza in the whole galaxy!" }
  let(:gemini_mock) { instance_double(Arneis::Generator::Gemini) }

  before do
    allow(Arneis::Generator::Gemini).to receive(:new).and_return(gemini_mock)
    # Ensure fixture directory exists
    FileUtils.mkdir_p("spec/fixtures")
    File.write(audio_path, "mock audio data") unless File.exist?(audio_path)
  end

  describe "#evaluate_audio_intelligibility" do
    it "returns success when similarity is 90% or higher" do
      gemini_response = {
        content: "SCORE: 9\nSIMILARITY: 95%\nTRANSCRIPTION: Riccardo wanted to find the best pizza in the galaxy!\nREASON: Very clear."
      }
      allow(gemini_mock).to receive(:generate).and_return(gemini_response)

      result = evaluator.evaluate_audio_intelligibility(audio_path, expected_text)
      expect(result[:success]).to be true
      expect(result[:similarity]).to eq(95)
      expect(result[:score]).to eq(9)
    end

    it "returns failure when similarity is below 90%" do
      gemini_response = {
        content: "SCORE: 4\nSIMILARITY: 70%\nTRANSCRIPTION: Riccardo wanted pizza.\nREASON: Missing half of the text."
      }
      allow(gemini_mock).to receive(:generate).and_return(gemini_response)

      result = evaluator.evaluate_audio_intelligibility(audio_path, expected_text)
      expect(result[:success]).to be false
      expect(result[:similarity]).to eq(70)
    end

    it "handles failures gracefully" do
      allow(gemini_mock).to receive(:generate).and_raise("Gemini Error")

      result = evaluator.evaluate_audio_intelligibility(audio_path, expected_text)
      expect(result[:success]).to be false
      expect(result[:evaluated]).to be false
    end
  end
end
