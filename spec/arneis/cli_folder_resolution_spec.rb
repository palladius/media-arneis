require "spec_helper"
require "arneis"

RSpec.describe Arneis::Cli do
  let(:cli) { described_class.new }

  describe "#resolve_media_folder" do
    let(:mock_env) { {} }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ARNEIS_FOLDER").and_wrap_original do
        mock_env["ARNEIS_FOLDER"]
      end
    end

    it "prefers the flag over positional argument and ENV" do
      mock_env["ARNEIS_FOLDER"] = "env_folder"
      options = {"media_folder" => "flag_folder"}
      args = ["positional_folder"]

      expect(cli.send(:resolve_media_folder, args, options)).to eq("flag_folder")
    end

    it "prefers the positional argument over ENV if flag is missing" do
      mock_env["ARNEIS_FOLDER"] = "env_folder"
      options = {}
      args = ["positional_folder"]

      expect(cli.send(:resolve_media_folder, args, options)).to eq("positional_folder")
    end

    it "falls back to ENV if flag and positional argument are missing" do
      mock_env["ARNEIS_FOLDER"] = "env_folder"
      options = {}
      args = []

      expect(cli.send(:resolve_media_folder, args, options)).to eq("env_folder")
    end

    it "raises an error if no folder is found" do
      mock_env["ARNEIS_FOLDER"] = nil
      options = {}
      args = []

      expect { cli.send(:resolve_media_folder, args, options) }.to raise_error(/No media folder specified/)
    end
  end
end
