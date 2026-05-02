require "spec_helper"
require "arneis/config"

RSpec.describe Arneis::Config do
  before do
    # Clear environment variables before each test to ensure isolation
    @original_eval = ENV["ARNEIS_EVAL_ENABLED"]
    @original_open = ENV["ARNEIS_OPEN_ENABLED"]
    ENV.delete("ARNEIS_EVAL_ENABLED")
    ENV.delete("ARNEIS_OPEN_ENABLED")
  end

  after do
    ENV["ARNEIS_EVAL_ENABLED"] = @original_eval
    ENV["ARNEIS_OPEN_ENABLED"] = @original_open
  end

  describe ".eval_enabled?" do
    context "when flags are provided" do
      it "returns true if eval flag is true" do
        expect(Arneis::Config.eval_enabled?(eval: true)).to be true
      end

      it "returns false if eval flag is false" do
        expect(Arneis::Config.eval_enabled?(eval: false)).to be false
      end

      it "precedes environment variable" do
        ENV["ARNEIS_EVAL_ENABLED"] = "false"
        expect(Arneis::Config.eval_enabled?(eval: true)).to be true
      end
    end

    context "when only environment variable is set" do
      it "returns true if ARNEIS_EVAL_ENABLED is true" do
        ENV["ARNEIS_EVAL_ENABLED"] = "true"
        expect(Arneis::Config.eval_enabled?).to be true
      end

      it "returns false if ARNEIS_EVAL_ENABLED is false" do
        ENV["ARNEIS_EVAL_ENABLED"] = "false"
        expect(Arneis::Config.eval_enabled?).to be false
      end
    end

    context "when neither is set" do
      it "defaults to true" do
        expect(Arneis::Config.eval_enabled?).to be true
      end
    end
  end

  describe ".open_enabled?" do
    context "when flags are provided" do
      it "returns true if open flag is true" do
        expect(Arneis::Config.open_enabled?(open: true)).to be true
      end

      it "returns false if open flag is false" do
        expect(Arneis::Config.open_enabled?(open: false)).to be false
      end

      it "precedes environment variable" do
        ENV["ARNEIS_OPEN_ENABLED"] = "false"
        expect(Arneis::Config.open_enabled?(open: true)).to be true
      end
    end

    context "when only environment variable is set" do
      it "returns true if ARNEIS_OPEN_ENABLED is true" do
        ENV["ARNEIS_OPEN_ENABLED"] = "true"
        expect(Arneis::Config.open_enabled?).to be true
      end

      it "returns false if ARNEIS_OPEN_ENABLED is false" do
        ENV["ARNEIS_OPEN_ENABLED"] = "false"
        expect(Arneis::Config.open_enabled?).to be false
      end
    end

    context "when neither is set" do
      it "defaults to true" do
        expect(Arneis::Config.open_enabled?).to be true
      end
    end
  end
end
