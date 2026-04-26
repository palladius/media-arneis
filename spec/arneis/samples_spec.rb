require "spec_helper"
require "arneis"

RSpec.describe "Data Samples" do
  Dir.glob("data/samples/**/*.yaml").each do |sample_path|
    describe "Sample: #{File.basename(sample_path)}" do
      it "can be hydrated and validated successfully" do
        # We wrap it in a project initialization which performs both hydration and validation
        expect { Arneis::VideoProject.new(sample_path) }.not_to raise_error
      end
    end
  end
end
