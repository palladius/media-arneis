# frozen_string_literal: true

require "spec_helper"
require "arneis/context_monitor"

RSpec.describe Arneis::ContextMonitor do
  let(:temp_dir) { "tmp/test_brain" }
  let(:conversation_id) { "test-conv-12345" }
  let(:transcript_dir) { File.join(temp_dir, conversation_id, ".system_generated", "logs") }
  let(:transcript_path) { File.join(transcript_dir, "transcript.jsonl") }

  before do
    FileUtils.rm_rf(temp_dir)
    FileUtils.mkdir_p(transcript_dir)
    stub_const("Arneis::ContextMonitor::BRAIN_DIR", temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ".count_steps" do
    it "returns 0 when no transcript file exists" do
      expect(described_class.count_steps("nonexistent-id")).to eq(0)
    end

    it "counts lines in a JSONL transcript file" do
      lines = 5.times.map { |i| %({"step_index":#{i},"type":"PLANNER_RESPONSE"}) }
      File.write(transcript_path, lines.join("\n") + "\n")

      expect(described_class.count_steps(conversation_id)).to eq(5)
    end

    it "counts a large number of steps correctly" do
      lines = 1500.times.map { |i| %({"step_index":#{i},"type":"PLANNER_RESPONSE"}) }
      File.write(transcript_path, lines.join("\n") + "\n")

      expect(described_class.count_steps(conversation_id)).to eq(1500)
    end
  end

  describe ".find_latest_conversation" do
    it "returns nil when brain directory is empty" do
      FileUtils.rm_rf(temp_dir)
      FileUtils.mkdir_p(temp_dir)
      expect(described_class.find_latest_conversation).to be_nil
    end

    it "returns the conversation with the most recent transcript" do
      # Create two conversations, the second one with a newer file
      conv_a_dir = File.join(temp_dir, "conv-aaa", ".system_generated", "logs")
      conv_b_dir = File.join(temp_dir, "conv-bbb", ".system_generated", "logs")
      FileUtils.mkdir_p(conv_a_dir)
      FileUtils.mkdir_p(conv_b_dir)
      File.write(File.join(conv_a_dir, "transcript.jsonl"), %({"step_index":0}\n))
      sleep 0.05 # ensure different mtime
      File.write(File.join(conv_b_dir, "transcript.jsonl"), %({"step_index":0}\n))

      expect(described_class.find_latest_conversation).to eq("conv-bbb")
    end
  end

  describe ".check_and_warn!" do
    it "outputs no warning when steps are below threshold" do
      lines = 10.times.map { |i| %({"step_index":#{i}}) }
      File.write(transcript_path, lines.join("\n") + "\n")

      expect { described_class.check_and_warn!(conversation_id) }.not_to output.to_stderr
    end

    it "outputs a colored warning when steps exceed 1000" do
      lines = 1050.times.map { |i| %({"step_index":#{i}}) }
      File.write(transcript_path, lines.join("\n") + "\n")

      expect { described_class.check_and_warn!(conversation_id) }.to output(
        /CONTEXT SIZE WARNING.*1050 steps/m
      ).to_stderr
    end

    it "warns with a configurable threshold" do
      lines = 50.times.map { |i| %({"step_index":#{i}}) }
      File.write(transcript_path, lines.join("\n") + "\n")

      expect { described_class.check_and_warn!(conversation_id, threshold: 30) }.to output(
        /CONTEXT SIZE WARNING.*50 steps/m
      ).to_stderr
    end
  end
end
