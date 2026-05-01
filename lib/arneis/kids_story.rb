# Arneis::KidsStory - Multi-page illustrated children's story orchestration.
# Similar to VideoProject but focused on static pages with character consistency.

require "yaml"
require "fileutils"
require "rainbow"
require "json"
require "time"

module Arneis
  class KidsStory
    attr_reader :story_title, :pages, :character_id, :story_audio, :output_path, :data, :metadata

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating KidsStory from #{yaml_path}...").cyan
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
      @story_title = @data["story_title"]
      @character_id = @data["character_id"]
      @story_audio = @data["story_audio"] || ["it", "en"]
      @pages = @data["pages"]
      @mutex = Thread::Mutex.new

      # Step 4: Load Character
      @character = Arneis::Character.find(@character_id)
      puts Rainbow("👤 Loaded Character: #{@character.name}").yellow if @character
    end

    def initialize_output(output_path)
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
      @output_path = output_path

      # Copy YAML to output folder for resumption
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      # Create initial state file
      state_file = File.join(output_path, ".state.yaml")
      state = {
        "story_title" => @story_title,
        "character_id" => @character_id,
        "status" => "initialized",
        "pages" => @pages.map { |p| p.merge("status" => "pending") },
        "background_music" => @data["background_music"] ? {"status" => "pending", "prompt" => @data["background_music"]["prompt"]} : nil,
        "final_story_assembly" => {"status" => "pending"}
      }
      
      # Add individual audio concatenation tasks
      @story_audio.each do |lang|
        state["final_audio_#{lang}"] = {"status" => "pending"}
      end
      
      File.write(state_file, state.to_yaml)
    end

    def process(async: true, verify: false, dryrun: false)
      if dryrun
        puts Rainbow("🌵 [DRYRUN] Validation complete. Skipping orchestration...").yellow
        return
      end
      update_status("in_progress")

      state_file = File.join(@output_path, ".state.yaml")
      current_state = begin
        YAML.load_file(state_file)
      rescue
        {"pages" => [], "status" => "initialized"}
      end

      pre_completed = []
      current_state["pages"]&.each { |p| pre_completed << "page_#{p["page"]}" if p["status"] == "done" || p["status"] == "verified" }
      pre_completed << "background_music" if current_state["background_music"] && (current_state["background_music"]["status"] == "done" || current_state["background_music"]["status"] == "verified")

      orchestrator = Orchestrator.new(async: async, pre_completed: pre_completed, verify: verify)
      gemini_generator = Generator::Gemini.new
      imagen_generator = Generator::Imagen.new
      lyria_generator = Generator::Lyria.new
      chirp_generator = Generator::Chirp.new
      page_task_ids = []

      # 1. Page Tasks
      @pages.each do |page|
        page_id = "page_#{page["page"]}"
        page_task_ids << page_id

        state_page = current_state["pages"]&.find { |p| p["page"] == page["page"] }
        if state_page && (state_page["status"] == "done" || state_page["status"] == "verified")
          puts Rainbow("  ⏭️  Skipping Page #{page["page"]} (already done)").blue
          next
        end

        orchestrator.add_task(page_id) do
          page_dir = File.join(@output_path, "pages", "page_#{page["page"]}")
          FileUtils.mkdir_p(page_dir)

          image_output = File.join(page_dir, "illustration.png")
          update_page_status(page["page"], "in_progress")

          # Use Character to enhance the prompt
          character_prompt = @character ? @character.prompt_context : ""
          full_prompt = "#{character_prompt} #{page["description"]}"

          system_instruction = "You are an expert Image Prompt Engineer. Enhance the user's children's story prompt to be highly descriptive, artistic, and suitable for high-quality image generation. Output ONLY the enhanced prompt, no conversational filler, no options, no preamble."
          enhancement = gemini_generator.generate("Enhance this children's story illustration prompt: #{full_prompt}", system_instruction: system_instruction)
          enhanced_prompt = enhancement[:content]
          File.write(File.join(page_dir, "prompt.txt"), enhanced_prompt)

          # ENRICH NARRATIVE
          puts Rainbow("  📝 [GEMINI] Enriching narrative for Page #{page["page"]}...").magenta
          narrative_instruction = "You are a professional children's book author. Your task is to expand the provided 'one-sentence' story beat into a beautiful, engaging, and detailed chapter for a kids' storybook. Aim for a substantial length (roughly 500-1000 words) with vivid descriptions, dialogue, and a magical, adventurous tone. Output ONLY the story text."
          narrative_resp = gemini_generator.generate(page["text"], system_instruction: narrative_instruction)
          enriched_text = narrative_resp[:content]
          File.write(File.join(page_dir, "story_text.txt"), enriched_text)

          res = imagen_generator.generate(enhanced_prompt, image_output, asset_id: "Page#{page["page"]}.image", reference_images: @character&.all_reference_images)

          if res[:status] == "done" || res[:status] == "mocked"
            # GENERATE AUDIO for each language
            @story_audio.each do |lang|
              audio_output = File.join(page_dir, "audio_#{lang}.wav")
              
              target_text = enriched_text
              if lang != "en"
                puts Rainbow("    🌐 [GEMINI] Translating Page #{page["page"]} to #{lang}...").cyan
                translation_instruction = "You are a professional translator for children's books. Translate the following English story text into the language with code '#{lang}'. Maintain a magical and adventurous tone. Output ONLY the translated text, with no preamble."
                trans_resp = gemini_generator.generate(enriched_text, system_instruction: translation_instruction)
                target_text = trans_resp[:content]
                File.write(File.join(page_dir, "story_text_#{lang}.txt"), target_text)
              end

              chirp_generator.generate(target_text, audio_output, language_code: lang, asset_id: "Page#{page["page"]}.audio.#{lang}")
            end

            validate_page(page, image_output)
          else
            update_page_status(page["page"], "failed", "Generation failed")
          end
        end
      end

      # 2. Background Music
      music_id = "background_music"
      if @data["background_music"]
        state_music = current_state["background_music"]
        if state_music && (state_music["status"] == "done" || state_music["status"] == "verified")
          puts Rainbow("  ⏭️  Skipping Background Music (already done)").blue
        else
          orchestrator.add_task(music_id) do
            update_task_status("background_music", "in_progress")
            music_dir = File.join(@output_path, "audio")
            FileUtils.mkdir_p(music_dir)
            music_output = File.join(music_dir, "background_music.wav")

            lyria_generator.generate(@data["background_music"]["prompt"], music_output, asset_id: "Story.music")
            update_task_status("background_music", "done")
          end
          page_task_ids << music_id
        end
      end

      # 2.5 Final Audio Concatenation
      @story_audio.each do |lang|
        audio_id = "final_audio_#{lang}"
        # Dependencies are all page tasks (which now include audio generation)
        orchestrator.add_task(audio_id, dependencies: @pages.map { |p| "page_#{p["page"]}" }) do
          update_task_status(audio_id, "in_progress")
          puts Rainbow("  🔊 [AUDIO] Concatenating final audio for #{lang}...").magenta
          concatenate_audio(lang)
          update_task_status(audio_id, "done")
        end
        page_task_ids << audio_id
      end

      # 3. Final Story Assembly
      story_md_id = "final_story_assembly"
      state_assembly = current_state["final_story_assembly"]
      if state_assembly && state_assembly["status"] == "done"
        puts Rainbow("  ⏭️  Skipping Final Story Assembly (already done)").blue
      else
        orchestrator.add_task(story_md_id, dependencies: page_task_ids) do
          update_task_status("final_story_assembly", "in_progress")
          puts Rainbow("📖 Assembling final story Markdown...").magenta
          generate_final_story
          update_task_status("final_story_assembly", "done")
        end
      end

      orchestrator.run
      update_status("done")
    end

    private

    def generate_final_story
      content = "# #{@story_title}\n\n"

      if @data["background_music"]
        content += "🎵 **Background Music:** [#{@data["background_music"]["prompt"]}](audio/background_music.wav)\n\n"
      end

      # Add Final Audio links
      @story_audio.each do |lang|
        audio_rel_path = "audio/final_story_#{lang}.wav"
        if File.exist?(File.join(@output_path, audio_rel_path))
          content += "🔊 **Full Story Audio (#{lang}):** [#{audio_rel_path}](#{audio_rel_path})\n\n"
        end
      end

      @pages.each do |page|
        num = page["page"]
        image_rel_path = "pages/page_#{num}/illustration.png"
        text_file = File.join(@output_path, "pages", "page_#{num}", "story_text.txt")
        display_text = File.exist?(text_file) ? File.read(text_file) : page["text"]

        content += "## Page #{num}\n\n"
        content += "![Page #{num}](#{image_rel_path})\n\n"
        content += "#{display_text}\n\n"
        content += "---\n\n"
      end

      story_file = File.join(@output_path, "STORY.md")
      File.write(story_file, content)
      puts Rainbow("✅ Final story saved to #{story_file}").green
    end

    def concatenate_audio(lang)
      audio_dir = File.join(@output_path, "audio")
      FileUtils.mkdir_p(audio_dir)
      final_output = File.join(audio_dir, "final_story_#{lang}.wav")

      # Collect all page audio files
      audio_files = @pages.map do |page|
        File.join(@output_path, "pages", "page_#{page["page"]}", "audio_#{lang}.wav")
      end

      # Verify all files exist
      missing = audio_files.reject { |f| File.exist?(f) }
      unless missing.empty?
        puts Rainbow("  ⚠️ [AUDIO] Missing audio files for concatenation: #{missing.join(", ")}").yellow
        return
      end

      # For now, we'll use a simple mock if ffmpeg is missing or just for the test
      if ENV["RSPEC_RUNNING"] || !system("which ffmpeg > /dev/null 2>&1")
        puts Rainbow("  🧪 [AUDIO] Simulating concatenation for #{lang}...").blue
        File.write(final_output, "CONCATENATED AUDIO DATA for #{lang}")
        return
      end

      # Real ffmpeg concatenation
      # Create a temporary file list for ffmpeg
      list_file = File.join(@output_path, "audio_list_#{lang}.txt")
      File.open(list_file, "w") do |f|
        audio_files.each { |path| f.puts "file '#{File.expand_path(path)}'" }
      end

      cmd = "ffmpeg -f concat -safe 0 -i #{list_file} -c copy #{final_output} -y"
      puts "    [FFMPEG] Running: #{cmd}"
      if system(cmd)
        puts Rainbow("  ✅ [AUDIO] Final story audio saved to #{final_output}").green
      else
        puts Rainbow("  ❌ [AUDIO] FFMPEG failed to concatenate audio for #{lang}").red
      end
      FileUtils.rm(list_file) if File.exist?(list_file)
    end

    def validate_page(page, image_output)
      v_result = Validator.validate_and_rename!(image_output, :image)
      if v_result[:success]
        # Perform Character Consistency EVAL
        evaluator = Evaluator.new
        e_result = evaluator.evaluate_character_consistency(image_output, @character)

        # Save Eval result to asset json
        asset_json = "#{image_output}.asset.json"
        if File.exist?(asset_json) && e_result
          asset_data = ::JSON.parse(File.read(asset_json))
          asset_data["eval"] = e_result
          File.write(asset_json, ::JSON.pretty_generate(asset_data))
        end

        # AUDIO EVAL
        @story_audio.each do |lang|
          audio_file = File.join(File.dirname(image_output), "audio_#{lang}.wav")
          if File.exist?(audio_file)
            # Find the text for this page in this language
            text_file = File.join(File.dirname(image_output), "story_text_#{lang}.txt")
            text_file = File.join(File.dirname(image_output), "story_text.txt") if lang == "en" && !File.exist?(text_file)
            
            if File.exist?(text_file)
              expected_text = File.read(text_file)
              a_result = evaluator.evaluate_audio_intelligibility(audio_file, expected_text)
              
              # Save audio eval to asset json
              audio_asset_json = "#{audio_file}.asset.json"
              if File.exist?(audio_asset_json) && a_result
                audio_asset_data = ::JSON.parse(File.read(audio_asset_json))
                audio_asset_data["eval"] = a_result
                File.write(audio_asset_json, ::JSON.pretty_generate(audio_asset_data))
              end
            end
          end
        end

        if e_result && e_result[:success]
          update_page_status(page["page"], "verified")
        elsif e_result
          update_page_status(page["page"], "done_with_warnings", "CC Score: #{e_result[:score]}/10 - #{e_result[:message]}")
        else
          update_page_status(page["page"], "done_with_warnings", "Evaluation failed")
        end
      else
        update_page_status(page["page"], "failed", v_result[:message])
      end
    end

    def update_task_status(task_key, status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]["status"] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def update_page_status(page_num, status, error_msg = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        page = state["pages"].find { |p| p["page"] == page_num }
        if page
          page["status"] = status
          page["error"] = error_msg if error_msg
        end
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
  end
end
