require 'spec_helper'
require 'tmpdir'
require 'arneis/video_project'

RSpec.describe Arneis::VideoProject do
  let(:valid_yaml_path) { 'spec/fixtures/video_plan.yaml' }

  it 'correctly parses a valid video_plan.yaml' do
    project = described_class.new(valid_yaml_path)
    expect(project.title).to eq('Rubycon Pitch Video')
    expect(project.scenes.size).to eq(2)
  end

  it 'raises an error for missing title' do
    allow(YAML).to receive(:load_file).and_return({ 'scenes' => [] })
    expect { described_class.new('any.yaml') }.to raise_error(/Missing 'title'/)
  end

  it 'creates a deterministic output folder' do
    Dir.mktmpdir do |tmp_dir|
      project = described_class.new(valid_yaml_path)
      output_path = File.join(tmp_dir, 'out_test')
      project.initialize_output(output_path)
      expect(Dir.exist?(output_path)).to be true
      expect(File.exist?(File.join(output_path, '.state.yaml'))).to be true
    end
  end
end
