# frozen_string_literal: true

require "spec_helper"
require "arneis"

RSpec.describe Arneis::ExtractBestOf do
  let(:source_dir) { "tmp_test_src" }
  let(:dest_dir1) { "tmp_test_dest1" }
  let(:dest_dir2) { "tmp_test_dest2" }
  let(:targets) { [dest_dir1, dest_dir2] }

  before do
    # Cleanup any leftovers
    FileUtils.rm_rf(source_dir)
    FileUtils.rm_rf(dest_dir1)
    FileUtils.rm_rf(dest_dir2)

    # Setup source directory structure
    FileUtils.mkdir_p(File.join(source_dir, "20260601_project1/pages/page_1"))
    FileUtils.mkdir_p(File.join(source_dir, "20260601_project1/.trash"))
    FileUtils.mkdir_p(File.join(source_dir, "best-of/pics"))

    # Create dummy images
    File.write(File.join(source_dir, "20260601_project1/character_image.png"), "dummy content image 1")
    File.write(File.join(source_dir, "20260601_project1/pages/page_1/illustration.png"), "dummy content image 2")
    
    # Create files that should be ignored
    File.write(File.join(source_dir, "20260601_project1/info.txt"), "some text info")
    File.write(File.join(source_dir, "20260601_project1/.trash/old.png"), "deleted content")
    File.write(File.join(source_dir, "best-of/pics/ignored_already.png"), "already in best-of")
  end

  after do
    FileUtils.rm_rf(source_dir)
    FileUtils.rm_rf(dest_dir1)
    FileUtils.rm_rf(dest_dir2)
  end

  describe "#find_files" do
    it "finds only images and respects exclusions" do
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      files = extractor.find_files

      expect(files).to contain_exactly(
        "tmp_test_src/20260601_project1/character_image.png",
        "tmp_test_src/20260601_project1/pages/page_1/illustration.png"
      )
    end
  end

  describe "#run" do
    it "copies files with deterministic collision-preventing names and populates stats" do
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      result = extractor.run

      expect(result[:success]).to be true
      expect(result[:stats][:found]).to eq(2)
      expect(result[:stats][:copied]).to eq(4) # 2 files * 2 target directories
      expect(result[:stats][:skipped]).to eq(0)
      expect(result[:stats][:overwritten]).to eq(0)

      # Check target dir 1
      expect(File.exist?(File.join(dest_dir1, "20260601_project1_character_image.png"))).to be true
      expect(File.exist?(File.join(dest_dir1, "20260601_project1_pages_page_1_illustration.png"))).to be true

      # Check target dir 2
      expect(File.exist?(File.join(dest_dir2, "20260601_project1_character_image.png"))).to be true
      expect(File.exist?(File.join(dest_dir2, "20260601_project1_pages_page_1_illustration.png"))).to be true
    end

    it "skips files if they exist and are of identical size" do
      # Pre-run
      described_class.new(source_dir: source_dir, targets: targets).run

      # Second run
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      result = extractor.run

      expect(result[:stats][:copied]).to eq(0)
      expect(result[:stats][:skipped]).to eq(4)
      expect(result[:stats][:overwritten]).to eq(0)
    end

    it "overwrites files if they exist but have different sizes" do
      # Pre-run
      described_class.new(source_dir: source_dir, targets: targets).run

      # Modify one source file to change its size
      File.write(File.join(source_dir, "20260601_project1/character_image.png"), "different and longer dummy content")

      # Second run
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      result = extractor.run

      expect(result[:stats][:copied]).to eq(0)
      expect(result[:stats][:skipped]).to eq(2) # The page_1 illustration remains identical (skipped on 2 targets)
      expect(result[:stats][:overwritten]).to eq(2) # The character_image has a different size (overwritten on 2 targets)

    end

    it "respects the dry_run flag" do
      extractor = described_class.new(source_dir: source_dir, targets: targets, dry_run: true)
      result = extractor.run

      expect(result[:stats][:copied]).to eq(4) # Stats still count it as planned copy
      expect(File.exist?(dest_dir1)).to be false
      expect(File.exist?(dest_dir2)).to be false
    end
  end
end
