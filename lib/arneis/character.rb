=begin
Arneis::Character - Model for character data.
=end

require 'yaml'
require 'date'

module Arneis
  class Character
    CHARACTERS_DIR = File.expand_path("../../data/characters", __dir__)

    attr_reader :name, :nickname, :surname, :personality, :visual_look, :consistency_images_dir, :id, :emoji, :nationality_emoji

    def self.all
      # Case 1: data/characters/*.yaml
      # Case 2: data/characters/*/character.yaml
      files = Dir.glob(File.join(CHARACTERS_DIR, "*.yaml")) +
              Dir.glob(File.join(CHARACTERS_DIR, "*/character.yaml"))
      files.uniq.map do |file|
        new(file)
      end.sort_by(&:name)
    end

    def self.find(name_or_nickname)
      all.find do |c|
        c.name&.downcase == name_or_nickname.downcase ||
        c.nickname&.downcase == name_or_nickname.downcase ||
        c.id.downcase == name_or_nickname.downcase
      end
    end

    attr_reader :yaml_path

    def initialize(yaml_path)
      @yaml_path = yaml_path
      @data = YAML.load_file(yaml_path, permitted_classes: [Date, Time])
      @name = @data['name']
      @surname = @data['surname']
      @nickname = @data['nickname']
      @personality = @data['personality']
      @visual_look = @data['visual_look']
      @consistency_images_dir = @data['consistency_images']
      @emoji = @data['emoji'] || "👤"
      @nationality_emoji = @data['nationality_emoji'] || "🌍"
      
      @id = if yaml_path.end_with?('character.yaml')
              File.basename(File.dirname(yaml_path))
            else
              File.basename(yaml_path, '.yaml')
            end
    end

    def full_name
      [@name, @surname].compact.join(" ")
    end

    def image_count
      return 0 unless @consistency_images_dir
      # If relative to YAML path (starts with .)
      base_dir = @yaml_path.end_with?('character.yaml') ? File.dirname(@yaml_path) : CHARACTERS_DIR
      dir = File.expand_path(@consistency_images_dir, base_dir)

      return 0 unless Dir.exist?(dir)
      # Count images but exclude hidden files
      Dir.glob(File.join(dir, "*")).reject { |f| File.directory?(f) || File.basename(f).start_with?('.') }.count
    end
  end
end
