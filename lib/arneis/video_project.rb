=begin
Arneis::VideoProject - Implementation of the Video Project template.
=end

require 'yaml'

module Arneis
  class VideoProject
    attr_reader :data, :title, :scenes

    def initialize(yaml_path)
      @yaml_path = yaml_path
      @data = YAML.load_file(yaml_path)
      @template = YAML.load_file('data/templates/VideoProject.yaml')
      validate!
      @title = @data['title']
      @scenes = @data['scenes']
      @mutex = Mutex.new
    end

    def validate!
      @template['required_fields'].each do |field|
        raise "Invalid YAML: Missing '#{field}'" unless @data[field]
      end
      
      raise "Invalid YAML: 'scenes' must be an array" unless @data['scenes'].is_a?(Array)
      
      min_scenes = @template.dig('structure', 'scenes', 'min_count')
      raise "Invalid YAML: 'scenes' must have at least #{min_scenes} items" if @data['scenes'].size < min_scenes
    end

    def initialize_output(output_path)
      Dir.mkdir(output_path) unless Dir.exist?(output_path)
      @output_path = output_path
      
      # Copy YAML to output folder for resumption
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      state_file = File.join(output_path, '.state.yaml')
      return if File.exist?(state_file) # Don't overwrite if it exists

      initial_state = {
        'status' => 'initialized',
        'project_title' => @title,
        'created_at' => Time.now.to_s,
        'scenes' => @scenes.map { |s| s.merge('status' => 'pending') }
      }
      File.write(state_file, initial_state.to_yaml)
    end

    def process
      orchestrator = Orchestrator.new
      veo_generator = Generator::Veo.new
      gemini_generator = Generator::Gemini.new
      system_prompt = @template.dig('defaults', 'system_prompt')

      # Read current state to see what needs doing
      state_file = File.join(@output_path, '.state.yaml')
      current_state = YAML.load_file(state_file)

      @scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}"
        
        # Check if this scene is already done in current_state
        state_scene = current_state['scenes'].find { |s| s['scene'] == scene['scene'] }
        if state_scene && state_scene['status'] == 'done'
          puts Rainbow("  ⏭️  Skipping Scene #{scene['scene']} (already done)").blue
          next
        end

        orchestrator.add_task(scene_id) do
          update_scene_status(scene['scene'], 'in_progress')
          
          # Enhance the description with Gemini using the template's system prompt
          puts "  ✨ Enhancing scene #{scene['scene']} description using template guardrails..."
          scene_output_base = File.join(@output_path, "scene_#{scene['scene']}")
          enhancement = gemini_generator.generate(
            "Enhance this video scene description: #{scene['description']}",
            "#{scene_output_base}.txt",
            system_instruction: system_prompt
          )
          enhanced_prompt = enhancement[:content]
          File.write("#{scene_output_base}.txt", enhanced_prompt)
          
          # Generate real video with Veo
          veo_output = "#{scene_output_base}.mp4"
          veo_generator.generate(enhanced_prompt, veo_output)
          
          # Validate artifact
          puts "  🛡️  Validating scene #{scene['scene']} artifact..."
          v_result = Validator.verify(veo_output, :video)
          
          if v_result[:success]
            puts Rainbow("    ✅ Validated: #{v_result[:info]}").green
            update_scene_status(scene['scene'], 'done')
          else
            puts Rainbow("    ⚠️  Validation failed: #{v_result[:message]}").yellow
            update_scene_status(scene['scene'], 'failed')
          end
        end
      end

      orchestrator.run
      
      # Determine final project status based on scenes
      state_file = File.join(@output_path, '.state.yaml')
      state = YAML.load_file(state_file)
      any_failed = state['scenes'].any? { |s| s['status'] == 'failed' }
      final_status = any_failed ? 'failed' : 'done'
      
      update_project_status(final_status)
    end

    private

    def update_scene_status(scene_num, status)
      @mutex.synchronize do
        state_file = File.join(@output_path, '.state.yaml')
        state = YAML.load_file(state_file)
        scene = state['scenes'].find { |s| s['scene'] == scene_num }
        scene['status'] = status if scene
        File.write(state_file, state.to_yaml)
      end
    end

    def update_project_status(status)
      @mutex.synchronize do
        state_file = File.join(@output_path, '.state.yaml')
        state = YAML.load_file(state_file)
        state['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end
  end
end
