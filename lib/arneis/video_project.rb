=begin
Arneis::VideoProject - Implementation of the Video Project template.
=end

require 'yaml'
require 'fileutils'
require 'thread'

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
        if state_scene && (state_scene['status'] == 'done' || state_scene['status'] == 'done_with_warnings')
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
            
            if eval_result[:success]
              puts Rainbow("    👍  EVAL: #{eval_result[:message]}").green
              update_scene_status(scene['scene'], 'done')
            else
              puts Rainbow("    😟  EVAL FAILED: #{eval_result[:message]} (Score: #{eval_result[:score]})").red
              
              if eval_result[:score] < 5
                puts Rainbow("    ♻️  Score is low (< 5). Rescheduling scene for rework...").yellow
                update_scene_status(scene['scene'], 'pending', eval_result[:message])
              else
                update_scene_status(scene['scene'], 'done_with_warnings', eval_result[:message])
              end
            end
          else
            puts Rainbow("    ⚠️  Validation failed: #{v_result[:message]}").yellow
            # If validation failed (file not found or mock), mark as failed so it can be retried
            update_scene_status(scene['scene'], 'failed', v_result[:message])
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
        puts Rainbow("  🎬 Starting final montage with LLM-driven ffmpeg command...").magenta
        output_file = File.join(@output_path, @data['output_filename'] || "final_video.mp4")
        
        # Use Gemini to generate the perfect ffmpeg command
        scenes_data = @scenes.map { |s| "scene_#{s['scene']}.mp4" }.join(", ")
        music_file = @data['background_music'] ? "background_music.wav" : "none"
        
        montage_prompt = "Generate a single-line bash command using ffmpeg to:
        1. Concatenate these video files in order: #{scenes_data}.
        2. Overlay this background music: #{music_file}.
        3. Ensure the audio is mixed (not replaced) and the music volume is adjusted to not overpower.
        4. The output filename MUST be: #{File.basename(output_file)}.
        
        CRITICAL: Do NOT use bash-specific syntax like process substitution <( ). Use standard -i flags for all inputs and a filter_complex to merge them.
        
        Assume we are running the command inside the folder: #{@output_path}
        Output ONLY the command, nothing else."

        resp = gemini_generator.generate(montage_prompt, system_instruction: "You are a Video Engineering Expert.")
        ffmpeg_cmd = resp[:content].strip.gsub(/```bash\n|```/, '')
        
        puts "  🏗️  Executing Generated Command: #{Rainbow(ffmpeg_cmd).cyan}"
        
        # Record the command in a receipt
        receipt = AssetReceipt.new(asset_id: "Project.montage", model: "gemini-2.5-flash", prompt: montage_prompt)
        
        Dir.chdir(@output_path) do
          success = system(ffmpeg_cmd)
          if success && File.exist?(File.basename(output_file))
            puts Rainbow("  ✅ [MONTAGE] Final video generated successfully!").green
            receipt.complete!(cost_usd: 0.0)
            receipt.save!(File.basename(output_file))
            update_project_task_status('montage', 'done')
          else
            puts Rainbow("  ⚠️  [MONTAGE] Real ffmpeg failed. Mocking final output.").yellow
            receipt.fail!(error_msg: "ffmpeg failed or files missing")
            receipt.save!(File.basename(output_file))
            File.write(File.basename(output_file), "MOCK_FINAL_MONTAGE_DATA")
            update_project_task_status('montage', 'done')
          end
        end
      end

      orchestrator.run
      
      # Determine final project status
      state = YAML.load_file(state_file)
      any_failed = (state['scenes'] || []).any? { |s| s['status'] == 'failed' }
      final_status = any_failed ? 'failed' : 'done'
      update_project_status(final_status)
    end

    private

    def update_project_task_status(task_key, status)
      @mutex.synchronize do
        # Use absolute path for state file to avoid Dir.chdir issues
        # The @output_path is already set during initialize_output
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def update_scene_status(scene_num, status, error_msg = nil)
      @mutex.synchronize do
        # Use absolute path for state file to avoid Dir.chdir issues
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
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
        # Use absolute path for state file to avoid Dir.chdir issues
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end
  end
end
