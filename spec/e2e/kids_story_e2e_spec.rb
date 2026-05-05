require "spec_helper"
require "arneis"

RSpec.describe "KidsStory End-to-End", :expensive do
  let(:sample_yaml) { "data/samples/KidsStory/riccardo_story.yaml" }
  let(:output_dir) { "out/e2e_kids_story_#{Time.now.to_i}" }

  before(:all) do
    # Ensure ARNEIS_NO_MOCK is set for the E2E run
    ENV["ARNEIS_NO_MOCK"] = "true"
  end

  after(:all) do
    # Cleanup if needed, but keeping for manual inspection if it fails is better
    # FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  it "successfully generates a full story with images and audio without mocks" do
    # Run the arnectl apply command
    cmd = "bundle exec bin/arnectl apply #{sample_yaml} -o #{output_dir} --no-async"
    puts "\n🚀 Running E2E command: #{cmd}"
    
    success = system(cmd)
    expect(success).to be true

    # 1. Verify Directory Structure
    expect(Dir.exist?(output_dir)).to be true
    expect(Dir.exist?(File.join(output_dir, "pages"))).to be true
    expect(Dir.exist?(File.join(output_dir, "audio"))).to be true

    # 2. Verify Page Artifacts
    # Sample has 3 pages
    (1..3).each do |i|
      page_dir = File.join(output_dir, "pages", "page_#{i}")
      expect(Dir.exist?(page_dir)).to be true
      
      # Images
      img_file = File.join(page_dir, "illustration.png")
      expect(File.exist?(img_file)).to be true
      expect(File.exist?("#{img_file}.mock")).to be false
      
      # Check asset json for evaluation
      asset_json = "#{img_file}.asset.json"
      expect(File.exist?(asset_json)).to be true
      asset_data = JSON.parse(File.read(asset_json))
      expect(asset_data["eval"]).not_to be_nil
      expect(asset_data["eval"]["score"]).to be >= 1

      # Audio (per language: it, en)
      ["it", "en"].each do |lang|
        audio_file = File.join(page_dir, "audio_#{lang}.wav")
        expect(File.exist?(audio_file)).to be true
        expect(File.exist?("#{audio_file}.mock")).to be false
        
        # Audio Eval
        audio_asset_json = "#{audio_file}.asset.json"
        expect(File.exist?(audio_asset_json)).to be true
        audio_asset_data = JSON.parse(File.read(audio_asset_json))
        expect(audio_asset_data["eval"]).not_to be_nil
        expect(audio_asset_data["eval"]["similarity"]).to be >= 50 # Allow some leeway for multimodal eval
      end
    end

    # 3. Verify Final Artifacts
    expect(File.exist?(File.join(output_dir, "audio", "final_story_it.wav"))).to be true
    expect(File.exist?(File.join(output_dir, "audio", "final_story_en.wav"))).to be true
    expect(File.exist?(File.join(output_dir, "STORY.md"))).to be true
    
    story_content = File.read(File.join(output_dir, "STORY.md"))
    expect(story_content).to include("Riccardo")
    expect(story_content).to include("audio/final_story_it.wav")
  end
end
