require "spec_helper"
require "arneis/generator/marketing"
require "fileutils"
require "tmpdir"

RSpec.describe Arneis::Generator::Marketing do
  let(:tmp_dir) { Dir.mktmpdir("marketing_test") }
  let(:output_dir) { File.join(tmp_dir, "marketing") }
  subject { described_class.new }

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#generate_all" do
    it "triggers image generation for all platforms" do
      # Mock Imagen generator to avoid real API calls
      mock_imagen = instance_double(Arneis::Generator::Imagen)
      allow(Arneis::Generator::Imagen).to receive(:new).and_return(mock_imagen)

      # Expect calls for LinkedIn, IG, and X
      expect(mock_imagen).to receive(:generate).thrice.and_return({status: "done"})

      results = subject.generate_all("Project Title", "Contextual info", output_dir)
      expect(results.keys).to include(:linkedin, :instagram_stories, :x_twitter)
    end
  end
end
