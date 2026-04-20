require 'spec_helper'
require 'arneis/planner'
require 'fileutils'
require 'tmpdir'

RSpec.describe Arneis::Planner do
  let(:tmp_dir) { Dir.mktmpdir('planner_test') }
  subject { described_class.new(tmp_dir) }

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#all_plans' do
    it 'finds and sorts plans by revision' do
      File.write(File.join(tmp_dir, 'plan__rev2.md'), 'rev: 2')
      File.write(File.join(tmp_dir, 'plan__rev1.md'), 'rev: 1')
      File.write(File.join(tmp_dir, 'random.md'), 'no rev')

      plans = subject.all_plans
      expect(plans.size).to eq(2)
      expect(File.basename(plans.first)).to eq('plan__rev1.md')
      expect(File.basename(plans.last)).to eq('plan__rev2.md')
    end
  end

  describe '#extract_revision' do
    it 'extracts from filename' do
      expect(subject.extract_revision('test__rev5.md')).to eq(5)
    end

    it 'returns 0 for non-matching files' do
      expect(subject.extract_revision('test.md')).to eq(0)
    end
  end

  describe '#valid_plan?' do
    it 'is true if internal rev matches filename' do
      path = File.join(tmp_dir, 'plan__rev1.md')
      File.write(path, "Some content\nrev: 1")
      expect(subject.valid_plan?(path)).to be true
    end

    it 'is false if internal rev is missing' do
      path = File.join(tmp_dir, 'plan__rev1.md')
      File.write(path, "Some content")
      expect(subject.valid_plan?(path)).to be false
    end
  end

  describe '#latest_plan' do
    it 'returns the file with highest revision' do
      File.write(File.join(tmp_dir, 'plan__rev1.md'), 'rev: 1')
      File.write(File.join(tmp_dir, 'plan__rev10.md'), 'rev: 10')
      
      expect(File.basename(subject.latest_plan)).to eq('plan__rev10.md')
    end
  end
end
