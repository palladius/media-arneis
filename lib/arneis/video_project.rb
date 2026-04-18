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
      lyria_generator = Generator::Lyria.new
      system_prompt = @template.dig('defaults', 'system_prompt')

      state_file = File.join(@output_path, '.state.yaml')
      current_state = YAML.load_file(state_file)

      # 1. Scene Tasks
      scene_task_ids = []
      @scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}"
        scene_task_ids << scene_id
        
        state_scene = current_state['scenes']&.find { |s| s['scene'] == scene['scene'] }
        if state_scene && state_scene['status'] == 'done'
          puts Rainbow("  ⏭️  Skipping Scene #{scene['scene']} (already done)").blue
          next
        end

        orchestrator.add_task(scene_id) do
          update_scene_status(scene['scene'], 'in_progress')
          scene_output_base = File.join(@output_path, "scene_#{scene['scene']}")
          
          enhancement = gemini_generator.generate(
            "Enhance this video scene description: #{scene['description']}",
            "#{scene_output_base}.text",
            system_instruction: system_prompt,
            asset_id: "Scene#{scene['scene']}.text"
          )
          enhanced_prompt = enhancement[:content]
          File.write("#{scene_output_base}.text.txt", enhanced_prompt)
          
          veo_output = "#{scene_output_base}.mp4"
          veo_generator.generate(enhanced_prompt, veo_output, asset_id: "Scene#{scene['scene']}.video")
          
          puts "  🛡️  Validating scene #{scene['scene']} artifact..."
          v_result = Validator.verify(veo_output, :video)
          
          if v_result[:success]
            puts Rainbow("    ✅ Validated: #{v_result[:info]}").green
            
            # Run QA Eval
            evaluator = Evaluator.new
            eval_result = evaluator.evaluate_video_text(veo_output, scene['description'])
            
            # Update receipt with eval data if possible
            # Note: We need the receipt object here. 
            # Refactoring to keep receipt accessible.
            
            if eval_result[:success]
              puts Rainbow("    ⚖️  EVAL: #{eval_result[:message]}").green
            else
              puts Rainbow("    ⚖️  EVAL FAILED: #{eval_result[:message]} (Score: #{eval_result[:score]})").red
              update_scene_status(scene['scene'], 'done_with_warnings', eval_result[:message])
            end

            # Update the existing asset.json with eval data
            asset_json_path = "#{veo_output}.asset.json"
            if File.exist?(asset_json_path)
              asset_data = ::JSON.parse(File.read(asset_json_path))
              asset_data['eval'] = {
                'success' => eval_result[:success],
                'score' => eval_result[:score],
                'message' => eval_result[:message],
                'ts' => Time.now.iso8601
              }
              File.write(asset_json_path, asset_data.to_json)
            end

            update_scene_status(scene['scene'], 'done') unless eval_result[:success] == false
          else
            puts Rainbow("    ⚠️  Validation failed: #{v_result[:message]}").yellow
            update_scene_status(scene['scene'], 'failed')
          end
        end
      end

      # 2. Project-wide Music Task
      if @data['background_music']
        music_id = 'background_music'
        if current_state['background_music']&.[]('status') == 'done'
          puts Rainbow("  ⏭️  Skipping Background Music (already done)").blue
        else
          orchestrator.add_task(music_id) do
            update_project_task_status('background_music', 'in_progress')
            music_output = File.join(@output_path, "background_music.wav")
            lyria_generator.generate(@data['background_music']['prompt'], music_output, asset_id: "Project.music")
            update_project_task_status('background_music', 'done')
          end
        end
        scene_task_ids << music_id
      end

      # 3. Final Montage Task (depends on all scenes and music)
      orchestrator.add_task('montage', dependencies: scene_task_ids) do
        update_project_task_status('montage', 'in_progress')
        puts Rainbow("  🎬 Starting final montage with ffmpeg...").magenta
        output_file = File.join(@output_path, @data['output_filename'] || "final_video.mp4")
        
        video_inputs = @scenes.map { |s| File.join(@output_path, "scene_#{s['scene']}.mp4") }
        audio_input = File.join(@output_path, 'background_music.wav') if @data['background_music']
        
        # Build ffmpeg command
        input_args = video_inputs.map { |v| "-i #{v}" }.join(" ")
        input_args += " -i #{audio_input}" if audio_input && File.exist?(audio_input)
        
        filter = ""
        video_inputs.each_with_index { |_, i| filter += "[#{i}:v]" }
        filter += "concat=n=#{video_inputs.size}:v=1:a=0[outv]"
        
        # Map audio if present, otherwise just video
        map_args = "-map \"[outv]\""
        if audio_input && File.exist?(audio_input)
          map_args += " -map #{video_inputs.size}:a"
        end
        
        cmd = "ffmpeg -y #{input_args} -filter_complex \"#{filter}\" #{map_args} -c:v libx264 -pix_fmt yuv420p -shortest #{output_file}"
        
        puts Rainbow("  🏗️  Executing: #{cmd}").yellow
        success = system(cmd)
        
        if success && File.exist?(output_file)
          puts Rainbow("  ✅ Montage complete: #{output_file}").green
          update_project_task_status('montage', 'done')
        else
          puts Rainbow("  ❌ Montage failed!").red
          update_project_task_status('montage', 'failed')
        end
      end

      orchestrator.run
      
      # Determine final project status
      state = YAML.load_file(state_file)
      any_failed = state['scenes'].any? { |s| s['status'] == 'failed' }
      final_status = any_failed ? 'failed' : 'done'
      update_project_status(final_status)
    end

    private

    def update_project_task_status(task_key, status)
      @mutex.synchronize do
        state_file = File.join(@output_path, '.state.yaml')
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end

    private

    def update_scene_status(scene_num, status, error_msg = nil)
      @mutex.synchronize do
        state_file = File.join(@output_path, '.state.yaml')
        state = YAML.load_file(state_file)
        scene = state['scenes'].find { |s| s['scene'] == scene_num }
        if scene
          scene['status'] = status
          scene['error'] = error_msg if error_msg
        end
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
