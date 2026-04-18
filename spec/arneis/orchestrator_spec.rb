require 'spec_helper'
require 'arneis/task'
require 'arneis/orchestrator'

RSpec.describe Arneis::Orchestrator do
  it 'executes tasks in the correct order based on dependencies' do
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

  it 'runs independent tasks' do
    orchestrator = described_class.new
    completed = []

    orchestrator.add_task(:task_a) { completed << :task_a }
    orchestrator.add_task(:task_b) { completed << :task_b }

    orchestrator.run

    expect(completed).to include(:task_a, :task_b)
  end
end
