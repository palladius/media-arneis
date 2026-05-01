require "spec_helper"
require "arneis/config"

RSpec.describe Arneis::Config do
  describe ".no_mock?" do
    before do
      @original_no_mock = ENV["ARNEIS_NO_MOCK"]
    end

    after do
      ENV["ARNEIS_NO_MOCK"] = @original_no_mock
    end

    it "returns true if ARNEIS_NO_MOCK is 'true'" do
      ENV["ARNEIS_NO_MOCK"] = "true"
      expect(Arneis::Config.no_mock?).to be true
    end

    it "returns true if ARNEIS_NO_MOCK is '1'" do
      ENV["ARNEIS_NO_MOCK"] = "1"
      expect(Arneis::Config.no_mock?).to be true
    end

    it "returns false if ARNEIS_NO_MOCK is 'false'" do
      ENV["ARNEIS_NO_MOCK"] = "false"
      expect(Arneis::Config.no_mock?).to be false
    end

    it "returns false if ARNEIS_NO_MOCK is not set" do
      ENV.delete("ARNEIS_NO_MOCK")
      expect(Arneis::Config.no_mock?).to be false
    end
  end
end
