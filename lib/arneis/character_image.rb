# Arneis::CharacterImage - Orchestration for high-resemblance character images.
# Supports single or multiple characters in a specified scenario.

require "yaml"
require "fileutils"
require "rainbow"
require "json"
require "time"

module Arneis
  class CharacterImage
    attr_reader :project_title, :character_ids, :prompt, :aspect_ratio, :output_path, :data, :metadata

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating CharacterImage from #{yaml_path}...").cyan
      @yaml_path = yaml_path

      # Step 1: Hydrate (Deep Merge with Template)
      h_result = Arneis::Hydrator.hydrate(yaml_path)
      unless h_result[:success]
        error = Arneis::Schema::ValidationError.new("Hydration Failed: #{h_result[:message]}", {hydration: [h_result[:message]]}, yaml_path)
        puts error.report
        raise error
      end

      # Step 2: Validate against Schema
      full_data = h_result[:data]
      @data = full_data["spec"]
      @metadata = full_data["metadata"]
      
      @project_title = @data["project_title"]
      @character_ids = @data["characters"]
      @prompt = @data["prompt"]
      @aspect_ratio = @data["aspect_ratio"] || "1:1"
      @mutex = Thread::Mutex.new

      # Step 3: Load Characters
      @characters = @character_ids.map { |id| Arneis::Character.find(id) }.compact
      @characters.each do |char|
        puts Rainbow("👤 Loaded Character: #{char.name}").yellow
      end
    end

    def initialize_output(output_path)
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
      @output_path = output_path

      # Copy YAML to output folder for resumption
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      # Create initial state file
      state_file = File.join(output_path, ".state.yaml")
      state = {
        "project_title" => @project_title,
        "status" => "initialized",
        "characters" => @character_ids,
        "image" => {"status" => "pending", "prompt" => @prompt}
      }
      File.write(state_file, state.to_yaml)
    end

    def process(async: true, verify: false, dryrun: false, eval: true)
      if dryrun
        puts Rainbow("🌵 [DRYRUN] Validation complete. Skipping orchestration...").yellow
        return
      end
      update_status("in_progress")

      orchestrator = Orchestrator.new(async: async, verify: verify, eval: eval)
      gemini_generator = Generator::Gemini.new
      imagen_generator = Generator::Imagen.new

      image_output = File.join(@output_path, "character_image.png")

      orchestrator.add_task(:generate_image, outputs: { image_output => :image }, intent_prompt: "#{@character_ids.join(", ")}: #{@prompt}") do
        update_task_status("image", "in_progress")

        # Combine character contexts
        char_contexts = @characters.map(&:prompt_context).join(" ")
        full_prompt = "#{char_contexts} #{@prompt}"

        system_instruction = "You are an expert Image Prompt Engineer. Enhance the user's character image prompt to be highly descriptive, artistic, and suitable for high-quality image generation. Ensure character physical traits are respected. Output ONLY the enhanced prompt."
        enhancement = gemini_generator.generate("Enhance this character image prompt: #{full_prompt}", system_instruction: system_instruction)
        enhanced_prompt = enhancement[:content]
        File.write(File.join(@output_path, "prompt.txt"), enhanced_prompt)

        # Collect all reference images for consistency
        all_refs = @characters.map(&:all_reference_images).flatten.uniq

        res = imagen_generator.generate(enhanced_prompt, image_output, asset_id: "CharacterImage.image", reference_images: all_refs, aspect_ratio: @aspect_ratio)

        if res[:status] == "done" || res[:status] == "mocked"
          validate_image(image_output, eval)
        else
          update_task_status("image", "failed", "Generation failed")
        end
      end

      orchestrator.run
      update_status("done")
    end

    private

    def validate_image(image_output, eval_enabled = true)
      v_result = Validator.validate_and_rename!(image_output, :image)
      if v_result[:success]
        # Perform Character Consistency EVAL for each character
        if eval_enabled
          evaluator = Evaluator.new
          overall_success = true
          warnings = []

          @characters.each do |char|
            e_result = evaluator.evaluate_character_consistency(image_output, char)
            
            # Merge results into asset json
            asset_json = "#{image_output}.asset.json"
            if File.exist?(asset_json)
              asset_data = ::JSON.parse(File.read(asset_json))
              asset_data["eval_#{char.name}"] = e_result
              File.write(asset_json, ::JSON.pretty_generate(asset_data))
            end

            unless e_result[:success]
              overall_success = false
              warnings << "#{char.name} Score: #{e_result[:score]}/10"
            end
          end

          if overall_success
            update_task_status("image", "verified")
          else
            update_task_status("image", "done_with_warnings", warnings.join(", "))
          end
        else
          puts Rainbow("  ⏭️  [EVAL] Skipping Character Consistency Evaluation (disabled)").yellow
          update_task_status("image", "done")
        end
      else
        update_task_status("image", "failed", v_result[:message])
      end
    end

    def update_task_status(task_key, status, error_msg = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]["status"] = status
        state[task_key]["error"] = error_msg if error_msg
        File.write(state_file, state.to_yaml)
      end
    end

    def update_status(status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state["status"] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def primary_artifact
      File.join(@output_path, "character_image.png")
    end
  end
end
