# Arneis (Media Harness) - Core module.

module Arneis
  VERSION = File.read(File.expand_path("../VERSION", __dir__)).strip
  PROJECT_ROOT = File.expand_path("..", __dir__)

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

# Override Kernel#puts to automatically add timestamps to all logging output originating from our code.
module Kernel
  alias_method :original_puts, :puts

  def puts(*args)
    if args.empty?
      original_puts
    else
      # Check if any line in the caller stack belongs to our project and is not vendored
      from_arneis = caller.any? do |line|
        line.start_with?(Arneis::PROJECT_ROOT) && !line.include?("/vendor/")
      end

      if from_arneis
        formatted = args.map do |arg|
          str = arg.to_s
          if str.empty?
            str
          else
            timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
            "[#{timestamp}] #{str}"
          end
        end
        original_puts(*formatted)
      else
        original_puts(*args)
      end
    end
  end
end

require "time"
require_relative "arneis/constants"
require_relative "arneis/config"
require_relative "arneis/asset_receipt"
require_relative "arneis/evaluator"
require_relative "arneis/media_opener"
require_relative "arneis/schema"
require_relative "arneis/planner"
require_relative "arneis/marketing_config"
require_relative "arneis/task"
require_relative "arneis/orchestrator"
require_relative "arneis/character"
require_relative "arneis/video_project"
require_relative "arneis/kids_story"
require_relative "arneis/power_colon"
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
require_relative "arneis/feedback_loader"
require_relative "arneis/characters_cli"
require_relative "arneis/cli"
require_relative "arneis/character_image"
require_relative "arneis/extract_best_of"

