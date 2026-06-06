require "spec_helper"
require "arneis/task"
require "arneis/config"
require "arneis/orchestrator"

RSpec.describe Arneis::Orchestrator do
  it "executes tasks in the correct order based on dependencies" do
    orchestrator = described_class.new
    execution_order = []

    orchestrator.add_task(:task1) do
      execution_order << :task1
    end

    orchestrator.add_task(:task2, dependencies: [:task1]) do
      execution_order << :task2
    end

    orchestrator.add_task(:task3, dependencies: [:task2]) do
      execution_order << :task3
    end

    orchestrator.run

    expect(execution_order).to eq([:task1, :task2, :task3])
    expect(orchestrator.completed_tasks).to include(:task1, :task2, :task3)
  end

  it "runs independent tasks" do
    orchestrator = described_class.new
    completed = []

    orchestrator.add_task(:task_a) { completed << :task_a }
    orchestrator.add_task(:task_b) { completed << :task_b }

    orchestrator.run

    expect(completed).to include(:task_a, :task_b)
  end

  describe "verification failures and retry hints" do
    let(:orchestrator) { described_class.new(verify: true) }

    it "prints a retry hint pointing to the run folder and kind when verification fails" do
      orchestrator.add_task(:test_task, outputs: {"out/run_456/image.png" => :image}) do
        # Do nothing, just succeed execution so verification gets triggered
      end

      allow(Arneis::Validator).to receive(:verify_assets).and_return({success: false, message: "Missing image"})

      allow(Dir).to receive(:exist?).with("out/run_456").and_return(true)
      allow(Dir).to receive(:glob).with("out/run_456/*.yaml").and_return(["out/run_456/spec.yaml"])

      mock_spec = {
        "kind" => "KidsStory"
      }
      allow(YAML).to receive(:load_file).with("out/run_456/spec.yaml").and_return(mock_spec)
      allow(File).to receive(:write) # prevent actually writing asset.json

      expect { orchestrator.run }.to output(
        a_string_including("To retry with eval feedback, run:")
        .and(a_string_including("arnectl generate KidsStory --retry run_456"))
      ).to_stdout
    end
  end
end
