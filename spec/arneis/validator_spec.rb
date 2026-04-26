require "spec_helper"
require "arneis/validator"

RSpec.describe Arneis::Validator do
  it "fails for non-existent files" do
    result = described_class.verify("missing.mp4", :video)
    expect(result[:success]).to be false
    expect(result[:message]).to include("File not found")
  end

  it "fails for mock text files masquerading as video" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "test.mp4")
      File.write(file, "MOCK_VIDEO_DATA")
      result = described_class.verify(file, :video)
      expect(result[:success]).to be false
      expect(result[:info]).to include("ASCII text")
    end
  end

  # We can't easily test real media without having a sample file,
  # but we can stub the ` command
  it 'succeeds when "file" output matches patterns' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "real.mp4")
      File.write(file, "dummy")
      allow(described_class).to receive(:`).with("file \"#{file}\"").and_return("real.mp4: ISO Media, MP4 v2 [ISO 14496-14]")

      result = described_class.verify(file, :video)
      expect(result[:success]).to be true
      expect(result[:info]).to include("ISO Media")
    end
  end

  it "succeeds for text files" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "test.txt")
      File.write(file, "Hello world")
      result = described_class.verify(file, :text)
      expect(result[:success]).to be true
      expect(result[:info]).to include("text")
    end
  end

  it "succeeds for markdown files" do
    Dir.mktmpdir do |dir|
      file = File.join(dir, "test.md")
      File.write(file, "# Title")
      result = described_class.verify(file, :markdown)
      expect(result[:success]).to be true
      expect(result[:info]).to include("text")
    end
  end
end
