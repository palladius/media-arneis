# Arneis::VideoProject - Core orchestration for video media generation.
# Handles hydration, validation, and execution of a media project plan.
# Refurbished for hierarchical subfolders (video/sceneX/, marketing/).

require "yaml"
require "fileutils"
require "rainbow"
require "json"
require "time"

module Arneis
  class VideoProject
    attr_reader :project_title, :scenes, :output_path, :data, :metadata

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating project from #{yaml_path}...").cyan
      @yaml_path = yaml_path

      # Step 1: Hydrate (Deep Merge with Template)
      h_result = Arneis::Hydrator.hydrate(yaml_path)
      unless h_result[:success]
        # Hydration errors are also critical
        error = Arneis::Schema::ValidationError.new("Hydration Failed: #{h_result[:message]}", {hydration: [h_result[:message]]}, yaml_path)
        puts error.report
        raise error
      end

      # Step 2: Validate against Schema
      full_data = h_result[:data]
      contract = Arneis::Schema.contract_for(full_data["kind"])

      unless contract
        raise "Unknown project kind: #{full_data["kind"]}"
      end

      val_result = contract.new.call(full_data)
      unless val_result.success?
        error = Arneis::Schema::ValidationError.new("Validation Error", val_result.errors.to_h, yaml_path)
        puts error.report
        raise error
      end

      # Step 3: Extract Spec
      @data = full_data["spec"]
      @metadata = full_data["metadata"]
      @project_title = @data["project_title"]
      @scenes = @data["scenes"]
      @mutex = Thread::Mutex.new
    end

    def initialize_output(output_path)
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
      @output_path = output_path

      # Copy YAML to output folder for resumption
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      # Create initial state file
      state_file = File.join(output_path, ".state.yaml")
      state = {
        "original_command" => "arnectl " + ARGV.join(" "),
        "project_title" => @project_title,
        "status" => "initialized",
        "scenes" => @scenes.map { |s| s.merge("status" => "pending") },
        "background_music" => @data["background_music"] ? {"status" => "pending", "prompt" => @data["background_music"]["prompt"]} : nil,
        "montage" => {"status" => "pending"},
        "marketing" => {"status" => "pending"}
      }
      File.write(state_file, state.to_yaml)
    end

    def process(async: true, verify: false, dryrun: false, eval: true)
      if dryrun
        puts Rainbow("🌵 [DRYRUN] Validation complete. Running orchestration with MOCKS...").yellow
      else
        update_project_status("in_progress")
      end

      state_file = File.join(@output_path, ".state.yaml")
      current_state = begin
        YAML.load_file(state_file)
      rescue
        {"scenes" => [], "status" => "initialized"}
      end

      pre_completed = []
      current_state["scenes"]&.each { |s| pre_completed << "scene_#{s["scene"]}" if s["status"] == "done" || s["status"] == "verified" }
      pre_completed << "background_music" if current_state["background_music"] && (current_state["background_music"]["status"] == "done" || current_state["background_music"]["status"] == "verified")

      orchestrator = Orchestrator.new(async: async, pre_completed: pre_completed, verify: verify, eval: eval)
      gemini_generator = Generator::Gemini.new
      veo_generator = Generator::Veo.new
      lyria_generator = Generator::Lyria.new
      marketing_generator = Generator::Marketing.new
      gif_generator = Generator::Gif.new
      scene_task_ids = []

      # 1. Scene Tasks (Subfolders: video/sceneX/)
      @scenes.each do |scene|
        scene_id = "scene_#{scene["scene"]}"
        scene_task_ids << scene_id

        state_scene = current_state["scenes"]&.find { |s| s["scene"] == scene["scene"] }
        if state_scene && (state_scene["status"] == "done" || state_scene["status"] == "verified")
          puts Rainbow("  ⏭️  Skipping Scene #{scene["scene"]} (already done)").blue
          next
        end

        veo_output = File.join(@output_path, "video", "scene_#{scene["scene"]}", "video.mp4")

        # Define the check_status_block for this task
        check_status_proc = lambda do
          # Load the latest state to get the operation_id
          latest_state_scene = YAML.load_file(state_file)["scenes"]&.find { |s| s["scene"] == scene["scene"] }
          if latest_state_scene && latest_state_scene["operation_id"]
            res = veo_generator.check_status(latest_state_scene["operation_id"], veo_output)
            if res[:status] == "done"
              validate_scene(scene, veo_output) # Validate after it's done polling
            end
            res
          else
            {status: "failed", message: "No operation_id found for polling"}
          end
        end

        orchestrator.add_task(scene_id, outputs: {veo_output => :video}, intent_prompt: scene["description"], check_status_block: check_status_proc) do
          scene_dir = File.dirname(veo_output)
          FileUtils.mkdir_p(scene_dir)

          # If we are resuming and already polling, the orchestrator's polling mechanism will handle it
          # This block should only initiate new generations or re-try failed ones
          state_scene = YAML.load_file(state_file)["scenes"]&.find { |s| s["scene"] == scene["scene"] }
          if state_scene && state_scene["status"] == "polling"
            # If already polling, simply return polling status to Orchestrator, it will then use check_status_proc
            next {status: "polling", operation_id: state_scene["operation_id"]}
          end

          update_scene_status(scene["scene"], "in_progress")

          enhancement = gemini_generator.generate("Enhance this video scene description: #{scene["description"]}")
          enhanced_prompt = enhancement[:content]
          File.write(File.join(scene_dir, "prompt.txt"), enhanced_prompt)

          res = veo_generator.generate(enhanced_prompt, veo_output, asset_id: "Scene#{scene["scene"]}.video", async: true)

          if res[:status] == "polling"
            update_scene_status(scene["scene"], "polling", nil, res[:operation_id])
            res # Return polling status to Orchestrator
          elsif res[:status] == "done"
            validate_scene(scene, veo_output)
            {status: "done"} # Return done status to Orchestrator
          else
            update_scene_status(scene["scene"], "failed", "Generation failed")
            {status: "failed", message: "Generation failed"} # Return failed status
          end
        end
      end

      # 2. Project-wide Music Task
      music_id = "background_music"
      if @data["background_music"]
        music_output = File.join(@output_path, "audio", "background_music.wav")
        orchestrator.add_task(music_id, outputs: {music_output => :audio}, intent_prompt: @data["background_music"]["prompt"]) do
          update_task_status("background_music", "in_progress")
          FileUtils.mkdir_p(File.dirname(music_output))

          lyria_generator.generate(@data["background_music"]["prompt"], music_output, asset_id: "Project.music")
          update_task_status("background_music", "done")
        end
        scene_task_ids << music_id
      end

      # 3. Final Montage (LLM-driven)
      montage_id = "montage"
      output_filename = @data["output_filename"] || "final_video.mp4"
      final_video_output = File.join(@output_path, output_filename)

      orchestrator.add_task(montage_id, dependencies: scene_task_ids, outputs: {final_video_output => :video}, intent_prompt: "A montage of all scenes: #{@project_title}") do
        update_project_status("in_progress")
        puts Rainbow("🎬 [MONTAGE] Generating final movie using LLM-driven ffmpeg command...").magenta

        # Build context for Gemini
        video_files = @scenes.map { |s| File.join(@output_path, "video", "scene_#{s["scene"]}", "video.mp4") }
        audio_file = File.join(@output_path, "audio", "background_music.wav")

        # Create a temporary file list for ffmpeg
        list_file = File.join(@output_path, "input.txt")
        File.open(list_file, "w") do |f|
          video_files.each { |path| f.puts "file '#{File.expand_path(path)}'" }
        end

        system_instruction = "You are an ffmpeg expert. Generate the EXACT shell command to concatenate the video files listed in 'input.txt' and add the background music. You MUST include the '-shortest' flag to ensure the output ends when the video ends. Use '-c:v copy' to avoid re-encoding. Output ONLY the command, no preamble, no code blocks."
        prompt = "Video files list: #{list_file}\nAudio file: #{audio_file}\nOutput file: #{final_video_output}"

        resp = gemini_generator.generate(prompt, system_instruction: system_instruction)
        ffmpeg_cmd = resp[:content].strip.gsub(/^`|`$/, "")

        if dryrun
          puts Rainbow("  🌵 [DRYRUN] Mocking MONTAGE command execution.").yellow
          File.write("#{final_video_output}.mock", "MOCK_VIDEO_MONTAGE: #{ffmpeg_cmd}")
        else
          puts "  💻 Executing: #{ffmpeg_cmd}"
          # We mock this for now since we might not have all real files in tests
          if ENV["ARNEIS_NO_MOCK"] == "true"
            system(ffmpeg_cmd)
          else
            puts Rainbow("  🤡 [MOCK] FFMPEG Montage mocked (ARNEIS_NO_MOCK is false)").yellow
            File.write("#{final_video_output}.mock", "MOCK_VIDEO_MONTAGE: #{ffmpeg_cmd}")
          end
        end
        FileUtils.rm(list_file) if File.exist?(list_file) # Clean up
        update_task_status("montage", "done")
      end

      # 4. Marketing Task
      marketing_id = "marketing"
      orchestrator.add_task(marketing_id, dependencies: [montage_id]) do
        update_task_status("marketing", "in_progress")
        marketing_dir = File.join(@output_path, "marketing")

        context = "A promotional video project: #{@project_title}"
        marketing_generator.generate_all(@project_title, context, marketing_dir)
        update_task_status("marketing", "done")
      end

      # 5. GIF Post-Production Task
      gif_id = "post_production_gif"
      gif_output = final_video_output.sub(/\.mp4$/, ".gif")
      orchestrator.add_task(gif_id, dependencies: [montage_id], outputs: {gif_output => :image}) do
        gif_generator.generate(final_video_output, gif_output)
      end

      orchestrator.run
      update_project_status("done")
    end

    private

    def update_task_status(task_key, status)
      task_key = task_key.to_s
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]["status"] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def validate_scene(scene, veo_output)
      puts "  🛡️  Validating scene #{scene["scene"]} artifact..."
      v_result = Validator.validate_and_rename!(veo_output, :video)
      if v_result[:success]
        update_scene_status(scene["scene"], "verified")
      else
        update_scene_status(scene["scene"], "failed", v_result[:message])
      end
    end

    def update_scene_status(scene_num, status, error_msg = nil, operation_id = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        scene = state["scenes"].find { |s| s["scene"] == scene_num }
        if scene
          scene["status"] = status
          scene["error"] = error_msg if error_msg
          scene["operation_id"] = operation_id if operation_id
        end
        File.write(state_file, state.to_yaml)
      end
    end

    def update_project_status(status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state["status"] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def primary_artifact
      output_filename = @data["output_filename"] || "final_video.mp4"
      File.join(@output_path, output_filename)
    end
  end
end
