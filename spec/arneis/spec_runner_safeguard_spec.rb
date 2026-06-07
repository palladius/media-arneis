# frozen_string_literal: true

require "spec_helper"
require "arneis/spec_runner_safeguard"

RSpec.describe Arneis::SpecRunnerSafeguard do
  let(:temp_history_file) { "tmp/test_spec_history.json" }
  let(:spec_file) { "spec/arneis/dummy_spec.rb" }
  let(:abs_spec_file) { File.expand_path(spec_file) }

  before do
    stub_const("Arneis::SpecRunnerSafeguard::HISTORY_FILE", temp_history_file)
    FileUtils.rm_f(temp_history_file)
  end

  after do
    FileUtils.rm_f(temp_history_file)
  end

  describe ".check!" do
    it "does not raise an error if history file does not exist" do
      expect {
        described_class.check!([spec_file])
      }.not_to raise_error
    end

    it "raises a circuit breaker error if a file has 3 or more consecutive failures" do
      history = {
        abs_spec_file => {
          "consecutive_failures" => 3,
          "last_run" => Time.now.iso8601
        }
      }
      FileUtils.mkdir_p(File.dirname(temp_history_file))
      File.write(temp_history_file, JSON.pretty_generate(history))

      expect {
        described_class.check!([spec_file])
      }.to raise_error(/CIRCUIT BREAKER/)
    end

    it "does not raise an error if consecutive failures are less than 3" do
      history = {
        abs_spec_file => {
          "consecutive_failures" => 2,
          "last_run" => Time.now.iso8601
        }
      }
      FileUtils.mkdir_p(File.dirname(temp_history_file))
      File.write(temp_history_file, JSON.pretty_generate(history))

      expect {
        described_class.check!([spec_file])
      }.not_to raise_error
    end
  end

  describe ".record_run!" do
    it "sets consecutive_failures to 0 on success" do
      described_class.record_run!([spec_file], true)
      data = JSON.parse(File.read(temp_history_file))
      expect(data[abs_spec_file]["consecutive_failures"]).to eq(0)
    end

    it "increments consecutive_failures on failure" do
      described_class.record_run!([spec_file], false)
      data = JSON.parse(File.read(temp_history_file))
      expect(data[abs_spec_file]["consecutive_failures"]).to eq(1)

      described_class.record_run!([spec_file], false)
      data = JSON.parse(File.read(temp_history_file))
      expect(data[abs_spec_file]["consecutive_failures"]).to eq(2)
    end
  end
end
