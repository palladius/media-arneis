require 'spec_helper'
require 'arneis/schema'
require 'tempfile'
require 'yaml'

RSpec.describe Arneis::Schema do
  let(:valid_video_project) do
    {
      'apiVersion' => 'media-arneis.palladius.it/v1',
      'kind' => 'VideoProject',
      'metadata' => { 'name' => 'test-video' },
      'spec' => {
        'project_title' => 'Test Project',
        'scenes' => [
          { 'scene' => 1, 'description' => 'Scene 1' }
        ]
      }
    }
  end

  describe '.validate_template' do
    it 'passes for a valid VideoProject' do
      file = Tempfile.new(['template', '.yaml'])
      file.write(valid_video_project.to_yaml)
      file.close
      
      result = described_class.validate_template(file.path)
      expect(result[:success]).to be true
    end

    it 'fails for invalid apiVersion' do
      invalid = valid_video_project.merge('apiVersion' => 'invalid/v1')
      file = Tempfile.new(['template', '.yaml'])
      file.write(invalid.to_yaml)
      file.close
      
      result = described_class.validate_template(file.path)
      expect(result[:success]).to be false
      expect(result[:message]).to include('apiVersion')
    end

    it 'fails for missing required fields' do
      invalid = valid_video_project.dup
      invalid['spec'].delete('scenes')
      file = Tempfile.new(['template', '.yaml'])
      file.write(invalid.to_yaml)
      file.close
      
      result = described_class.validate_template(file.path)
      expect(result[:success]).to be false
      expect(result[:message]).to include('scenes')
    end
  end
end

RSpec.describe Arneis::Hydrator do
  describe '.hydrate' do
    it 'merges template and sample correctly' do
      template = {
        'apiVersion' => 'media-arneis.palladius.it/v1',
        'kind' => 'VideoProject',
        'metadata' => { 'name' => 'VideoProject' },
        'spec' => { 'project_title' => 'Default Title', 'output_filename' => 'final.mp4' }
      }
      sample = {
        'metadata' => { 'template' => 'VideoProject', 'name' => 'my-pitch' },
        'spec' => { 'project_title' => 'Override Title' }
      }
      
      # Mock file system for test
      allow(File).to receive(:exist?).with('data/samples/pitch.yaml').and_return(true)
      allow(YAML).to receive(:load_file).with('data/samples/pitch.yaml').and_return(sample)
      allow(File).to receive(:exist?).with('data/templates/VideoProject.yaml').and_return(true)
      allow(YAML).to receive(:load_file).with('data/templates/VideoProject.yaml').and_return(template)

      result = described_class.hydrate('data/samples/pitch.yaml')
      expect(result[:success]).to be true
      expect(result[:data]['spec']['project_title']).to eq('Override Title')
      expect(result[:data]['spec']['output_filename']).to eq('final.mp4')
      expect(result[:data]['metadata']['name']).to eq('my-pitch')
    end
  end
end
