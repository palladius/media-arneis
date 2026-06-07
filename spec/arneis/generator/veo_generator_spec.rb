require "spec_helper"
require "arneis" # Load the entire Arneis module to ensure all dependencies are met.
require "shellwords"

RSpec.describe Arneis::Generator::Veo do
  let(:output_file) { "tmp/veo_test_output.mp4" }
  let(:prompt) { "A test prompt with 'quotes', `backticks`, and $money symbols." }
  let(:mock_veo_script_path) { "tmp/mock_veo_script.py" }

  before do
    FileUtils.mkdir_p("tmp")
    # Create a mock Python script that just prints the command line arguments
    File.write(mock_veo_script_path, <<~PYTHON
      #!/usr/bin/env python3
      import sys
      # Just print the arguments to stderr for inspection
      print(f"MOCK_VEO_SCRIPT_ARGS: {sys.argv[1:]}", file=sys.stderr)
      # Simulate success if not checking status
      if "--check-status" not in sys.argv:
        with open("mock_output.mp4", "w") as f: # Create the dummy file
          f.write("mock video content")
        print("MEDIA:mock_output.mp4")
    PYTHON
    )
    FileUtils.chmod(0o755, mock_veo_script_path)

    allow(Arneis::Config).to receive(:veo_script).and_return(mock_veo_script_path)
    allow(Arneis::Config).to receive(:google_cloud_project).and_return("test-project")
    allow(Arneis::Config).to receive(:google_cloud_region).and_return("us-central1")
    allow(Arneis::Config).to receive(:genmedia_bucket).and_return("test-bucket")
  end

  after do
    FileUtils.rm_rf("tmp")
  end

  describe "#generate" do
    context "with a complex prompt" do
      it "escapes the prompt correctly for the shell command" do
        generator = Arneis::Generator::Veo.new

        # We need to capture the Open3.popen3 call to inspect the actual command
        expect(Open3).to receive(:popen3) do |env, cmd_str|
          expect(cmd_str).to include("uv run #{mock_veo_script_path}")
          # Check that the prompt is correctly escaped as a single argument
          expected_escaped_prompt = Shellwords.escape(prompt)
          expect(cmd_str).to include(expected_escaped_prompt)
          # Ensure it's not wrapped in extra quotes by our code, as Shellwords.escape handles that
          expect(cmd_str).not_to include("\"#{expected_escaped_prompt}\"")

          # Simulate successful execution for the purpose of this test
          [double("stdin", close: nil), double("stdout", gets: nil), double("stderr", gets: nil), double("wait_thr", value: double(success?: true), join: nil)]
        end.and_call_original # allow other calls to popen3 if any

        generator.generate(prompt, output_file)
      end
    end

    context "when Config.no_mock? is true and not dryrun" do
      before do
        allow(Arneis::Config).to receive(:no_mock?).and_return(true)
        allow(Arneis::Config).to receive(:dryrun?).and_return(false)
        # Stubbing external calls to avoid real AI requests and focus on the logic
        allow(Open3).to receive(:popen3).and_raise("Simulated Veo Failure")
      end

      it "raises an error instead of falling back to mock" do
        generator = Arneis::Generator::Veo.new
        expect {
          generator.generate("fail prompt", output_file)
        }.to raise_error("Simulated Veo Failure")
        expect(File.exist?("#{output_file}.mock")).to be false
      end
    end

    context "when dryrun? is true" do
      before do
        allow(Arneis::Config).to receive(:dryrun?).and_return(true)
        # Expect maybe_mock to be called, as maybe_mock short-circuits external calls
        expect_any_instance_of(Arneis::Generator::Veo).to receive(:maybe_mock).and_call_original
      end

      it "produces a mock file and does not call external script" do
        generator = Arneis::Generator::Veo.new
        res = generator.generate("dryrun prompt", output_file)
        expect(res[:status]).to eq("mocked")
        expect(File.exist?("#{output_file}.mock")).to be true
      end
    end
  end
end
