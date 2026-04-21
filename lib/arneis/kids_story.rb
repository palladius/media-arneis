=begin
Arneis::KidsStory - Multi-page illustrated children's story orchestration.
Similar to VideoProject but focused on static pages with character consistency.
=end

require 'yaml'
require 'fileutils'
require 'rainbow'
require 'json'
require 'time'
require 'thread'

module Arneis
  class KidsStory
    attr_reader :story_title, :pages, :character_id, :output_path, :data, :metadata

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating KidsStory from #{yaml_path}...").cyan
      @yaml_path = yaml_path
      
      # Step 1: Hydrate (Deep Merge with Template)
      h_result = Arneis::Hydrator.hydrate(yaml_path)
      unless h_result[:success]
        error = Arneis::Schema::ValidationError.new("Hydration Failed: #{h_result[:message]}", { hydration: [h_result[:message]] }, yaml_path)
        puts error.report
        raise error
      end
      
      # Step 2: Validate against Schema
      full_data = h_result[:data]
      contract = Arneis::Schema.contract_for(full_data['kind'])
      
      unless contract
        raise "Unknown project kind: #{full_data['kind']}"
      end

      val_result = contract.new.call(full_data)
      unless val_result.success?
        error = Arneis::Schema::ValidationError.new("Validation Error", val_result.errors.to_h, yaml_path)
        puts error.report
        raise error
      end

      # Step 3: Extract Spec
      @data = full_data['spec']
      @metadata = full_data['metadata']
      @story_title = @data['story_title']
      @character_id = @data['character_id']
      @pages = @data['pages']
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
      state_file = File.join(output_path, '.state.yaml')
      state = {
        'story_title' => @story_title,
        'character_id' => @character_id,
        'status' => 'initialized',
        'pages' => @pages.map { |p| p.merge('status' => 'pending') },
        'background_music' => @data['background_music'] ? { 'status' => 'pending', 'prompt' => @data['background_music']['prompt'] } : nil,
        'final_story_assembly' => { 'status' => 'pending' }
      }
      File.write(state_file, state.to_yaml)
    end

    def process(async: true)
      update_status('in_progress')

      state_file = File.join(@output_path, '.state.yaml')
      current_state = YAML.load_file(state_file) rescue { 'pages' => [], 'status' => 'initialized' }

      pre_completed = []
      current_state['pages']&.each { |p| pre_completed << "page_#{p['page']}" if p['status'] == 'done' || p['status'] == 'verified' }
      pre_completed << "background_music" if current_state['background_music'] && (current_state['background_music']['status'] == 'done' || current_state['background_music']['status'] == 'verified')

      orchestrator = Orchestrator.new(async: async, pre_completed: pre_completed)
      gemini_generator = Generator::Gemini.new
      imagen_generator = Generator::Imagen.new
      lyria_generator = Generator::Lyria.new      
      page_task_ids = []

      # 1. Page Tasks
      @pages.each do |page|
        page_id = "page_#{page['page']}"
        page_task_ids << page_id
        
        state_page = current_state['pages']&.find { |p| p['page'] == page['page'] }
        if state_page && (state_page['status'] == 'done' || state_page['status'] == 'verified')
          puts Rainbow("  ⏭️  Skipping Page #{page['page']} (already done)").blue
          next
        end

        orchestrator.add_task(page_id) do
          page_dir = File.join(@output_path, "pages", "page_#{page['page']}")
          FileUtils.mkdir_p(page_dir)
          
          image_output = File.join(page_dir, "illustration.png")
          update_page_status(page['page'], 'in_progress')
          
          # Use Character to enhance the prompt
          character_prompt = @character ? @character.prompt_context : ""
          full_prompt = "#{character_prompt} #{page['description']}"
          
          system_instruction = "You are an expert Image Prompt Engineer. Enhance the user's children's story prompt to be highly descriptive, artistic, and suitable for high-quality image generation. Output ONLY the enhanced prompt, no conversational filler, no options, no preamble."
          enhancement = gemini_generator.generate("Enhance this children's story illustration prompt: #{full_prompt}", system_instruction: system_instruction)
          enhanced_prompt = enhancement[:content]
          File.write(File.join(page_dir, "prompt.txt"), enhanced_prompt)
          
          # ENRICH NARRATIVE
          puts Rainbow("  📝 [GEMINI] Enriching narrative for Page #{page['page']}...").magenta
          narrative_instruction = "You are a professional children's book author. Your task is to expand the provided 'one-sentence' story beat into a beautiful, engaging, and age-appropriate paragraph for a kids' storybook. Use vivid language and a magical tone. Output ONLY the story paragraph."
          narrative_resp = gemini_generator.generate(page['text'], system_instruction: narrative_instruction)
          enriched_text = narrative_resp[:content]
          File.write(File.join(page_dir, "story_text.txt"), enriched_text)
          
          res = imagen_generator.generate(enhanced_prompt, image_output, asset_id: "Page#{page['page']}.image", reference_image: @character&.reference_image)
          
          if res[:status] == 'done'
            validate_page(page, image_output)
          else
            update_page_status(page['page'], 'failed', "Generation failed")
          end
        end
      end

      # 2. Background Music
      music_id = "background_music"
      if @data['background_music']
        state_music = current_state['background_music']
        if state_music && (state_music['status'] == 'done' || state_music['status'] == 'verified')
          puts Rainbow("  ⏭️  Skipping Background Music (already done)").blue
        else
          orchestrator.add_task(music_id) do
            update_task_status('background_music', 'in_progress')
            music_dir = File.join(@output_path, "audio")
            FileUtils.mkdir_p(music_dir)
            music_output = File.join(music_dir, "background_music.wav")
            
            lyria_generator.generate(@data['background_music']['prompt'], music_output, asset_id: "Story.music")
            update_task_status('background_music', 'done')
          end
          page_task_ids << music_id
        end
      end

      # 3. Final Story Assembly
      story_md_id = "final_story_assembly"
      state_assembly = current_state['final_story_assembly']
      if state_assembly && state_assembly['status'] == 'done'
        puts Rainbow("  ⏭️  Skipping Final Story Assembly (already done)").blue
      else
        orchestrator.add_task(story_md_id, dependencies: page_task_ids) do
          update_task_status('final_story_assembly', 'in_progress')
          puts Rainbow("📖 Assembling final story Markdown...").magenta
          generate_final_story
          update_task_status('final_story_assembly', 'done')
        end
      end

      orchestrator.run
      update_status('done')
    end

    private

    def generate_final_story
      content = "# #{@story_title}\n\n"
      
      if @data['background_music']
        content += "🎵 **Background Music:** [#{@data['background_music']['prompt']}](audio/background_music.wav)\n\n"
      end

      @pages.each do |page|
        num = page['page']
        image_rel_path = "pages/page_#{num}/illustration.png"
        text_file = File.join(@output_path, "pages", "page_#{num}", "story_text.txt")
        display_text = File.exist?(text_file) ? File.read(text_file) : page['text']

        content += "## Page #{num}\n\n"
        content += "![Page #{num}](#{image_rel_path})\n\n"
        content += "#{display_text}\n\n"
        content += "---\n\n"
      end

      story_file = File.join(@output_path, "STORY.md")
      File.write(story_file, content)
      puts Rainbow("✅ Final story saved to #{story_file}").green
    end

    def validate_page(page, image_output)
      v_result = Validator.validate_and_rename!(image_output, :image)
      if v_result[:success]
        # Perform Character Consistency EVAL
        evaluator = Evaluator.new
        e_result = evaluator.evaluate_character_consistency(image_output, @character)
        
        # Save Eval result to asset json
        asset_json = "#{image_output}.asset.json"
        if File.exist?(asset_json)
          asset_data = ::JSON.parse(File.read(asset_json))
          asset_data['eval'] = e_result
          File.write(asset_json, ::JSON.pretty_generate(asset_data))
        end

        if e_result[:success]
          update_page_status(page['page'], 'verified')
        else
          update_page_status(page['page'], 'done_with_warnings', "CC Score: #{e_result[:score]}/10 - #{e_result[:message]}")
        end
      else
        update_page_status(page['page'], 'failed', v_result[:message])
      end
    end

    def update_task_status(task_key, status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state[task_key] ||= {}
        state[task_key]['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def update_page_status(page_num, status, error_msg = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        page = state['pages'].find { |p| p['page'] == page_num }
        if page
          page['status'] = status
          page['error'] = error_msg if error_msg
        end
        File.write(state_file, state.to_yaml)
      end
    end

    def update_status(status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), '.state.yaml')
        state = YAML.load_file(state_file)
        state['status'] = status
        File.write(state_file, state.to_yaml)
      end
    end
  end
end
