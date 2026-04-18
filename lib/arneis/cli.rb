=begin
Arneis::Cli - Implementation of the arnectl command-line interface.
=end

require 'thor'
require 'rainbow'
require 'yaml'
require 'json'

module Arneis
  class Cli < Thor
    def initialize(*args)
      super
      Config.load!
    end

    desc "version", "Show arnectl version"
    def version
      puts "arnectl version #{Arneis::VERSION} 🍷"
    end

    desc "apply YAML_PATH", "Initialize and start a media project from a YAML specification"
    method_option :dryrun, type: :boolean, aliases: "-n", desc: "Validate YAML and dependencies without executing"
    def apply(yaml_path)
      puts Rainbow("🎨 Applying #{yaml_path}...").green
      project = VideoProject.new(yaml_path)
      output_path = "out/#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{File.basename(yaml_path, '.*')}"
      project.initialize_output(output_path)
      puts Rainbow("🚀 Project initialized at #{output_path}").blue
      
      puts Rainbow("⚙️ Starting orchestration...").magenta
      project.process
      puts Rainbow("✅ Generation complete!").green
    end

    desc "feedback [FOLDER_PATH] -p, --prompt=PROMPT", "Provide natural language feedback on a specific asset"
    method_option :prompt, type: :string, required: true, aliases: "-p", desc: "Your feedback"
    def feedback(folder_path = nil)
      # If first argument isn't a folder, it might be the prompt if not using -p, 
      # but Thor handles options separately.
      # If folder_path is nil, default to latest
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found in out/").red
        return
      end

      puts Rainbow("💬 Processing feedback for #{folder_path}...").cyan
      
      state_file = File.join(folder_path, '.state.yaml')
      state = YAML.load_file(state_file)
      
      # Try direct mapping first (e.g., video3, text2)
      asset_id = nil
      if options[:prompt] =~ /^(video|text)(\d+)$/i
        type = $1.downcase == 'video' ? 'video' : 'text'
        scene_num = $2
        asset_id = "Scene#{scene_num}.#{type}"
      else
        # Use Gemini to identify which asset the user is talking about
        gemini = Generator::Gemini.new
        system_prompt = "You are an expert Media Assistant. Given a user prompt and a list of project assets, identify the EXACT asset_id (e.g., 'Scene3.video' or 'Project.music') the user is talking about.
        If it's a general project feedback, return 'Project'.
        Output ONLY the asset_id, nothing else."
        
        asset_list = state['scenes'].map { |s| "Scene#{s['scene']}.video, Scene#{s['scene']}.text" }.join(", ")
        asset_list += ", Project.music" if state['background_music']
        
        identification_prompt = "User Feedback: '#{options[:prompt]}'\nAsset List: #{asset_list}"
        
        resp = gemini.generate(identification_prompt, system_instruction: system_prompt)
        asset_id = resp[:content].strip
      end
      
      puts Rainbow("🎯 Identified target: #{asset_id}").yellow
      
      if asset_id == 'Project'
        puts "  (General project feedback not yet implemented for automated regeneration)"
        return
      end

      # Parse asset_id (e.g., Scene3.video)
      if asset_id =~ /Scene(\d+)\.(video|text)/
        scene_num = $1.to_i
        type = $2
        
        # Archive to .trash/
        trash_dir = File.join(folder_path, ".trash", Time.now.strftime('%Y%m%d_%H%M%S'))
        FileUtils.mkdir_p(trash_dir)
        
        target_file = File.join(folder_path, "scene_#{scene_num}.#{type == 'video' ? 'mp4' : 'text.txt'}")
        if File.exist?(target_file)
          puts "  🗑️  Archiving #{File.basename(target_file)} to .trash/"
          FileUtils.mv(target_file, trash_dir)
          # Also move receipts and asset json
          Dir.glob("#{target_file}*").each { |f| FileUtils.mv(f, trash_dir) }
        end

        # Reset status in .state.yaml
        scene = state['scenes'].find { |s| s['scene'] == scene_num }
        if scene
          scene['status'] = 'pending'
          # Also store feedback for future regeneration
          scene['feedback'] = options[:prompt]
          File.write(state_file, state.to_yaml)
          puts Rainbow("✅ Scene #{scene_num} reset to pending. Run 'arnectl resume' to regenerate.").green
        end
      else
        puts Rainbow("⚠️  Could not map '#{asset_id}' to an automated action.").yellow
      end
    end

    desc "resume [FOLDER_PATH]", "Resume a media project from its state file (defaults to latest in out/)"
    def resume(folder_path = nil)
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found in out/").red
        return
      end

      puts Rainbow("🚀 Resuming #{folder_path}...").green
      # Note: We need a way to load a project from an existing folder
      # For now, let's assume the YAML is still there
      yaml_files = Dir.glob(File.join(folder_path, "*.yaml"))
      if yaml_files.empty?
        puts Rainbow("❌ No YAML found in #{folder_path} to resume from").red
        return
      end

      project = VideoProject.new(yaml_files.first)
      project.instance_variable_set(:@output_path, folder_path) # Direct injection for resume
      
      puts Rainbow("⚙️ Resuming orchestration...").magenta
      project.process
      puts Rainbow("✅ Resume complete!").green
    end

    desc "status [FOLDER_PATH]", "Show real-time status of a media project (defaults to latest in out/)"
    def status(folder_path = nil)
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found in out/").red
        return
      end

      puts Rainbow("🔍 Checking status of ").yellow + Rainbow(folder_path).cyan
      state_file = File.join(folder_path, '.state.yaml')
      unless File.exist?(state_file)
        puts Rainbow("❌ No state file found in #{folder_path}").red
        return
      end

      state = YAML.load_file(state_file)
      puts "Project: #{Rainbow(state['project_title']).yellow}"
      puts "Status: #{status_emoji(state['status'])} #{state['status']} | Auth: #{Config.auth_method_emoji}"
      
      # Calculate stats
      total_tokens = 0
      total_cost = 0.0
      input_tokens = 0
      output_tokens = 0

      # Scenes
      puts "\nScenes:"
      state['scenes'].each do |scene|
        desc = scene['description']
        desc = "#{desc[0..76]}..." if desc.length > 80
        
        # Check if file exists or is mocked
        video_file = File.join(folder_path, "scene_#{scene['scene']}.mp4")
        mock_file = "#{video_file}.mock"
        asset_json = "#{video_file}.asset.json"
        
        # Eval indicators
        eval_indicator = "🟣" # Not evaluated
        eval_score = ""
        if File.exist?(asset_json)
          asset_data = ::JSON.parse(File.read(asset_json))
          if asset_data['eval']
            eval_indicator = asset_data['eval']['success'] ? "👍" : "👎"
            eval_score = " (⭐ #{asset_data['eval']['score']}/10)"
          end
        end

        puts "  #{status_emoji(scene['status'])} 🎥 #{eval_indicator}" + Rainbow(" Scene #{scene['scene']}:").orange + " " + Rainbow(desc).white + eval_score + (File.exist?(mock_file) ? Rainbow(" 🤡").yellow : "")
        
        # Check for errors in the output folder
        output_base = File.join(folder_path, "scene_#{scene['scene']}")
        Dir.glob("#{output_base}.*.error.json").each do |error_file|
          error_data = ::JSON.parse(File.read(error_file))
          err_msg = error_data['error']
          model_name = error_data['model'] || error_file.split('.').first.split('_').last
          
          if err_msg.include?('429')
            puts Rainbow("    ❌ 429 (#{model_name})").red
          else
            puts Rainbow("    ❌ Error (#{model_name}): #{Config.sanitize(err_msg)}").red
          end
        end

        # Aggregate stats from standardized asset receipts
        Dir.glob("#{output_base}.*.asset.json").each do |receipt_file|
          receipt = ::JSON.parse(File.read(receipt_file))
          input_tokens += receipt['input_tokens'] || 0
          output_tokens += receipt['output_tokens'] || 0
          total_tokens += (receipt['input_tokens'] || 0) + (receipt['output_tokens'] || 0)
          total_cost += receipt['cost_usd'] || 0.0
        end
      end

      # Project-wide tasks
      puts "\nProject Tasks:"
      if state['background_music']
        music_file = File.join(folder_path, "background_music.wav")
        mock_music = "#{music_file}.mock"
        puts "  #{status_emoji(state['background_music']['status'])} 🎵 Background Music" + (File.exist?(mock_music) ? Rainbow(" 🤡").yellow : "")
        
        # Check for music errors
        Dir.glob(File.join(folder_path, "background_music.*.error.json")).each do |error_file|
          error_data = ::JSON.parse(File.read(error_file))
          puts Rainbow("    ❌ Error: #{Config.sanitize(error_data['error'])}").red
        end
      end
      if state['montage']
        montage_file = File.join(folder_path, state['output_filename'] || "final_video.mp4")
        mock_montage = "#{montage_file}.mock"
        puts "  #{status_emoji(state['montage']['status'])} 🎞️  Final Montage" + (File.exist?(mock_montage) ? Rainbow(" 🤡").yellow : "")
        
        # Check for montage errors
        Dir.glob(File.join(folder_path, "montage.*.error.json")).each do |error_file|
          error_data = ::JSON.parse(File.read(error_file))
          puts Rainbow("    ❌ Error: #{Config.sanitize(error_data['error'])}").red
        end
      end

      puts Rainbow("\n📊 Stats: 🪙 #{total_tokens} (⬆️ #{input_tokens} ⬇️ #{output_tokens}) | 💸 $#{'%.2f' % total_cost}").cyan.bold
    end

    desc "stats FOLDER_PATH", "Show resource usage and cost for a media project"
    def stats(folder_path)
      puts Rainbow("📊 Calculating stats for #{folder_path}...").cyan
      # This will eventually pull from the state file and logs
      puts "Total Tokens: 0"
      puts "Estimated Cost: $0.00"
      puts "Time Elapsed: 0s"
    end

    desc "verify FOLDER_PATH", "Verify the integrity of all media artifacts in a project folder"
    def verify(folder_path)
      puts Rainbow("🛡️  Verifying artifacts in #{folder_path}...").cyan
      state_file = File.join(folder_path, '.state.yaml')
      unless File.exist?(state_file)
        puts Rainbow("❌ No state file found in #{folder_path}").red
        return
      end

      state = YAML.load_file(state_file)
      state['scenes'].each do |scene|
        video_file = File.join(folder_path, "scene_#{scene['scene']}.mp4")
        puts "Scene #{scene['scene']}:"
        result = Validator.verify(video_file, :video)
        if result[:success]
          puts Rainbow("  ✅ Video: #{result[:info]}").green
        else
          puts Rainbow("  ❌ Video: #{result[:message]}").red
        end
      end
    end

    desc "graph YAML_PATH", "Generate a Mermaid.js dependency graph for a project"
    method_option :output, type: :string, aliases: "-o", desc: "Output file (default: graph.md)"
    def graph(yaml_path)
      puts Rainbow("📊 Generating graph for #{yaml_path}...").cyan
      project = VideoProject.new(yaml_path)
      
      tasks = []
      scene_task_ids = []

      # 1. Scenes
      project.scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}".to_sym
        tasks << Arneis::Task.new(scene_id)
        scene_task_ids << scene_id
      end
      
      # 2. Music
      if project.data['background_music']
        tasks << Arneis::Task.new(:background_music)
        scene_task_ids << :background_music
      end

      # 3. Montage
      tasks << Arneis::Task.new(:montage, dependencies: scene_task_ids)

      visualizer = Visualizer.new(tasks)
      mermaid = visualizer.to_mermaid
      
      # Determine output folder
      # Heuristic: if we have a folder path in out/ with a state file, use it
      latest_project = Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      output_dir = latest_project || "out/latest_graph"
      FileUtils.mkdir_p(output_dir)
      
      output_file = options[:output] || File.join(output_dir, "DEPENDENCIES.md")
      content = "# Dependency Graph: #{project.title}\n\n```mermaid\n#{mermaid}\n```"
      File.write(output_file, content)
      
      puts Rainbow("✅ Graph generated and saved to #{output_file}").green
    end

    desc "research-pitch RESEARCH_PATH", "Generate a compelling sales pitch YAML from a research document"
    def research_pitch(research_path)
      puts Rainbow("🧠 Researching #{research_path}...").cyan
      research_content = File.read(research_path)
      template_content = File.read('data/templates/VideoProject.yaml')
      
      gemini = Generator::Gemini.new
      system_prompt = "You are an expert Copywriter and Video Producer. Create a VideoProject YAML based on the provided research.
      The goal is to sell tickets. 
      CRITICAL: You MUST follow the schema provided in the template.
      
      TEMPLATE SCHEMA:
      #{template_content}
      
      Output ONLY the YAML."
      
      response = gemini.generate(research_content, system_instruction: system_prompt)
      yaml_content = response[:content].gsub(/```yaml\n|```/, '') # Clean up markdown
      
      output_file = "data/samples/#{File.basename(research_path, '.*')}.yaml"
      File.write(output_file, yaml_content)
      
      puts Rainbow("✅ Pitch generated and saved to #{output_file}").green
    end

    no_commands do
      def status_emoji(status)
        case status
        when 'done' then "🟢"
        when 'done_with_warnings' then "⚖️ "
        when 'in_progress' then "🟡"
        when 'pending' then "⚪"
        when 'waiting' then "🩶"
        when 'failed' then "🔴"
        when 'initialized' then "🚀"
        else "❓"
        end
      end
    end

    def self.exit_on_failure?
      true
    end
  end
end
