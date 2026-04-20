=begin
Arneis::Schema - YAML schema validation and inheritance (hydration).
Uses dry-validation for structural enforcement.
=end

require 'dry-validation'
require 'deep_merge'

module Arneis
  module Schema
    # Base schema for all Arneis YAML objects (K8s-compliant)
    class BaseContract < Dry::Validation::Contract
      params do
        required(:apiVersion).filled(:string)
        required(:kind).filled(:string)
        required(:metadata).hash do
          required(:name).filled(:string)
          optional(:labels).hash
          optional(:annotations).hash
          optional(:template).filled(:string) # Link to base template
        end
      end

      rule(:apiVersion) do
        unless value == 'media-arneis.palladius.it/v1'
          key.failure("must be media-arneis.palladius.it/v1")
        end
      end
    end

    # Specific schema for VideoProject
    class VideoProjectContract < BaseContract
      params(BaseContract.schema) do
        required(:spec).hash do
          required(:project_title).filled(:string)
          optional(:output_filename).filled(:string)
          required(:scenes).array(:hash) do
            required(:scene).filled(:integer)
            required(:description).filled(:string)
          end
          optional(:background_music).hash do
            required(:prompt).filled(:string)
          end
        end
      end

      rule(:kind) do
        unless value == 'VideoProject'
          key.failure("must be VideoProject")
        end
      end
    end

    def self.validate_template(yaml_path)
      data = YAML.load_file(yaml_path)
      # For now, identify contract by kind
      contract = contract_for(data['kind'])
      
      unless contract
        return { success: false, message: "Unknown kind: #{data['kind']}" }
      end

      result = contract.new.call(data)
      if result.success?
        { success: true, data: result.to_h }
      else
        { success: false, message: "Validation failed for #{File.basename(yaml_path)}: #{result.errors.to_h}", errors: result.errors.to_h }
      end
    rescue => e
      { success: false, message: "Error loading YAML: #{e.message}" }
    end

    def self.contract_for(kind)
      case kind
      when 'VideoProject' then VideoProjectContract
      else nil
      end
    end
  end

  module Hydrator
    def self.hydrate(sample_path)
      unless File.exist?(sample_path)
        return { success: false, message: "File not found: #{sample_path}" }
      end
      sample_data = YAML.load_file(sample_path)
      template_name = sample_data.dig('metadata', 'template') || sample_data['template']
      
      unless template_name
        return { success: false, message: "No template specified in #{sample_path}" }
      end

      template_path = File.join("data/templates", "#{template_name}.yaml")
      unless File.exist?(template_path)
        return { success: false, message: "Template not found: #{template_path}" }
      end

      template_data = YAML.load_file(template_path)
      
      # Deep Merge: sample overrides template
      hydrated_data = template_data.dup.deep_merge!(sample_data)

      
      # Ensure metadata name comes from sample
      hydrated_data['metadata'] ||= {}
      hydrated_data['metadata']['name'] = sample_data.dig('metadata', 'name') || File.basename(sample_path, '.*')
      
      { success: true, data: hydrated_data }
    rescue => e
      { success: false, message: "Hydration error: #{e.message}" }
    end
  end
end
