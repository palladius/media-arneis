require "spec_helper"
require "arneis"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }
  let(:output_dir) { "out/test_redo" }
  let(:state_file) { File.join(output_dir, ".state.yaml") }

  before do
    FileUtils.mkdir_p(output_dir)
    state = {
      "story_title" => "Test Story",
      "status" => "done",
      "pages" => [
        {"page" => 1, "description" => "Page 1", "status" => "done"},
        {"page" => 2, "description" => "Page 2", "status" => "done"}
      ],
      "final_story_assembly" => {"status" => "done"}
    }
    File.write(state_file, state.to_yaml)

    # Page 1: Score 4 (Bad)
    page1_dir = File.join(output_dir, "pages/page_1")
    FileUtils.mkdir_p(page1_dir)
    File.write(File.join(page1_dir, "illustration.png"), "image 1")
    File.write(File.join(page1_dir, "illustration.png.asset.json"), {"eval_dummy" => {"score" => 4}}.to_json)

    # Page 2: Score 9 (Good)
    page2_dir = File.join(output_dir, "pages/page_2")
    FileUtils.mkdir_p(page2_dir)
    File.write(File.join(page2_dir, "illustration.png"), "image 2")
    File.write(File.join(page2_dir, "illustration.png.asset.json"), {"eval_dummy" => {"score" => 9}}.to_json)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "#redo" do
    it "invalidates artifacts below the threshold" do
      allow(cli).to receive(:options).and_return({threshold: 6})
      allow(cli).to receive(:invoke).with(:resume, [output_dir])
      cli.redo(output_dir)

      state = YAML.load_file(state_file)
      expect(state["pages"].find { |p| p["page"] == 1 }["status"]).to eq("pending")
      expect(state["pages"].find { |p| p["page"] == 2 }["status"]).to eq("done")

      expect(File.exist?(File.join(output_dir, "pages/page_1/illustration.png"))).to be false
      expect(Dir.glob(File.join(output_dir, ".trash/**/illustration.png"))).not_to be_empty
    end
  end
end
