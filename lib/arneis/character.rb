=begin
Arneis::Character - Model for character data.
=end

require 'yaml'

module Arneis
  class Character
    CHARACTERS_DIR = File.expand_path("../../data/characters", __dir__)

    attr_reader :name, :nickname, :surname, :personality, :visual_look, :consistency_images_dir

    def self.all
      Dir.glob(File.join(CHARACTERS_DIR, "*.yaml")).map do |file|
        new(file)
      end.sort_by(&:name)
    end

    def self.find(name_or_nickname)
      all.find do |c| 
        c.name&.downcase == name_or_nickname.downcase || 
        c.nickname&.downcase == name_or_nickname.downcase ||
        File.basename(c.yaml_path, '.yaml').downcase == name_or_nickname.downcase
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
    end

    def image_count
      return 0 unless @consistency_images_dir
      dir = File.expand_path(@consistency_images_dir, CHARACTERS_DIR)
      return 0 unless Dir.exist?(dir)
      # Count images but exclude hidden files
      Dir.glob(File.join(dir, "*")).reject { |f| File.directory?(f) || File.basename(f).start_with?('.') }.count
    end
    
    def full_name
      "#{@name} #{@surname}".strip
    end

    def emoji
      @data['emoji'] || "👤"
    end

    def nationality_emoji
      case @data['nationality']&.downcase
      when 'italian', 'italy' then "🇮🇹"
      when 'french', 'france' then "🇫🇷"
      when 'american', 'usa' then "🇺🇸"
      else ""
      end
    end
  end
end
