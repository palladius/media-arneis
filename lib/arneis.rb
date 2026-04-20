=begin
Arneis (Media Harness) - Core module.
=end

module Arneis
  VERSION = "0.0.1"
end

require 'time'
require_relative 'arneis/constants'
require_relative 'arneis/config'
require_relative 'arneis/asset_receipt'
require_relative 'arneis/evaluator'
require_relative 'arneis/schema'
require_relative 'arneis/planner'
require_relative 'arneis/task'
require_relative 'arneis/orchestrator'
require_relative 'arneis/character'
require_relative 'arneis/video_project'
require_relative 'arneis/visualizer'
require_relative 'arneis/generator/base'
require_relative 'arneis/generator/gemini'
require_relative 'arneis/generator/veo'
require_relative 'arneis/generator/lyria'
require_relative 'arneis/generator/imagen'
require_relative 'arneis/validator'
require_relative 'arneis/characters_cli'
require_relative 'arneis/cli'
