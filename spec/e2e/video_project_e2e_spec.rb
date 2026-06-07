require "spec_helper"
require "arneis"

RSpec.describe "VideoProject End-to-End", :expensive do
  let(:sample_yaml) { "data/samples/VideoProject/rubycon_pitch.yaml" }
  let(:output_dir) { "out/e2e_video_project_#{Time.now.to_i}" }

  before(:all) do
    ENV["ARNEIS_NO_MOCK"] = "true"
  end

  it "successfully generates a full video project without mocks" do
    cmd = "bundle exec bin/arnectl apply #{sample_yaml} -o #{output_dir} --no-async"
    puts "\n🚀 Running E2E command: #{cmd}"

    success = system(cmd)
    expect(success).to be true

    # 1. Verify Directory Structure
    expect(Dir.exist?(output_dir)).to be true
    expect(Dir.exist?(File.join(output_dir, "video"))).to be true
    expect(Dir.exist?(File.join(output_dir, "audio"))).to be true

    # 2. Verify Scene Artifacts
    # Sample has 5 scenes
    (1..5).each do |i|
      scene_dir = File.join(output_dir, "video", "scene_#{i}")
      expect(Dir.exist?(scene_dir)).to be true

      video_file = File.join(scene_dir, "video.mp4")
      expect(File.exist?(video_file)).to be true
      expect(File.exist?("#{video_file}.mock")).to be false
    end

    # 3. Verify Final Artifacts
    expect(File.exist?(File.join(output_dir, "audio", "background_music.wav"))).to be true
    expect(File.exist?(File.join(output_dir, "rubycon_pitch_from_plan.mp4"))).to be true
  end
end
