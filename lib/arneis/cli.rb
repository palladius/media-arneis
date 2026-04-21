=begin
Arneis::Cli - Implementation of the arnectl command-line interface.
=end

require 'thor'
require 'rainbow'
require 'yaml'
require 'json'
require 'fileutils'
require 'time'

module Arneis
  class CharactersCli < Thor; end

  class Cli < Thor
    class_option :async, type: :boolean, default: true, desc: "Run media generation asynchronously using Fibers"
    class_option :media_folder, type: :string, aliases: "-f", desc: "Explicitly set the media folder"

    def initialize(*args)
      super
      Config.load!
    end

    desc "version", "Show arnectl version"
    def version
      puts "arnectl version #{Arneis::VERSION} 🍷"
    end

    desc "characters SUBCOMMAND ...ARGS", "Manage characters"
    subcommand "characters", CharactersCli

    desc "apply YAML_PATH", "Initialize and start a media project from a YAML specification"
    method_option :dryrun, type: :boolean, aliases: "-n", desc: "Validate YAML and dependencies without executing"
    method_option :output, type: :string, aliases: "-o", desc: "Custom output folder (defaults to timestamped)"
    def apply(yaml_path)
      if %w[--help -h].include?(yaml_path)
        help("apply")
        return
      end
      puts Rainbow("🎨 Applying #{yaml_path}...").green
      project = VideoProject.new(yaml_path)
      
      output_path = options[:output] || "out/#{Time.now.strftime('%Y%m%d_%H%M%S')}_#{File.basename(yaml_path, '.*')}"
      
      project.initialize_output(output_path)
      puts Rainbow("🚀 Project initialized at #{output_path}").blue
      
      puts Rainbow("⚙️ Starting orchestration...").magenta
      project.process(async: options[:async])
      puts Rainbow("✅ Generation complete!").green
    end

    desc "feedback [FOLDER_PATH] -p, --prompt=PROMPT", "Provide natural language feedback on a specific asset"
    method_option :prompt, type: :string, required: true, aliases: "-p", desc: "Your feedback"
    def feedback(folder_path = nil)
      folder_path = resolve_media_folder([folder_path], options) rescue nil
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      puts Rainbow("💬 Processing feedback for #{folder_path}...").cyan
      
      state_file = File.join(folder_path, '.state.yaml')
      state = YAML.load_file(state_file)
      
      asset_id = nil
      if options[:prompt] =~ /^(video|text)(\d+)$/i
        type = $1.downcase == 'video' ? 'video' : 'text'
        scene_num = $2
        asset_id = "Scene#{scene_num}.#{type}"
      else
        gemini = Generator::Gemini.new
        system_prompt = "You are an expert Media Assistant. Identify the EXACT asset_id (e.g., 'Scene3.video' or 'Project.music') the user is talking about. Return 'Project' for general feedback. Output ONLY the asset_id."
        
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

      if asset_id =~ /Scene(\d+)\.(video|text)/
        scene_num = $1.to_i
        type = $2
        
        trash_dir = File.join(folder_path, ".trash", Time.now.strftime('%Y%m%d_%H%M%S'))
        FileUtils.mkdir_p(trash_dir)
        
        target_file = File.join(folder_path, "scene_#{scene_num}.#{type == 'video' ? 'mp4' : 'text.txt'}")
        if File.exist?(target_file)
          puts "  🗑️  Archiving #{File.basename(target_file)} to .trash/"
          FileUtils.mv(target_file, trash_dir)
          Dir.glob("#{target_file}*").each { |f| FileUtils.mv(f, trash_dir) }
        end

        scene = state['scenes'].find { |s| s['scene'] == scene_num }
        if scene
          scene['status'] = 'pending'
          scene['feedback'] = options[:prompt]
          scene['human_score'] = 5
          File.write(state_file, state.to_yaml)
          puts Rainbow("✅ Scene #{scene_num} reset to pending. Run 'arnectl resume' to regenerate.").green
        end
      else
        puts Rainbow("⚠️  Could not map '#{asset_id}' to an automated action.").yellow
      end
    end

    desc "resume [FOLDER_PATH]", "Resume a media project from its state file"
    method_option :force, type: :boolean, aliases: "-f", desc: "Force retry of failed or mocked tasks"
    def resume(folder_path = nil)
      folder_path = resolve_media_folder([folder_path], options) rescue nil
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      puts Rainbow("🚀 Resuming #{folder_path}...").green
      
      state_file = File.join(folder_path, '.state.yaml')
      if options[:force]
        puts Rainbow("  🔥 Force flag detected. Resetting non-done tasks...").yellow
        state = YAML.load_file(state_file)
        state['scenes'].each do |s|
          video_file = File.join(folder_path, "scene_#{s['scene']}.mp4")
          if s['status'] == 'failed' || s['status'] == 'done_with_warnings' || !File.exist?(video_file) || File.exist?("#{video_file}.mock")
            s['status'] = 'pending'
          end
        end
        if state['background_music']
          music_file = File.join(folder_path, "background_music.wav")
          if state['background_music']['status'] == 'failed' || !File.exist?(music_file) || File.exist?("#{music_file}.mock")
            state['background_music']['status'] = 'pending'
          end
        end
        File.write(state_file, state.to_yaml)
      end

      yaml_files = Dir.glob(File.join(folder_path, "*.yaml"))
      if yaml_files.empty?
        puts Rainbow("❌ No YAML found in #{folder_path} to resume from").red
        return
      end

      project = VideoProject.new(yaml_files.first)
      project.instance_variable_set(:@output_path, folder_path)
      
      puts Rainbow("⚙️ Resuming orchestration...").magenta
      project.process(async: options[:async])
      puts Rainbow("✅ Resume complete!").green
    end

    desc "status [FOLDER_PATH]", "Show real-time status of a media project"
    def status(folder_path = nil)
      folder_path = resolve_media_folder([folder_path], options) rescue nil
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      
      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
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
      
      total_tokens = 0
      total_cost = 0.0
      input_tokens = 0
      output_tokens = 0

      puts "\nScenes:"
      state['scenes'].each do |scene|
        desc = scene['description']
        desc = "#{desc[0..76]}..." if desc.length > 80
        
        video_file = File.join(folder_path, "scene_#{scene['scene']}.mp4")
        mock_file = "#{video_file}.mock"
        bad_file = "#{video_file}.NOT_GOOD"
        asset_json = "#{video_file}.asset.json"
        
        eval_indicator = "🟣"
        eval_score = ""
        if File.exist?(asset_json)
          asset_data = ::JSON.parse(File.read(asset_json))
          if asset_data['eval']
            eval_indicator = asset_data['eval']['success'] ? "👍" : "👎"
            eval_score = " (⭐ #{asset_data['eval']['score']}/10)"
          end
        end

        suffix = ""
        suffix = Rainbow(" 🤡").yellow if File.exist?(mock_file)
        suffix = Rainbow(" 🚫 INVALID").red if File.exist?(bad_file)

        puts "  #{status_emoji(scene['status'])} 🎥 #{eval_indicator}" + Rainbow(" Scene #{scene['scene']}:").orange + " " + Rainbow(desc).white + eval_score + suffix
        
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

        Dir.glob("#{output_base}.*.asset.json").each do |receipt_file|
          receipt = ::JSON.parse(File.read(receipt_file))
          input_tokens += receipt['input_tokens'] || 0
          output_tokens += receipt['output_tokens'] || 0
          total_tokens += (receipt['input_tokens'] || 0) + (receipt['output_tokens'] || 0)
          total_cost += receipt['cost_usd'] || 0.0
        end
      end

      puts "\nProject Tasks:"
      if state['background_music']
        music_file = File.join(folder_path, "background_music.wav")
        mock_music = "#{music_file}.mock"
        bad_music = "#{music_file}.NOT_GOOD"
        asset_json = "#{music_file}.asset.json"
        eval_indicator = File.exist?(asset_json) ? "👍" : "🟣"
        suffix = ""
        suffix = Rainbow(" 🤡").yellow if File.exist?(mock_music)
        suffix = Rainbow(" 🚫 INVALID").red if File.exist?(bad_music)
        puts "  #{status_emoji(state['background_music']['status'])} 🎵 #{eval_indicator} Background Music" + suffix
      end
      if state['montage']
        montage_file = File.join(folder_path, state['output_filename'] || "final_video.mp4")
        mock_montage = "#{montage_file}.mock"
        bad_montage = "#{montage_file}.NOT_GOOD"
        asset_json = "#{montage_file}.asset.json"
        eval_indicator = File.exist?(asset_json) ? "👍" : "🟣"
        suffix = ""
        suffix = Rainbow(" 🤡").yellow if File.exist?(mock_montage)
        suffix = Rainbow(" 🚫 INVALID").red if File.exist?(bad_montage)
        puts "  #{status_emoji(state['montage']['status'])} 🎞️  #{eval_indicator} Final Montage" + suffix
      end

      puts Rainbow("\n📊 Stats: 🪙 #{total_tokens} (⬆️ #{input_tokens} ⬇️ #{output_tokens}) | 💸 $#{'%.2f' % total_cost}").cyan.bold
    end

    desc "list", "List all meaningful projects in out/"
    def list
      puts Rainbow("📂 Listing Arneis projects...").cyan.bold
      projects_paths = Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }
      
      if projects_paths.empty?
        puts "No projects found."
        return
      end

      data = projects_paths.sort_by { |f| File.mtime(f) }.reverse.map do |path|
        state = YAML.load_file(File.join(path, '.state.yaml'))
        title = state['project_title'] || File.basename(path)
        status = state['status']
        
        all_media = Dir.glob(File.join(path, "*.{mp4,png,wav}"))
        real_media = all_media.reject { |f| File.exist?("#{f}.mock") || File.exist?("#{f}.NOT_GOOD") }
        mock_media_files = Dir.glob(File.join(path, "*.mock"))
        bad_media_files = Dir.glob(File.join(path, "*.NOT_GOOD"))
        
        honest_status = status
        if status == 'done' && real_media.empty?
          honest_status = bad_media_files.empty? ? 'mocked' : 'failed'
        end
        honest_status = 'failed' if !bad_media_files.empty?

        total_cost = 0.0
        Dir.glob(File.join(path, "*.asset.json")).each do |f|
          total_cost += ::JSON.parse(File.read(f))['cost_usd'] || 0.0
        end

        mtime = File.mtime(path).strftime("%Y-%m-%d %H:%M")
        is_symlink = File.symlink?(path.chomp('/'))
        
        {
          path: path,
          mtime: mtime,
          is_symlink: is_symlink,
          status: honest_status,
          title: title,
          cost: total_cost,
          video_count: real_media.select { |f| f.end_with?('.mp4') }.count,
          image_count: real_media.select { |f| f.end_with?('.png') }.count,
          audio_count: real_media.select { |f| f.end_with?('.wav') || f.end_with?('.mp3') }.count,
          text_count: Dir.glob(File.join(path, "*.{txt,md}")).count
        }
      end

      max_path = data.map { |d| d[:path].length }.max
      data.each do |d|
        folder_color = d[:is_symlink] ? :cyan : :blue
        folder_emoji = d[:is_symlink] ? "🔗" : "📂"
        
        media_stats = []
        media_stats << "#{d[:video_count]}🎥" if d[:video_count] > 0
        media_stats << "#{d[:image_count]}🖼️" if d[:image_count] > 0
        media_stats << "#{d[:audio_count]}🎵" if d[:audio_count] > 0
        media_stats << "#{d[:text_count]}📝" if d[:text_count] > 0
        
        total_assets = d[:video_count] + d[:image_count] + d[:audio_count] + d[:text_count]
        stats_str = ""
        stats_str += "🫘 #{total_assets}: " if total_assets > 0
        stats_str += media_stats.join(" ")
        
        display_title = d[:title].length > 40 ? "#{d[:title][0...37]}..." : d[:title].ljust(40)
        puts "#{folder_emoji} #{Rainbow(d[:path].ljust(max_path + 1)).send(folder_color)} #{status_emoji(d[:status])} #{Rainbow(display_title).yellow} 💸 $#{'%.2f' % d[:cost]} #{stats_str}"
      end
    end

    desc "cleanup", "Archive projects without any REAL media to out/archived/"
    def cleanup
      puts Rainbow("🧹 Starting aggressive deterministic cleanup...").cyan
      projects = Dir.glob("out/*/").reject { |f| f.include?('archived') }
      archived_count = 0
      projects.each do |path|
        # Real media = exists and no .mock / .NOT_GOOD
        media_files = Dir.glob(File.join(path, "*.{mp4,png,wav,mp3}"))
        real_media = media_files.reject { |f| File.exist?("#{f}.mock") || File.exist?("#{f}.NOT_GOOD") }
        
        if real_media.empty?
          puts "  📦 Archiving project with ZERO real media: #{path}"
          FileUtils.mkdir_p("out/archived")
          # Handle potential symlinks or busy folders
          begin
            FileUtils.mv(path, File.join("out/archived", File.basename(path)))
            archived_count += 1
          rescue => e
            puts Rainbow("    ⚠️  Failed to move #{path}: #{e.message}").yellow
          end
        end
      end
      puts Rainbow("✅ Cleanup complete. Archived #{archived_count} junk projects.").green
    end

    desc "check-fake-media [FOLDER_PATH]", "Rigorously verify all media files in a project or all projects"
    def check_fake_media(folder_path = nil)
      folder_path = resolve_media_folder([folder_path], options) rescue "out"
      search_path = folder_path ? File.join(folder_path, "**", "*.{mp4,png,wav}") : "out/**/*.{mp4,png,wav}"
      puts Rainbow("🛡️  Rigorously checking media artifacts in #{search_path}...").cyan.bold
      
      files = Dir.glob(search_path).reject do |f| 
        f.include?('.mock') || f.include?('.NOT_GOOD') || f.include?('archived/')
      end
      
      if files.empty?
        puts "No media files found to check."
        return
      end

      found_fakes = 0
      files.each do |file|
        type = case File.extname(file).downcase
               when '.mp4' then :video
               when '.png' then :image
               when '.wav' then :audio
               end
        
        result = Validator.validate_and_rename!(file, type)
        if result[:success]
          puts "  ✅ #{file}: #{Rainbow("REAL").green} (#{result[:info]})"
        else
          puts "  ❌ #{file}: #{Rainbow("FAKE").red} (#{result[:info]}) -> Renamed to .NOT_GOOD"
          found_fakes += 1
        end
      end

      if found_fakes > 0
        puts Rainbow("\n⚠️  Found and neutralized #{found_fakes} fake media files!").yellow.bold
      else
        puts Rainbow("\n✨ All checked media files are genuine.").green.bold
      end
    end

    desc "graph YAML_PATH", "Generate a Mermaid.js dependency graph"
    method_option :output, type: :string, aliases: "-o", desc: "Output file"
    def graph(yaml_path)
      if %w[--help -h].include?(yaml_path)
        help("graph")
        return
      end
      puts Rainbow("📊 Generating graph for #{yaml_path}...").cyan
      project = VideoProject.new(yaml_path)
      tasks = []
      scene_task_ids = []
      project.scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}".to_sym
        tasks << Arneis::Task.new(scene_id)
        scene_task_ids << scene_id
      end
      if project.data['background_music']
        tasks << Arneis::Task.new(:background_music)
        scene_task_ids << :background_music
      end
      tasks << Arneis::Task.new(:montage, dependencies: scene_task_ids)
      visualizer = Visualizer.new(tasks)
      mermaid = visualizer.to_mermaid
      latest_project = Dir.glob("out/*/").select { |f| File.exist?(File.join(f, '.state.yaml')) }.max_by { |f| File.mtime(f) }
      output_dir = latest_project || "out/latest_graph"
      FileUtils.mkdir_p(output_dir)
      output_file = options[:output] || File.join(output_dir, "DEPENDENCIES.md")
      content = "# Dependency Graph: #{project.title}\n\n```mermaid\n#{mermaid}\n```"
      File.write(output_file, content)
      puts Rainbow("✅ Graph generated and saved to #{output_file}").green
    end

    desc "research-pitch RESEARCH_PATH", "Generate a sales pitch YAML"
    def research_pitch(research_path)
      if %w[--help -h].include?(research_path)
        help("research_pitch")
        return
      end
      puts Rainbow("🧠 Researching #{research_path}...").cyan
      research_content = File.read(research_path)
      template_content = File.read('data/templates/VideoProject.yaml')
      gemini = Generator::Gemini.new
      system_prompt = "You are an expert Copywriter. Create a VideoProject YAML based on the research. Follow the schema. Output ONLY the YAML."
      resp = gemini.generate(research_content, system_instruction: system_prompt)
      yaml_content = resp[:content].gsub(/```yaml\n|```/, '')
      output_file = "data/samples/#{File.basename(research_path, '.*')}.yaml"
      File.write(output_file, yaml_content)
      puts Rainbow("✅ Pitch generated and saved to #{output_file}").green
    end

    no_commands do
      def resolve_media_folder(args = [], options = {})
        # Precedence:
        # 1. Command-line flag (-f / --media-folder)
        # 2. Positional argument
        # 3. Environment variable (ARNEIS_FOLDER)
        
        folder = options['media_folder'] || args.first || ENV['ARNEIS_FOLDER']
        
        if folder.nil? || folder.empty?
          raise "No media folder specified. Use -f, a positional argument, or set ARNEIS_FOLDER ENV."
        end
        
        folder
      end

      def status_emoji(status)
        case status
        when 'verified' then "⚖️ "
        when 'done' then "🟢"
        when 'polling' then "🔵"
        when 'mocked' then "🤡"
        when 'done_with_warnings' then "😟"
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
