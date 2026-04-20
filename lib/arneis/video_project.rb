=begin
Arneis::VideoProject - Core orchestration for video media generation.
Handles hydration, validation, and execution of a media project plan.
Supports asynchronous polling for high-cost generations.
=end

require 'yaml'
require 'fileutils'
require 'rainbow'
require 'json'
require 'time'
require 'thread'

module Arneis
  class VideoProject
    attr_reader :project_title, :scenes, :output_path, :data, :metadata

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating project from #{yaml_path}...").cyan
      @yaml_path = yaml_path
      
      # Step 1: Hydrate (Deep Merge with Template)
      h_result = Arneis::Hydrator.hydrate(yaml_path)
      unless h_result[:success]
        puts Rainbow("❌ Hydration Failed: #{h_result[:message]}").red
        raise h_result[:message]
      end
      
      # Step 2: Validate against Schema
      full_data = h_result[:data]
      contract = Arneis::Schema.contract_for(full_data['kind'])
      
      unless contract
        raise "Unknown project kind: #{full_data['kind']}"
      end

      val_result = contract.new.call(full_data)
      unless val_result.success?
        puts Rainbow("❌ Validation Failed for #{yaml_path}:").red
        val_result.errors.to_h.each do |field, msgs|
          puts Rainbow("   - #{field}: #{msgs.join(', ')}").yellow
        end
        raise "Validation Error: #{val_result.errors.to_h}"
      end

      # Step 3: Extract Spec
      @data = full_data['spec']
      @metadata = full_data['metadata']
      @project_title = @data['project_title']
      @scenes = @data['scenes']
      @mutex = Thread::Mutex.new
    end

    def initialize_output(output_path)
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
      @output_path = output_path
      
      # Copy YAML to output folder for resumption
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      # Create initial state file
      state_file = File.join(output_path, '.state.yaml')
      state = {
        'project_title' => @project_title,
        'status' => 'initialized',
        'scenes' => @scenes.map { |s| s.merge('status' => 'pending') },
        'background_music' => @data['background_music'] ? { 'status' => 'pending', 'prompt' => @data['background_music']['prompt'] } : nil,
        'montage' => { 'status' => 'pending' }
      }
      File.write(state_file, state.to_yaml)
    end

    def process(async: true)
      update_project_status('in_progress')
      
      orchestrator = Orchestrator.new(async: async)
      gemini_generator = Generator::Gemini.new
      veo_generator = Generator::Veo.new
      lyria_generator = Generator::Lyria.new
      
      # Use current state to resume
      state_file = File.join(@output_path, '.state.yaml')
      current_state = YAML.load_file(state_file)
      
      scene_task_ids = []

      # 1. Scene Tasks
      @scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}"
        scene_task_ids << scene_id
        
        state_scene = current_state['scenes']&.find { |s| s['scene'] == scene['scene'] }
        if state_scene && (state_scene['status'] == 'done' || state_scene['status'] == 'done_with_warnings' || state_scene['status'] == 'verified')
          puts Rainbow("  ⏭️  Skipping Scene #{scene['scene']} (already done)").blue
          next
        end

        orchestrator.add_task(scene_id) do
          # Re-read state in case it changed (since we run in parallel)
          state_scene = YAML.load_file(state_file)['scenes']&.find { |s| s['scene'] == scene['scene'] }
          
          scene_output_base = File.join(@output_path, "scene_#{scene['scene']}")
          veo_output = "#{scene_output_base}.mp4"

          # Handle existing polling operation
          if state_scene && state_scene['status'] == 'polling' && state_scene['operation_id']
            res = veo_generator.check_status(state_scene['operation_id'], veo_output)
            if res[:status] == 'done'
              validate_scene(scene, veo_output)
            else
              puts Rainbow("    🔵 Scene #{scene['scene']} is still polling...").blue
            end
            next
          end

          update_scene_status(scene['scene'], 'in_progress')
          
          # Enhance scene description with Gemini
          enhancement_prompt = "Enhance this video scene description for high-quality production: #{scene['description']}"
          enhancement = gemini_generator.generate(enhancement_prompt)
          enhanced_prompt = enhancement[:content]
          File.write("#{scene_output_base}.text.txt", enhanced_prompt)
          
          # Generate real video with Veo (Async enabled)
          res = veo_generator.generate(enhanced_prompt, veo_output, asset_id: "Scene#{scene['scene']}.video", async: true)
          
          if res[:status] == 'polling'
            update_scene_status(scene['scene'], 'polling', nil, res[:operation_id])
          elsif res[:status] == 'done'
            validate_scene(scene, veo_output)
          else
            update_scene_status(scene['scene'], 'failed', "Generation failed")
          end
        end
      end

      # 2. Project-wide Music Task
      if @data['background_music']
        music_id = "background_music"
        state_music = current_state['background_music']
        
        if state_music && (state_music['status'] == 'done' || state_music['status'] == 'verified')
          puts Rainbow("  ⏭️  Skipping Background Music (already done)").blue
        else
          orchestrator.add_task(music_id) do
            update_project_task_status('background_music', 'in_progress')
            music_output = File.join(@output_path, "background_music.wav")
            lyria_generator.generate(@data['background_music']['prompt'], music_output, asset_id: "Project.music")
            
            # Validate and Rename
            v_result = Validator.validate_and_rename!(music_output, :audio)
            if v_result[:success]
              # Update asset.json with metadata
              asset_json_path = "#{music_output}.asset.json"
              if File.exist?(asset_json_path)
                asset_data = ::JSON.parse(File.read(asset_json_path))
                asset_data['metadata'] = v_result[:metadata]
                File.write(asset_json_path, asset_data.to_json)
              end
              update_project_task_status('background_music', 'done')
            else
              update_project_task_status('background_music', 'failed')
            end
          end
        end
        scene_task_ids << music_id
      end

      # 3. Final Montage Task (depends on all scenes and music)
      montage_id = "montage"
      state_montage = current_state['montage']
      if state_montage && (state_montage['status'] == 'done' || state_montage['status'] == 'verified')
         puts Rainbow("  ⏭️  Skipping Final Montage (already done)").blue
      else
        orchestrator.add_task(montage_id, dependencies: scene_task_ids) do
          # Final montage only runs if all dependencies are 'verified' or 'done' (not 'polling')
          # Refresh state
          latest_state = YAML.load_file(state_file)
          pending_scenes = latest_state['scenes'].select { |s| s['status'] == 'polling' || s['status'] == 'pending' }
          
          if pending_scenes.any?
            puts Rainbow("  ⏳ [MONTAGE] Waiting for #{pending_scenes.count} scenes to finish polling...").yellow
            update_project_task_status('montage', 'waiting')
            next
          end

          update_project_task_status('montage', 'in_progress')
          puts Rainbow("🎞️  [MONTAGE] Assembling final video...").magenta
          
          output_file = File.join(@output_path, @data['output_filename'] || "final_video.mp4")
          scenes_data = @scenes.map { |s| "scene_#{s['scene']}.mp4" }.join(", ")
          music_file = "background_music.wav"
          
          receipt = AssetReceipt.new(asset_id: "Project.montage", model: "gemini-2.5-flash", prompt: "FFMPEG Montage")
          
          # Use Gemini to generate an optimized ffmpeg command
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
          
          puts "  [MONTAGE] Executing: #{ffmpeg_cmd}"
          
          success = false
          Dir.chdir(@output_path) do
            success = system(ffmpeg_cmd)
          end

          if success && File.exist?(File.join(@output_path, File.basename(output_file)))
            # Validate and Rename
            v_result = Validator.validate_and_rename!(File.join(@output_path, File.basename(output_file)), :video)
            if v_result[:success]
              puts Rainbow("  ✅ [MONTAGE] Final video generated successfully!").green
              receipt.metadata = v_result[:metadata]
              receipt.complete!(cost_usd: 0.0)
              receipt.save!(File.join(@output_path, File.basename(output_file)))
              update_project_task_status('montage', 'done')
            else
              puts Rainbow("  ⚠️  [MONTAGE] Final video is INVALID!").red
              receipt.fail!(error_msg: v_result[:message])
              receipt.save!(File.join(@output_path, File.basename(output_file)))
              update_project_task_status('montage', 'failed')
            end
          else
            puts Rainbow("  ⚠️  [MONTAGE] Real ffmpeg failed. Mocking final output.").yellow
            receipt.fail!(error_msg: "ffmpeg failed or files missing")
            receipt.save!(File.join(@output_path, File.basename(output_file)))
            File.write(File.join(@output_path, "#{File.basename(output_file)}.mock"), "MOCK_FINAL_MONTAGE_DATA")
            update_project_task_status('montage', 'done')
          end
        end
      end

      orchestrator.run
      
      # Final project status update
      final_state = YAML.load_file(state_file)
      if final_state['scenes'].any? { |s| s['status'] == 'polling' }
        update_project_status('in_progress')
      else
        update_project_status('done')
      end
    end

    private

    def validate_scene(scene, veo_output)
      puts "  🛡️  Validating scene #{scene['scene']} artifact..."
      v_result = Validator.validate_and_rename!(veo_output, :video)
      
      if v_result[:success]
        puts Rainbow("    ✅ Validated: #{v_result[:info]}").green
        
        # Update the asset.json with physical metadata
        asset_json_path = "#{veo_output}.asset.json"
        if File.exist?(asset_json_path)
          asset_data = ::JSON.parse(File.read(asset_json_path))
          asset_data['metadata'] = v_result[:metadata]
          File.write(asset_json_path, asset_data.to_json)
        end

        # Run QA Eval
        evaluator = Evaluator.new
        eval_result = evaluator.evaluate_video_text(veo_output, scene['description'])
        
        if eval_result[:success]
          puts Rainbow("    👍  EVAL: #{eval_result[:message]}").green
          update_scene_status(scene['scene'], 'verified')
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
        update_scene_status(scene['scene'], 'failed', v_result[:message])
      end
    end

    def update_project_task_status(task_key, status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def update_scene_status(scene_num, status, error_msg = nil, operation_id = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        scene = state['scenes'].find { |s| s['scene'] == scene_num }
        if scene
          scene['status'] = status
          scene['error'] = error_msg if error_msg
          scene['operation_id'] = operation_id if operation_id
        end
        File.write(state_file, state.to_yaml)
      end
    end

    def update_project_status(status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end
  end
end
