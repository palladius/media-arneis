require "spec_helper"
require "arneis"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }
  let(:output_dir) { "out/test_status_eval" }
  let(:state_file) { File.join(output_dir, ".state.yaml") }

  before do
    FileUtils.mkdir_p(output_dir)
    state = {
      "story_title" => "Test Story",
      "status" => "done",
      "pages" => [
        { "page" => 1, "description" => "Page 1", "status" => "done" }
      ],
      "final_story_assembly" => { "status" => "done" }
    }
    File.write(state_file, state.to_yaml)
    
    # Mocking a low score asset json
    asset_json = File.join(output_dir, "pages/page_1/illustration.png.asset.json")
    FileUtils.mkdir_p(File.dirname(asset_json))
    asset_data = {
      "eval_dummy" => { "success" => false, "score" => 4, "message" => "Bad" }
    }
    File.write(asset_json, asset_data.to_json)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "#status" do
    it "detects low scores and suggests a redo command" do
      # Use a regex that is very flexible with whitespace and ANSI codes
      expect { cli.status(output_dir) }.to output(/arnectl redo.*--threshold 6/m).to_stdout
    end
  end
end
