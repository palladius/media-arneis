# Arneis (Media Harness) - Core module.

module Arneis
  VERSION = "0.1.6"

  def self.load_project(yaml_path)
    data = YAML.load_file(yaml_path)
    kind = data["kind"]
    begin
      klass = const_get(kind)
      klass.new(yaml_path)
    rescue NameError
      raise "Unknown project kind: #{kind}"
    end
  end
end

require "time"
require_relative "arneis/constants"
require_relative "arneis/config"
require_relative "arneis/asset_receipt"
require_relative "arneis/evaluator"
require_relative "arneis/schema"
require_relative "arneis/planner"
require_relative "arneis/marketing_config"
require_relative "arneis/task"
require_relative "arneis/orchestrator"
require_relative "arneis/character"
require_relative "arneis/video_project"
require_relative "arneis/kids_story"
require_relative "arneis/visualizer"
require_relative "arneis/generator/base"
require_relative "arneis/generator/gemini"
require_relative "arneis/generator/veo"
require_relative "arneis/generator/lyria"
require_relative "arneis/generator/imagen"
require_relative "arneis/generator/marketing"
require_relative "arneis/generator/gif"
require_relative "arneis/generator/chirp"
require_relative "arneis/validator"
require_relative "arneis/characters_cli"
require_relative "arneis/cli"
require_relative "arneis/character_image"
