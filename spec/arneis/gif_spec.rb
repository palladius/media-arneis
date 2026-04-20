require 'spec_helper'
require 'arneis/generator/gif'
require 'fileutils'
require 'tmpdir'

RSpec.describe Arneis::Generator::Gif do
  let(:tmp_dir) { Dir.mktmpdir('gif_test') }
  let(:input_file) { File.join(tmp_dir, 'input.mp4') }
  let(:output_file) { File.join(tmp_dir, 'output.gif') }
  subject { described_class.new }

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#generate' do
    it 'generates a mock GIF if input is missing' do
      result = subject.generate('missing.mp4', output_file)
      expect(result[:status]).to eq('mocked')
      expect(File.exist?("#{output_file}.mock")).to be true
    end

    it 'triggers ffmpeg when input exists' do
      File.write(input_file, "FAKE_VIDEO_CONTENT")
      # Mock system call to avoid real ffmpeg in unit test
      allow(subject).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(output_file).and_return(true)
      # Stub validator
      allow(Arneis::Validator).to receive(:validate_and_rename!).and_return({success: true})

      result = subject.generate(input_file, output_file)
      expect(result[:status]).to eq('done')
    end
  end
end
