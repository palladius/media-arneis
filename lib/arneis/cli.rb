# Arneis::Cli - Implementation of the arnectl command-line interface.

require "thor"
require "rainbow"
require "yaml"
require "json"
require "fileutils"
require "time"
require "rbconfig"

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
    method_option :force_clean, type: :boolean, default: false, desc: "Force a clean run by deleting the output directory if it exists"
    method_option :verify, type: :boolean, default: false, desc: "Enable multimodal E2E verification of generated artifacts"
    method_option :open, type: :boolean, default: false, desc: "Open the primary artifact after generation"
    def apply(yaml_path)
      if %w[--help -h].include?(yaml_path)
        help("apply")
        return
      end
      puts Rainbow("🎨 Applying #{yaml_path}...").green
      
      Config.dryrun = options[:dryrun]
      output_path = options[:media_folder] || options[:output] || "out/#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{File.basename(yaml_path, ".*")}"
      if options[:force_clean] && Dir.exist?(output_path)
        puts Rainbow("  🔥 Deleting existing output directory due to --force flag: #{output_path}").yellow
        FileUtils.rm_rf(output_path)
      end
      
      project = Arneis.load_project(yaml_path)
      project.initialize_output(output_path)
      puts Rainbow("🚀 Project initialized at #{output_path}").blue

      puts Rainbow("⚙️ Starting orchestration...").magenta
      project.process(async: options[:async], verify: options[:verify], dryrun: options[:dryrun])
      puts Rainbow("✅ Generation complete!").green

      if options[:open] && !options[:dryrun]
        open_file(project.primary_artifact)
      end
    end

    desc "generate KIND", "Generate a media project on the fly"
    method_option :characters, type: :string, aliases: "-c", desc: "Comma-separated character IDs"
    method_option :prompt, type: :string, aliases: "-p", desc: "Prompt for the generation"
    method_option :aspect_ratio, type: :string, default: "1:1", desc: "Aspect ratio (1:1, 4:3, 3:4, 16:9, 9:16)"
    method_option :title, type: :string, desc: "Project title"
    method_option :dryrun, type: :boolean, aliases: "-n", desc: "Validate without executing"
    method_option :verify, type: :boolean, default: false, desc: "Enable verification"
    method_option :open, type: :boolean, default: false, desc: "Open the primary artifact after generation"
    method_option :retry, type: :string, desc: "Retry a previous run with evaluation feedback"
    method_option :topic, type: :string, aliases: "-t", desc: "Topic for PowerColon ideation"
    method_option :slides, type: :numeric, default: 5, desc: "Number of slides for PowerColon"
    method_option :fun, type: :boolean, default: false, desc: "Make PowerColon presentation fun"
    def generate(kind)
      puts Rainbow("🚀 Generating #{kind} ad-hoc...").green

      if kind == "PowerColon" && options[:topic]
        # 1. Ideation / Drafting Phase
        topic = options[:topic]
        num_slides = options[:slides] || 5
        is_fun = options[:fun]
        
        puts Rainbow("🧠 [GEMINI] Ideating slide deck on: '#{topic}' (#{num_slides} slides, fun: #{is_fun})...").magenta
        
        gemini = Generator::Gemini.new
        prompt = <<-PROMPT
        You are an expert presentation designer. Create a slide deck outline on the topic: "#{topic}" with exactly #{num_slides} slides.
        The tone should be #{is_fun ? "fun, humorous, and engaging" : "professional and informative"}.
        
        For each slide, specify:
        1. Title
        2. Style (must be one of: 'title_slide', 'chapter', 'default', 'left_image')
        3. Markdown content (bullet points, etc.)
        4. Optional image details (prompt, aspect_ratio e.g. 3:4 if style is left_image)

        Output the response strictly as a JSON object of this structure (raw JSON text, NO markdown formatting block around it):
        {
          "presentation_title": "Openclaw vs Hermes",
          "slides": [
            {
              "style": "title_slide",
              "title": "Openclaw vs Hermes",
              "content": "An architectural showdown"
            },
            {
              "style": "left_image",
              "title": "Architecture Comparison",
              "content": "- Openclaw is agentic\\n- Hermes is message-driven",
              "image": {
                "prompt": "A mechanical lobster next to a messenger god",
                "aspect_ratio": "3:4"
              }
            }
          ]
        }
        PROMPT
        
        resp = gemini.generate(prompt)
        # Parse JSON
        clean_content = resp[:content].gsub(/```json/, "").gsub(/```/, "").strip
        begin
          idea = JSON.parse(clean_content)
        rescue => e
          puts Rainbow("❌ Failed to parse Gemini ideation response: #{e.message}").red
          puts clean_content
          return
        end

        # Create topic slug
        topic_slug = topic.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/(^_+|_+$)/, "")
        slides_dir = "data/presentations/slides/#{topic_slug}"
        FileUtils.mkdir_p(slides_dir)
        
        yaml_slides = []
        idea["slides"].each_with_index do |slide, idx|
          slide_file_name = "slide_#{sprintf('%02d', idx + 1)}.md"
          slide_file_path = File.join(slides_dir, slide_file_name)
          
          # Write slide markdown
          markdown = "# #{slide['title']}\n#{slide['content']}"
          File.write(slide_file_path, markdown)
          
          slide_entry = {
            "file" => slide_file_path,
            "style" => slide["style"]
          }
          if slide["image"]
            slide_entry["image"] = {
              "filename" => "slide_#{sprintf('%02d', idx + 1)}_illustration.png",
              "aspect_ratio" => slide["image"]["aspect_ratio"] || "3:4",
              "prompt" => slide["image"]["prompt"]
            }
          end
          yaml_slides << slide_entry
        end

        yaml_data = {
          "apiVersion" => "media-arneis.palladius.it/v1",
          "kind" => "PowerColon",
          "metadata" => {
            "name" => topic_slug,
            "template" => "PowerColon"
          },
          "spec" => {
            "presentation_title" => idea["presentation_title"] || topic,
            "slides" => yaml_slides
          }
        }
        
        yaml_path = "data/presentations/#{topic_slug}.yaml"
        FileUtils.mkdir_p("data/presentations")
        File.write(yaml_path, yaml_data.to_yaml)
        
        puts Rainbow("✨ Ideated slides drafted!").green
        puts "  - YAML config: #{yaml_path}"
        puts "  - Slide files in: #{slides_dir}/"
        puts "\nPress enter to compile this presentation (or Ctrl+C to cancel and edit draft first):"
        
        # In test / non-interactive mode, we proceed automatically
        unless ENV["RSPEC_RUNNING"]
          $stdin.gets
        end
        
        apply(yaml_path)
        return
      end

      # Create a temporary YAML to reuse existing hydration/validation logic
      temp_yaml = "tmp_adhoc_#{Time.now.to_i}.yaml"
      data = {
        "apiVersion" => "media-arneis.palladius.it/v1",
        "kind" => kind,
        "metadata" => { "name" => "adhoc-gen", "template" => kind },
        "spec" => {
          "project_title" => options[:title] || "Ad-hoc #{kind}",
          "characters" => (options[:characters] || "").split(","),
          "prompt" => options[:prompt],
          "aspect_ratio" => options[:aspect_ratio]
        }
      }
      File.write(temp_yaml, data.to_yaml)

      begin
        apply(temp_yaml)
      ensure
        FileUtils.rm(temp_yaml) if File.exist?(temp_yaml)
      end
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

      items = state["scenes"] || state["pages"] || []
      has_low_scores = items.any? do |item|
        num = item["scene"] || item["page"]
        item_dir = state["scenes"] ? "video/scene_#{num}" : "pages/page_#{num}"
        artifact_name = state["scenes"] ? "video.mp4" : "illustration.png"
        asset_json = File.join(folder_path, item_dir, "#{artifact_name}.asset.json")

        if File.exist?(asset_json)
          asset_data = JSON.parse(File.read(asset_json))
          char_evals = asset_data.keys.select { |k| k.start_with?("eval_") }
          min_score = char_evals.map { |k| asset_data.dig(k, "score") }.compact.min
          min_score && min_score <= 6
        else
          false
        end
      end

      puts ""
      if has_low_scores
        puts "💡 Hint: Use 'arnectl redo #{folder_path} --threshold 6' to reset tasks with low evaluation scores."
      else
        puts "💡 Hint: Use 'arnectl redo' to reset tasks with low evaluation scores."
      end
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

        # Handle VideoProject (scenes), KidsStory (pages), and PowerColon (slides)
        items = state["scenes"] || state["pages"] || state["slides"] || []

        items.each_with_index do |item, idx|
          if state["slides"]
            has_image = item["style"] == "left_image" || item["image"]
            if has_image
              target_filename = item.dig("image", "filename") || "slide_#{sprintf('%02d', idx + 1)}_illustration.png"
              artifact_file = File.join(folder_path, "assets", target_filename)
              if %w[failed done_with_warnings in_progress].include?(item["status"]) || !File.exist?(artifact_file) || File.exist?("#{artifact_file}.mock")
                item["status"] = "pending"
              end
            else
              if %w[failed done_with_warnings in_progress].include?(item["status"])
                item["status"] = "pending"
              end
            end
          else
            num = item["scene"] || item["page"]
            item_dir = state["scenes"] ? "" : "pages/page_#{num}/"
            artifact_name = state["scenes"] ? "scene_#{num}.mp4" : "illustration.png"
            artifact_file = File.join(folder_path, item_dir, artifact_name)

            if %w[failed done_with_warnings in_progress].include?(item["status"]) || !File.exist?(artifact_file) || File.exist?("#{artifact_file}.mock")
              item["status"] = "pending"
            end
          end
        end
        if state["background_music"]
          music_file = File.join(folder_path, "audio", "background_music.wav")
          if %w[failed in_progress].include?(state["background_music"]["status"]) || !File.exist?(music_file) || File.exist?("#{music_file}.mock")
            state["background_music"]["status"] = "pending"
          end
        end
        # Also reset project-level tasks
        state.each do |key, value|
          next if %w[pages scenes slides status project_title story_title presentation_title character_id story_audio metadata].include?(key)
          next unless value.is_a?(Hash) && value["status"]
          if %w[failed in_progress].include?(value["status"])
            value["status"] = "pending"
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

    desc "redo [FOLDER_PATH]", "Automatically reset and retry tasks with scores below the threshold"
    method_option :threshold, type: :numeric, default: 6, desc: "Score threshold (1-10) below which a task is redone"
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

      puts Rainbow("🔄 Redoing tasks in #{folder_path} with score <= #{options[:threshold]}...").cyan

      state_file = File.join(folder_path, ".state.yaml")
      state = YAML.load_file(state_file)
      items = state["scenes"] || state["pages"] || []
      
      reset_count = 0

      items.each do |item|
        num = item["scene"] || item["page"]
        item_dir = state["scenes"] ? "video/scene_#{num}" : "pages/page_#{num}"
        artifact_name = state["scenes"] ? "video.mp4" : "illustration.png"
        artifact_file = File.join(folder_path, item_dir, artifact_name)
        asset_json = "#{artifact_file}.asset.json"

        if File.exist?(asset_json)
          asset_data = ::JSON.parse(File.read(asset_json))
          char_evals = asset_data.keys.select { |k| k.start_with?("eval_") }
          score = char_evals.map { |k| asset_data.dig(k, "score") }.compact.min || 10
          if score <= options[:threshold]
            puts Rainbow("  🎯 Resetting Task #{num} (Score: #{score})").yellow
            
            trash_dir = File.join(folder_path, ".trash", "redo_#{Time.now.strftime("%Y%m%d_%H%M%S")}")
            FileUtils.mkdir_p(trash_dir)
            
            [artifact_file, asset_json, "#{artifact_file}.mock"].each do |f|
              if File.exist?(f)
                FileUtils.mv(f, File.join(trash_dir, File.basename(f)))
              end
            end

            item["status"] = "pending"
            reset_count += 1
          end
        end
      end

      if reset_count > 0
        state["status"] = "in_progress"
        File.write(state_file, state.to_yaml)
        puts Rainbow("✅ #{reset_count} tasks reset. Resuming...").green
        invoke :resume, [folder_path]
      else
        puts Rainbow("🙌 No tasks found below the threshold. Everything looks good!").green
      end
    end

    no_commands do
      def open_file(path)
        return unless File.exist?(path)
        puts Rainbow("📂 Opening #{path}...").cyan
        case RbConfig::CONFIG["host_os"]
        when /mswin|mingw|cygwin/
          system "start #{path}"
        when /darwin/
          system "open #{path}"
        when /linux|bsd/
          system "xdg-open #{path}"
        end
      end

      def resolve_media_folder(args = [], options = {})
        folder = options["media_folder"] || args.first || ENV["ARNEIS_FOLDER"]
        raise "No media folder specified." if folder.nil? || folder.empty?
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
