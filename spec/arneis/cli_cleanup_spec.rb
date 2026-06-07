# frozen_string_literal: true

require "spec_helper"
require "arneis/cli"
require "arneis/validator"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }

  before do
    allow(Arneis::Config).to receive(:load!)
  end

  describe "#cleanup" do
    before do
      allow(Dir).to receive(:glob).with("out/*").and_return(["out/junk_project", "out/real_project"])
      allow(File).to receive(:directory?).with("out/junk_project").and_return(true)
      allow(File).to receive(:directory?).with("out/real_project").and_return(true)
    end

    it "moves directories with zero real media to out/.trash" do
      # Mock checking for media files recursively in junk_project
      allow(Dir).to receive(:glob).with("out/junk_project/**/*.{" + Arneis::Cli::VALID_TYPES.keys.join(",") + "}").and_call_original rescue nil
      # Note: Since Dir.glob pattern inside cleanup uses specific extensions:
      allow(Dir).to receive(:glob).with("out/junk_project/**/*.{" + "mp4,mov,avi,mkv,webm,png,jpg,jpeg,webp,gif,wav,mp3" + "}").and_return(["out/junk_project/image.png"])
      allow(File).to receive(:exist?).with("out/junk_project/image.png.mock").and_return(true) # it is a mock!
      allow(File).to receive(:exist?).with("out/junk_project/image.png.NOT_GOOD").and_return(false)

      # Mock checking for media files in real_project
      allow(Dir).to receive(:glob).with("out/real_project/**/*.{" + "mp4,mov,avi,mkv,webm,png,jpg,jpeg,webp,gif,wav,mp3" + "}").and_return(["out/real_project/image.png"])
      allow(File).to receive(:exist?).with("out/real_project/image.png.mock").and_return(false) # it is real!
      allow(File).to receive(:exist?).with("out/real_project/image.png.NOT_GOOD").and_return(false)

      # Expect FileUtils.mv to be called for junk_project but not real_project
      allow(FileUtils).to receive(:mkdir_p)
      expect(FileUtils).to receive(:mv).with("out/junk_project", anything)
      expect(FileUtils).not_to receive(:mv).with("out/real_project", anything)

      cli.options = {dryrun: false}
      expect { cli.cleanup }.to output(/Archiving project with ZERO real media: out\/junk_project/).to_stdout
    end

    it "does not move directories if dryrun option is true" do
      allow(Dir).to receive(:glob).with("out/junk_project/**/*.{" + "mp4,mov,avi,mkv,webm,png,jpg,jpeg,webp,gif,wav,mp3" + "}").and_return(["out/junk_project/image.png"])
      allow(File).to receive(:exist?).with("out/junk_project/image.png.mock").and_return(true)
      allow(File).to receive(:exist?).with("out/junk_project/image.png.NOT_GOOD").and_return(false)

      allow(Dir).to receive(:glob).with("out/real_project/**/*.{" + "mp4,mov,avi,mkv,webm,png,jpg,jpeg,webp,gif,wav,mp3" + "}").and_return([])

      expect(FileUtils).not_to receive(:mv)

      cli.options = {dryrun: true}
      expect { cli.cleanup }.to output(/Would archive project with ZERO real media/).to_stdout
    end
  end

  describe "#check_fake_media" do
    it "calls Validator.validate_and_rename! on each found file" do
      allow(cli).to receive(:resolve_media_folder).and_return("out/test_project")
      
      allow(Dir).to receive(:glob).with("out/test_project/**/*.{" + "mp4,mov,avi,mkv,webm,png,jpg,jpeg,webp,gif,wav,mp3" + "}").and_return(["out/test_project/image.png"])
      
      expect(Arneis::Validator).to receive(:validate_and_rename!).with("out/test_project/image.png", :image).and_return({success: true, info: "REAL"})
      
      expect { cli.check_fake_media("test_project") }.to output(/All checked media files are genuine/).to_stdout
    end
  end
end
