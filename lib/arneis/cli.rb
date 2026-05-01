# Arneis::Cli - Implementation of the arnectl command-line interface.

require "thor"
require "rainbow"
require "yaml"
require "json"
require "fileutils"
require "time"

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
    # Note: --force should NOT delete files. I would expect from a --force to kill other similar processes and suff or force some potentially unreliabile thing, but NOT to delete files
    method_option :force_clean, type: :boolean, default: false, desc: "Force a clean run by deleting the output directory if it exists"
    method_option :verify, type: :boolean, default: false, desc: "Enable multimodal E2E verification of generated artifacts"
    def apply(yaml_path)
      if %w[--help -h].include?(yaml_path)
        help("apply")
        return
      end
      puts Rainbow("🎨 Applying #{yaml_path}...").green
      
      output_path = options[:media_folder] || options[:output] || "out/#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{File.basename(yaml_path, ".*")}"
      if options[:force_clean] && Dir.exist?(output_path)
        puts Rainbow("  🔥 Deleting existing output directory due to --force flag: #{output_path}").yellow
        FileUtils.rm_rf(output_path)
      end
      
      project = Arneis.load_project(yaml_path)

      output_path = options[:media_folder] || options[:output] || "out/#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{File.basename(yaml_path, ".*")}"

      puts Rainbow("🚀 Project initialized at #{output_path}").blue

      puts Rainbow("⚙️ Starting orchestration...").magenta
      project.process(async: options[:async], verify: options[:verify], dryrun: options[:dryrun])
      puts Rainbow("✅ Generation complete!").green
    end

    desc "feedback [FOLDER_PATH] -p, --prompt=PROMPT", "Provide natural language feedback on a specific asset"
    method_option :prompt, type: :string, required: true, aliases: "-p", desc: "Your feedback"
    def feedback(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      puts Rainbow("💬 Processing feedback for #{folder_path}...").cyan

      state_file = File.join(folder_path, ".state.yaml")
      state = YAML.load_file(state_file)

      # 1. Identify which asset the user is talking about
      puts "  🧠 Gemini identifying target asset..."

      # Build a list of assets for Gemini to choose from
      items = state["scenes"] || state["pages"] || []
      asset_list = items.map { |i| "ID: #{state["scenes"] ? "scene_#{i["scene"]}" : "page_#{i["page"]}"}, Description: #{i["description"]}" }
      asset_list << "ID: background_music, Description: Background music for the project"

      gemini = Generator::Gemini.new
      id_prompt = "Based on the user feedback: '#{options[:prompt]}', identify which Asset ID they are referring to from this list:
      #{asset_list.join("\n")}

      Output ONLY the Asset ID (e.g., 'scene_1' or 'background_music'). If unclear, output 'unknown'."

      id_resp = gemini.generate(id_prompt)
      target_id = id_resp[:content].strip.gsub(/['"]/, "")

      if target_id == "unknown"
        puts Rainbow("  🤔 Gemini couldn't identify the target asset. Please be more specific.").yellow
        return
      end

      puts Rainbow("  🎯 Target identified: #{target_id}").green

      # 2. Archive to .trash/
      trash_dir = File.join(folder_path, ".trash", Time.now.strftime("%Y%m%d_%H%M%S"))
      FileUtils.mkdir_p(trash_dir)

      # Identify file paths to trash
      to_trash = []
      if target_id == "background_music"
        to_trash << File.join(folder_path, "audio", "background_music.wav")
      elsif target_id.start_with?("scene_")
        num = target_id.split("_").last
        to_trash << File.join(folder_path, "video", "scene_#{num}", "video.mp4")
        to_trash << File.join(folder_path, "video", "scene_#{num}", "video.mp4.asset.json")
      elsif target_id.start_with?("page_")
        num = target_id.split("_").last
        to_trash << File.join(folder_path, "pages", "page_#{num}", "illustration.png")
        to_trash << File.join(folder_path, "pages", "page_#{num}", "illustration.png.asset.json")
        to_trash << File.join(folder_path, "pages", "page_#{num}", "story_text.txt")
      end

      to_trash.each do |f|
        if File.exist?(f)
          puts "  🗑️  Trashing #{File.basename(f)}..."
          FileUtils.mv(f, File.join(trash_dir, File.basename(f)))
        end
      end

      # 3. Update .state.yaml
      if target_id == "background_music"
        state["background_music"]["status"] = "pending"
        state["background_music"]["feedback"] = options[:prompt]
      else
        num = target_id.split("_").last.to_i
        item = items.find { |i| (i["scene"] || i["page"]) == num }
        if item
          item["status"] = "pending"
          item["feedback"] = options[:prompt]
        end
      end

      # Also reset final assembly if it exists
      state["final_story_assembly"]["status"] = "pending" if state["final_story_assembly"]
      state["status"] = "in_progress"

      File.write(state_file, state.to_yaml)

      puts Rainbow("✅ Feedback recorded. Target #{target_id} reset to pending.").green
      puts Rainbow("🚀 Run 'just arnectl resume #{folder_path}' to re-generate with feedback.").blue
    end

    desc "resume [FOLDER_PATH]", "Resume a media project from its state file"
    method_option :force, type: :boolean, aliases: "-f", desc: "Force retry of failed or mocked tasks"
    def resume(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      puts Rainbow("🚀 Resuming #{folder_path}...").green

      state_file = File.join(folder_path, ".state.yaml")
      if options[:force]
        puts Rainbow("  🔥 Force flag detected. Resetting non-done tasks...").yellow
        state = YAML.load_file(state_file)

        # Handle both VideoProject (scenes) and KidsStory (pages)
        items = state["scenes"] || state["pages"] || []

        items.each do |item|
          num = item["scene"] || item["page"]
          item_dir = state["scenes"] ? "" : "pages/page_#{num}/"
          artifact_name = state["scenes"] ? "scene_#{num}.mp4" : "illustration.png"
          artifact_file = File.join(folder_path, item_dir, artifact_name)

          if %w[failed done_with_warnings in_progress].include?(item["status"]) || !File.exist?(artifact_file) || File.exist?("#{artifact_file}.mock")
            item["status"] = "pending"
          end
        end
        if state["background_music"]
          music_file = File.join(folder_path, "audio", "background_music.wav") # Note: added audio/ subfolder which was missing in original resume logic
          if %w[failed in_progress].include?(state["background_music"]["status"]) || !File.exist?(music_file) || File.exist?("#{music_file}.mock")
            state["background_music"]["status"] = "pending"
          end
        end
        # Also reset project-level tasks
        state.each do |key, value|
          next if %w[pages scenes status project_title story_title character_id story_audio metadata].include?(key)
          next unless value.is_a?(Hash) && value["status"]
          if %w[failed in_progress].include?(value["status"])
            value["status"] = "pending"
          end
        end
        if state["final_story_assembly"]
          story_file = File.join(folder_path, "STORY.md")
          if !File.exist?(story_file) || options[:force]
            state["final_story_assembly"]["status"] = "pending"
          end
        end
        File.write(state_file, state.to_yaml)
      end

      yaml_files = Dir.glob(File.join(folder_path, "*.yaml"))
      if yaml_files.empty?
        puts Rainbow("❌ No YAML found in #{folder_path} to resume from").red
        return
      end

      project = Arneis.load_project(yaml_files.first)
      project.instance_variable_set(:@output_path, folder_path)

      puts Rainbow("⚙️ Resuming orchestration...").magenta
      project.process(async: options[:async])
      puts Rainbow("✅ Resume complete!").green
    end

    desc "status [FOLDER_PATH]", "Show real-time status of a media project"
    def status(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      puts Rainbow("🔍 Checking status of ").yellow + Rainbow(folder_path).cyan
      state_file = File.join(folder_path, ".state.yaml")
      unless File.exist?(state_file)
        puts Rainbow("❌ No state file found in #{folder_path}").red
        return
      end

      state = YAML.load_file(state_file)
      title = state["project_title"] || state["story_title"] || File.basename(folder_path)
      puts "Project: #{Rainbow(title).yellow}"
      puts "Status: #{status_emoji(state["status"])} #{state["status"]} | Auth: #{Config.auth_method_emoji}"

      total_tokens = 0
      total_cost = 0.0
      input_tokens = 0
      output_tokens = 0
      min_score = 10

      # Handle both VideoProject (scenes) and KidsStory (pages)
      items = state["scenes"] || state["pages"] || []
      label = state["scenes"] ? "Scene" : "Page"
      icon = state["scenes"] ? "🎥" : "🖼️"
      has_failures = state["status"] == "failed"

      puts "\n#{label}s:"
      items.each do |item|
        num = item["scene"] || item["page"]
        desc = item["description"]
        desc = "#{desc[0..76]}..." if desc.length > 80

        has_failures = true if item["status"] == "failed"

        state["scenes"] ? ".mp4" : "/illustration.png"
        item_dir = state["scenes"] ? "" : "pages/page_#{num}/"
        artifact_file = File.join(folder_path, item_dir, "#{state["scenes"] ? "scene_#{num}" : "illustration"}#{state["scenes"] ? ".mp4" : ".png"}")

        mock_file = "#{artifact_file}.mock"
        bad_file = "#{artifact_file}.NOT_GOOD"
        asset_json = "#{artifact_file}.asset.json"

        eval_indicator = "⚫" # No eval implementation yet
        eval_score = ""
        if File.exist?(asset_json)
          asset_data = ::JSON.parse(File.read(asset_json))
          if asset_data["eval"]
            eval_indicator = asset_data["eval"]["success"] ? "👍" : "👎"
            score = asset_data["eval"]["score"]
            eval_score = " (⭐ #{score}/10)"
            min_score = [min_score, score].min
          end
        end

        suffix = ""
        suffix = Rainbow(" 🤡").yellow if File.exist?(mock_file)
        suffix = Rainbow(" 🚫 INVALID").red if File.exist?(bad_file)

        puts "  #{status_emoji(item["status"])} #{icon} #{eval_indicator}" + Rainbow(" #{label} #{num}:").orange + " " + Rainbow(desc).white + eval_score + suffix

        output_base = File.join(folder_path, item_dir, state["scenes"] ? "scene_#{num}" : "illustration")
        Dir.glob("#{output_base}.*.error.json").each do |error_file|
          error_data = ::JSON.parse(File.read(error_file))
          err_msg = error_data["error"]
          model_name = error_data["model"] || error_file.split(".").first.split("_").last

          if err_msg.include?("429")
            puts Rainbow("    ❌ 429 (#{model_name})").red
          else
            puts Rainbow("    ❌ Error (#{model_name}): #{Config.sanitize(err_msg)}").red
          end
        end

        Dir.glob("#{output_base}.*.asset.json").each do |receipt_file|
          receipt = ::JSON.parse(File.read(receipt_file))
          input_tokens += receipt["input_tokens"] || 0
          output_tokens += receipt["output_tokens"] || 0
          total_tokens += (receipt["input_tokens"] || 0) + (receipt["output_tokens"] || 0)
          total_cost += receipt["cost_usd"] || 0.0
        end
      end

      puts "\nProject Tasks:"
      # Show known specific tasks first
      if state["background_music"]
        status = state["background_music"]["status"]
        artifact_file = File.join(folder_path, "audio", "background_music.wav")
        mock_file = "#{artifact_file}.mock"
        bad_file = "#{artifact_file}.NOT_GOOD"
        asset_json = "#{artifact_file}.asset.json"
        eval_indicator = File.exist?(asset_json) ? "👍" : "🟣"
        suffix = ""
        suffix = Rainbow(" 🤡").yellow if File.exist?(mock_file)
        suffix = Rainbow(" 🚫 INVALID").red if File.exist?(bad_file)
        puts "  #{status_emoji(status)} 🎵 #{eval_indicator} Background Music" + suffix
      end
      
      # Show all other top-level keys that have a 'status' field and are not 'pages', 'scenes', or 'status'
      state.each do |key, value|
        next if %w[pages scenes status project_title story_title character_id story_audio metadata].include?(key)
        next unless value.is_a?(Hash) && value["status"]
        next if key == "background_music" # Already shown
        
        icon = case key
               when /audio/ then "🔊"
               when /assembly/ then "📖"
               when /montage/ then "🎞️ "
               when /marketing/ then "📢"
               else "⚙️ "
               end
        
        link = ""
        if key == "final_story_assembly"
          story_file = File.join(folder_path, "STORY.md")
          link = File.exist?(story_file) ? " -> " + Rainbow(story_file).cyan.underline : ""
        end

        puts "  #{status_emoji(value["status"])} #{icon} #{key.capitalize.gsub("_", " ")}#{link}"
      end

      puts Rainbow("\n📊 Stats: 🪙 #{total_tokens} (⬆️ #{input_tokens} ⬇️ #{output_tokens}) | 💸 $#{"%.2f" % total_cost}").cyan.bold

      if min_score < 6
        puts Rainbow("\n💡 Hint: Some evaluations are sub-optimal (score < 6).").yellow
        puts "   to automatically re-do the sub-optimal jobs, type: " + Rainbow("arnectl redo --threshold 6").white
      end

      if has_failures
        puts Rainbow("\n💡 Hint: Some parts failed. To fix, run:").yellow
        puts Rainbow("   just arnectl resume #{folder_path} --force").white
      end

      puts Rainbow("\nLegend: 🟢 done | 🔴 failed | 🟡 in_progress | ⚪ pending | 🤡 mocked | 👍/👎 evaluated | 🟣/⚫ unevaluated").gray.italic
    end

    desc "redo [FOLDER_PATH]", "Invalidate and redo sub-optimal generation tasks"
    method_option :threshold, type: :numeric, default: 6, aliases: "-t", desc: "Evaluation score threshold (0-10)"
    def redo(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found. Specify one or set ARNEIS_FOLDER.").red
        return
      end

      threshold = options[:threshold]
      puts Rainbow("🔄 Redoing tasks with evaluation score < #{threshold} in #{folder_path}...").cyan

      state_file = File.join(folder_path, ".state.yaml")
      state = YAML.load_file(state_file)

      # Handle both VideoProject (scenes) and KidsStory (pages)
      items = state["scenes"] || state["pages"] || []
      invalidated_count = 0
      trash_dir = File.join(folder_path, ".trash", "redo_#{Time.now.strftime("%Y%m%d_%H%M%S")}")

      items.each do |item|
        num = item["scene"] || item["page"]
        item_dir = state["scenes"] ? "" : "pages/page_#{num}/"
        artifact_base = File.join(folder_path, item_dir, state["scenes"] ? "scene_#{num}" : "illustration")
        
        # Check all possible media extensions
        media_file = Dir.glob("#{artifact_base}.{mp4,png,wav}").first
        next unless media_file

        asset_json = "#{media_file}.asset.json"
        next unless File.exist?(asset_json)

        asset_data = ::JSON.parse(File.read(asset_json))
        score = asset_data.dig("eval", "score") || 10

        if score < threshold
          puts Rainbow("  🗑️  Invalidating Page/Scene #{num} (Score: #{score})").yellow
          FileUtils.mkdir_p(trash_dir)
          
          # Move files to trash
          Dir.glob("#{artifact_base}*").each do |f|
            FileUtils.mv(f, File.join(trash_dir, File.basename(f)))
          end
          
          item["status"] = "pending"
          invalidated_count += 1
        end
      end

      if invalidated_count > 0
        state["status"] = "in_progress"
        # Also reset final assembly
        state["final_story_assembly"]["status"] = "pending" if state["final_story_assembly"]
        state["montage"]["status"] = "pending" if state["montage"]
        
        File.write(state_file, state.to_yaml)
        puts Rainbow("✅ Successfully invalidated #{invalidated_count} tasks.").green
        puts Rainbow("🚀 Run 'just arnectl resume #{folder_path}' to re-generate.").blue
      else
        puts Rainbow("✨ No tasks found below the threshold of #{threshold}.").green
      end
    end

    desc "list", "List all meaningful projects in out/"
    def list
      puts Rainbow("📂 Listing Arneis projects...").cyan.bold
      projects_paths = Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }

      if projects_paths.empty?
        puts "No projects found."
        return
      end

      data = projects_paths.sort_by { |f| File.mtime(f) }.reverse.map do |path|
        state = YAML.load_file(File.join(path, ".state.yaml"))
        title = state["project_title"] || state["story_title"] || File.basename(path)
        status = state["status"]

        all_media = Dir.glob(File.join(path, "**", "*.{mp4,png,wav}"))
        real_media = all_media.reject { |f| File.exist?("#{f}.mock") || File.exist?("#{f}.NOT_GOOD") }
        Dir.glob(File.join(path, "**", "*.mock"))
        bad_media_files = Dir.glob(File.join(path, "**", "*.NOT_GOOD"))

        honest_status = status
        if status == "done" && real_media.empty?
          honest_status = bad_media_files.empty? ? "mocked" : "failed"
        end
        honest_status = "failed" if !bad_media_files.empty?

        total_cost = 0.0
        Dir.glob(File.join(path, "**", "*.asset.json")).each do |f|
          total_cost += ::JSON.parse(File.read(f))["cost_usd"] || 0.0
        end

        mtime = File.mtime(path).strftime("%Y-%m-%d %H:%M")
        is_symlink = File.symlink?(path.chomp("/"))

        {
          path: path,
          mtime: mtime,
          is_symlink: is_symlink,
          status: honest_status,
          title: title,
          cost: total_cost,
          video_count: real_media.select { |f| f.end_with?(".mp4") }.count,
          image_count: real_media.select { |f| f.end_with?(".png") }.count,
          audio_count: real_media.select { |f| f.end_with?(".wav", ".mp3") }.count,
          text_count: Dir.glob(File.join(path, "**", "*.{txt,md}")).count
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

        display_title = (d[:title].length > 40) ? "#{d[:title][0...37]}..." : d[:title].ljust(40)
        puts "#{folder_emoji} #{Rainbow(d[:path].ljust(max_path + 1)).send(folder_color)} #{status_emoji(d[:status])} #{Rainbow(display_title).yellow} 💸 $#{"%.2f" % d[:cost]} #{stats_str}"
      end
    end

    desc "cleanup", "Archive projects without any REAL media to out/archived/"
    def cleanup
      puts Rainbow("🧹 Starting aggressive deterministic cleanup...").cyan
      projects = Dir.glob("out/*/").reject { |f| f.include?("archived") }
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
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        "out"
      end
      search_path = folder_path ? File.join(folder_path, "**", "*.{mp4,png,wav}") : "out/**/*.{mp4,png,wav}"
      puts Rainbow("🛡️  Rigorously checking media artifacts in #{search_path}...").cyan.bold

      files = Dir.glob(search_path).reject do |f|
        f.include?(".mock") || f.include?(".NOT_GOOD") || f.include?("archived/")
      end

      if files.empty?
        puts "No media files found to check."
        return
      end

      found_fakes = 0
      files.each do |file|
        type = case File.extname(file).downcase
        when ".mp4" then :video
        when ".png" then :image
        when ".wav" then :audio
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
      project = Arneis.load_project(yaml_path)

      tasks = []
      core_task_ids = []

      # Handle both VideoProject (scenes) and KidsStory (pages)
      items = project.respond_to?(:scenes) ? project.scenes : project.pages
      label_prefix = project.respond_to?(:scenes) ? "scene_" : "page_"

      items.each do |item|
        num = item["scene"] || item["page"]
        item_id = :"#{label_prefix}#{num}"
        tasks << Arneis::Task.new(item_id)
        core_task_ids << item_id
      end

      if project.data["background_music"]
        tasks << Arneis::Task.new(:background_music)
        core_task_ids << :background_music
      end

      # Add assembly tasks based on kind
      if project.is_a?(Arneis::VideoProject)
        tasks << Arneis::Task.new(:montage, dependencies: core_task_ids)
        tasks << Arneis::Task.new(:marketing, dependencies: [:montage])
      elsif project.is_a?(Arneis::KidsStory)
        tasks << Arneis::Task.new(:final_story_assembly, dependencies: core_task_ids)
      end

      visualizer = Visualizer.new(tasks)
      mermaid = visualizer.to_mermaid

      # Determine output folder
      output_dir = options[:media_folder] || options[:output] || Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) } || "out/latest_graph"
      FileUtils.mkdir_p(output_dir) if output_dir.start_with?("out/")

      output_file = options[:output] || File.join(output_dir, "DEPENDENCIES.md")
      title = project.respond_to?(:project_title) ? project.project_title : project.story_title
      content = "# Dependency Graph: #{title}\n\n```mermaid\n#{mermaid}\n```"

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
      File.read("data/templates/VideoProject.yaml")
      gemini = Generator::Gemini.new
      system_prompt = "You are an expert Copywriter. Create a VideoProject YAML based on the research. Follow the schema. Output ONLY the YAML."
      resp = gemini.generate(research_content, system_instruction: system_prompt)
      yaml_content = resp[:content].gsub(/```yaml\n|```/, "")
      output_dir = "data/samples/VideoProject"
      FileUtils.mkdir_p(output_dir)
      output_file = File.join(output_dir, "#{File.basename(research_path, ".*")}.yaml")
      File.write(output_file, yaml_content)
      puts Rainbow("✅ Pitch generated and saved to #{output_file}").green
    end

    no_commands do
      def resolve_media_folder(args = [], options = {})
        # Precedence:
        # 1. Command-line flag (-f / --media-folder)
        # 2. Positional argument
        # 3. Environment variable (ARNEIS_FOLDER)

        folder = options["media_folder"] || args.first || ENV["ARNEIS_FOLDER"]

        if folder.nil? || folder.empty?
          raise "No media folder specified. Use -f, a positional argument, or set ARNEIS_FOLDER ENV."
        end

        folder
      end

      def status_emoji(status)
        case status
        when "verified" then "⚖️ "
        when "done" then "🟢"
        when "done_with_warnings" then "😟"
        when "polling" then "🔵"
        when "in_progress" then "🟡"
        when "pending" then "⚪"
        when "waiting" then "🩶"
        when "failed" then "🔴"
        when "initialized" then "🚀"
        else "❓"
        end
      end
    end

    def self.exit_on_failure?
      true
    end
  end
end
