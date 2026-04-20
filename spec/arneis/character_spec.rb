require 'spec_helper'
require 'arneis/character'

RSpec.describe Arneis::Character do
  describe '.all' do
    it 'returns all characters from data/characters' do
      chars = described_class.all
      expect(chars).to be_an(Array)
      expect(chars.any? { |c| c.id == 'riccardo' }).to be true
    end
  end

  describe '#full_name' do
    it 'joins name and surname' do
      char = described_class.new(File.expand_path('../../data/characters/riccardo/character.yaml', __dir__))
      expect(char.full_name).to include('Riccardo')
    end
  end
end
