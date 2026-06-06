require "spec_helper"
require "arneis/feedback_loader"

RSpec.describe Arneis::FeedbackLoader do
  let(:temp_dir) { "tmp/test_feedback_loader" }
  let(:state_file) { File.join(temp_dir, ".state.yaml") }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it "raises an error if folder_path does not exist" do
    expect {
      described_class.load("non_existent_folder")
    }.to raise_error(/Directory does not exist/)
  end

  it "returns empty feedback structure if files do not exist" do
    fb = described_class.load(temp_dir)
    expect(fb).to eq({
      original_command: nil,
      original_prompt: nil,
      eval_errors: [],
      previous_image: nil
    })
  end

  it "loads metadata from .state.yaml and recursively parses .asset.json files" do
    # 1. Write .state.yaml
    state_data = {
      "original_command" => "arnectl generate CharacterImage -c riccardo -p 'superhero'",
      "prompt" => "superhero"
    }
    File.write(state_file, state_data.to_yaml)

    # 2. Write an asset.json file
    sub_dir = File.join(temp_dir, "pages", "page_1")
    FileUtils.mkdir_p(sub_dir)
    asset_file = File.join(sub_dir, "illustration.png")
    asset_json = "#{asset_file}.asset.json"

    # Create dummy image file to satisfy File.exist?(previous_image) check
    File.write(asset_file, "dummy image content")

    asset_data = {
      "asset_id" => "page_1_image",
      "prompt" => "superhero in a cape",
      "verification" => [
        {"type" => "asset_integrity", "success" => true, "message" => "Files found"},
        {"type" => "multimodal_intent", "success" => false, "message" => "No cape visible"}
      ]
    }
    File.write(asset_json, asset_data.to_json)

    # 3. Load feedback
    fb = described_class.load(temp_dir)

    expect(fb[:original_command]).to eq("arnectl generate CharacterImage -c riccardo -p 'superhero'")
    expect(fb[:original_prompt]).to eq("superhero")
    expect(fb[:eval_errors]).to eq(["No cape visible"])
    expect(fb[:previous_image]).to eq(asset_file)
  end

  it "falls back to asset prompt if state prompt is nil" do
    state_data = {
      "original_command" => "arnectl generate CharacterImage"
    }
    File.write(state_file, state_data.to_yaml)

    sub_dir = File.join(temp_dir, "pages", "page_1")
    FileUtils.mkdir_p(sub_dir)
    asset_file = File.join(sub_dir, "illustration.png")
    asset_json = "#{asset_file}.asset.json"
    File.write(asset_file, "dummy")

    asset_data = {
      "prompt" => "fallback asset prompt",
      "verification" => []
    }
    File.write(asset_json, asset_data.to_json)

    fb = described_class.load(temp_dir)
    expect(fb[:original_prompt]).to eq("fallback asset prompt")
  end
end
