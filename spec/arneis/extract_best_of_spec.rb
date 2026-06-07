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
    FileUtils.mkdir_p(File.join(source_dir, "20260601_rubycon_talk"))
    FileUtils.mkdir_p(File.join(source_dir, "20260601_sebastian_pokemon"))

    # Create dummy images
    File.write(File.join(source_dir, "20260601_project1/character_image.png"), "dummy content image 1")
    File.write(File.join(source_dir, "20260601_project1/pages/page_1/illustration.png"), "dummy content image 2")
    File.write(File.join(source_dir, "20260601_rubycon_talk/logo.png"), "rubycon logo content")
    File.write(File.join(source_dir, "20260601_sebastian_pokemon/character_image.png"), "seby pokemon content")

    # Create dummy videos
    File.write(File.join(source_dir, "20260601_project1/video.mp4"), "dummy video content")
    File.write(File.join(source_dir, "20260601_rubycon_talk/presentation_video.webm"), "rubycon video content")
    
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
    it "finds only images and videos and respects exclusions" do
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      files = extractor.find_files

      expect(files).to contain_exactly(
        "tmp_test_src/20260601_project1/character_image.png",
        "tmp_test_src/20260601_project1/pages/page_1/illustration.png",
        "tmp_test_src/20260601_rubycon_talk/logo.png",
        "tmp_test_src/20260601_sebastian_pokemon/character_image.png",
        "tmp_test_src/20260601_project1/video.mp4",
        "tmp_test_src/20260601_rubycon_talk/presentation_video.webm"
      )
    end
  end

  describe "#run" do
    it "copies images to pics/ and videos to videos/ with flat subfolder categorization" do
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      result = extractor.run

      expect(result[:success]).to be true
      expect(result[:stats][:found]).to eq(6)
      expect(result[:stats][:copied]).to eq(12) # 6 files * 2 target directories
      expect(result[:stats][:skipped]).to eq(0)
      expect(result[:stats][:overwritten]).to eq(0)

      # Check target dir 1 (Images)
      expect(File.exist?(File.join(dest_dir1, "pics/20260601_project1_character_image.png"))).to be true
      expect(File.exist?(File.join(dest_dir1, "pics/20260601_project1_pages_page_1_illustration.png"))).to be true
      expect(File.exist?(File.join(dest_dir1, "pics/rubycon/20260601_rubycon_talk_logo.png"))).to be true
      expect(File.exist?(File.join(dest_dir1, "pics/family/20260601_sebastian_pokemon_character_image.png"))).to be true

      # Check target dir 1 (Videos)
      expect(File.exist?(File.join(dest_dir1, "videos/20260601_project1_video.mp4"))).to be true
      expect(File.exist?(File.join(dest_dir1, "videos/rubycon/20260601_rubycon_talk_presentation_video.webm"))).to be true

      # Check target dir 2
      expect(File.exist?(File.join(dest_dir2, "pics/20260601_project1_character_image.png"))).to be true
      expect(File.exist?(File.join(dest_dir2, "videos/20260601_project1_video.mp4"))).to be true
    end

    it "skips files if they exist and are of identical size" do
      # Pre-run
      described_class.new(source_dir: source_dir, targets: targets).run

      # Second run
      extractor = described_class.new(source_dir: source_dir, targets: targets)
      result = extractor.run

      expect(result[:stats][:copied]).to eq(0)
      expect(result[:stats][:skipped]).to eq(12)
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
      expect(result[:stats][:skipped]).to eq(10) # 5 unchanged files * 2 targets
      expect(result[:stats][:overwritten]).to eq(2) # 1 changed file * 2 targets
    end

    it "respects the dry_run flag" do
      extractor = described_class.new(source_dir: source_dir, targets: targets, dry_run: true)
      result = extractor.run

      expect(result[:stats][:copied]).to eq(12) # Stats still count it as planned copy
      expect(File.exist?(dest_dir1)).to be false
      expect(File.exist?(dest_dir2)).to be false
    end
  end

  describe "rotation and cleanup" do
    let(:current_prefix) { Time.now.strftime("%Y%m%d_%H%M%S") }
    let(:old_dir) { File.join(source_dir, "20200101_000000_old_project") }
    let(:new_dir) { File.join(source_dir, "#{current_prefix}_new_project") }

    before do
      FileUtils.mkdir_p(old_dir)
      File.write(File.join(old_dir, "illustration.png"), "dummy")

      FileUtils.mkdir_p(new_dir)
      File.write(File.join(new_dir, "illustration.png"), "dummy")
    end

    it "only trashes folders older than the rotate_days threshold when clean is true" do
      extractor = described_class.new(
        source_dir: source_dir,
        targets: targets,
        clean: true,
        rotate_days: 7,
        auto_approve: true
      )
      result = extractor.run

      expect(result[:success]).to be true
      expect(result[:deleted].map { |d| File.basename(d) }).to contain_exactly("20200101_000000_old_project")

      expect(Dir.exist?(old_dir)).to be false
      expect(Dir.exist?(new_dir)).to be true

      # Check that it exists inside the .trash directory
      trash_dir = File.join(source_dir, ".trash")
      trashed_folders = Dir.glob(File.join(trash_dir, "**/20200101_000000_old_project"))
      expect(trashed_folders.any? { |f| Dir.exist?(f) }).to be true
    end

    it "does not delete folders if dry_run is true" do
      extractor = described_class.new(
        source_dir: source_dir,
        targets: targets,
        clean: true,
        rotate_days: 7,
        dry_run: true,
        auto_approve: true
      )
      result = extractor.run

      expect(result[:success]).to be true
      expect(result[:deleted].map { |d| File.basename(d) }).to contain_exactly("20200101_000000_old_project")

      expect(Dir.exist?(old_dir)).to be true
      expect(Dir.exist?(new_dir)).to be true
    end
  end
end
