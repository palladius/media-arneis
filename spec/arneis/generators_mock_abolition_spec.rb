require "spec_helper"
require "arneis"

RSpec.describe "Generators Mock Abolition" do
  let(:output_file) { "tmp/test_output.media" }

  before do
    FileUtils.mkdir_p("tmp")
    allow(Arneis::Config).to receive(:no_mock?).and_return(true)
    # Stubbing external calls to avoid real AI requests and focus on the logic
    allow(Open3).to receive(:popen3).and_raise("Simulated Failure")
  end

  after do
    FileUtils.rm_rf("tmp")
  end

  describe Arneis::Generator::Imagen do
    it "raises an error when no_mock? is true" do
      generator = Arneis::Generator::Imagen.new
      expect {
        generator.generate("a test prompt", output_file)
      }.to raise_error("Simulated Failure")
    end
  end

  describe Arneis::Generator::Chirp do
    it "raises an error when no_mock? is true" do
      generator = Arneis::Generator::Chirp.new
      expect {
        generator.generate("a test prompt", output_file)
      }.to raise_error("Simulated Failure")
    end
  end

  describe Arneis::Generator::Lyria do
    it "raises an error when no_mock? is true" do
      generator = Arneis::Generator::Lyria.new
      expect {
        generator.generate("a test prompt", output_file)
      }.to raise_error("Simulated Failure")
    end
  end

  describe Arneis::Generator::Veo do
    it "raises an error when no_mock? is true" do
      generator = Arneis::Generator::Veo.new
      expect {
        generator.generate("a test prompt", output_file)
      }.to raise_error("Simulated Failure")
    end
  end
end
