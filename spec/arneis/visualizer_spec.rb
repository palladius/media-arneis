require 'spec_helper'
require 'arneis/task'
require 'arneis/visualizer'

RSpec.describe Arneis::Visualizer do
  it 'generates a basic Mermaid graph' do
    tasks = [
      Arneis::Task.new(:task1),
      Arneis::Task.new(:task2, dependencies: [:task1])
    ]
    visualizer = described_class.new(tasks)
    mermaid = visualizer.to_mermaid

    expect(mermaid).to include('graph LR')
    expect(mermaid).to include('task1["task1"]')
    expect(mermaid).to include('task2["task2"]')
    expect(mermaid).to include('task1 --> task2')
  end
end
