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
    method_option :verify, type: :boolean, desc: "Enable multimodal E2E verification of generated artifacts"
    method_option :open, type: :boolean, desc: "Open the primary artifact after generation"
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
      project.initialize_output(output_path)
      puts Rainbow("🚀 Project initialized at #{output_path}").blue

      puts Rainbow("⚙️ Starting orchestration...").magenta
      verify_flag = Arneis::Config.eval_enabled?(eval: options[:verify])
      project.process(async: options[:async], verify: verify_flag, dryrun: options[:dryrun])
      puts Rainbow("✅ Generation complete!").green

      open_flag = Arneis::Config.open_enabled?(open: options[:open])
      if open_flag && !options[:dryrun] && project.media?
        Arneis::MediaOpener.open(project.primary_artifact)
      end
    end

    desc "generate KIND", "Generate a media project on the fly"
    method_option :characters, type: :string, aliases: "-c", desc: "Comma-separated character IDs"
    method_option :prompt, type: :string, aliases: "-p", desc: "Prompt for the generation"
    method_option :aspect_ratio, type: :string, default: "1:1", desc: "Aspect ratio (1:1, 16:9, etc.)"
    method_option :title, type: :string, desc: "Project title"
    method_option :dryrun, type: :boolean, aliases: "-n", desc: "Validate without executing"
    method_option :verify, type: :boolean, desc: "Enable verification"
    method_option :open, type: :boolean, desc: "Open the primary artifact after generation"
    def generate(kind)
      puts Rainbow("🚀 Generating #{kind} ad-hoc...").green

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
      elsif target_id.start_with?("page_")
        num = target_id.split("_").last
        to_trash << File.join(folder_path, "pages", "page_#{num}", "illustration.png")
      end

      to_trash.each do |path|
        if File.exist?(path)
          puts "  🗑️  Archiving #{File.basename(path)} to .trash/..."
          FileUtils.mv(path, File.join(trash_dir, File.basename(path)))
          # Also archive receipt
          receipt = "#{path}.receipt.json"
          FileUtils.mv(receipt, File.join(trash_dir, File.basename(receipt))) if File.exist?(receipt)
          # Also archive asset json
          asset_json = "#{path}.asset.json"
          FileUtils.mv(asset_json, File.join(trash_dir, File.basename(asset_json))) if File.exist?(asset_json)
        end
      end

      # 3. Update State
      if target_id == "background_music"
        state["background_music"]["status"] = "pending"
        state["background_music"]["feedback"] = options[:prompt]
      else
        item = items.find { |i| target_id == (state["scenes"] ? "scene_#{i["scene"]}" : "page_#{i["page"]}") }
        item["status"] = "pending"
        item["feedback"] = options[:prompt]
      end

      state["status"] = "in_progress"
      File.write(state_file, state.to_yaml)

      puts Rainbow("✅ State updated. Run 'arnectl apply' or 'arnectl resume' to regenerate with feedback.").green
    end

    desc "status [FOLDER_PATH]", "Show status of a media project"
    def status(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found.").red
        return
      end

      state_file = File.join(folder_path, ".state.yaml")
      state = YAML.load_file(state_file)

      puts Rainbow("📊 Project Status: #{state["project_title"]}").bold.cyan
      puts "📁 Folder: #{folder_path}"
      puts "🕒 Status: #{status_emoji(state["status"])} #{state["status"].capitalize}"
      puts ""

      items = state["scenes"] || state["pages"] || []
      items.each do |item|
        id = state["scenes"] ? "Scene #{item["scene"]}" : "Page #{item["page"]}"
        puts "  #{status_emoji(item["status"])} #{id.ljust(8)}: #{item["status"].ljust(15)} | #{item["description"]}"
        if item["error"]
          puts Rainbow("    ❌ Error: #{item["error"]}").red
        end
      end

      if state["background_music"]
        bm = state["background_music"]
        puts "  #{status_emoji(bm["status"])} Music   : #{bm["status"].ljust(15)} | #{bm["prompt"]}"
      end

      if state["montage"]
        m = state["montage"]
        puts "  #{status_emoji(m["status"])} Montage : #{m["status"].ljust(15)}"
      end

      has_low_scores = items.any? do |item|
        num = state["scenes"] ? item["scene"] : item["page"]
        prefix = state["scenes"] ? "video/scene_#{num}/video.mp4" : "pages/page_#{num}/illustration.png"
        asset_json = File.join(folder_path, "#{prefix}.asset.json")

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
        puts "💡 Hint: Use 'arnectl redo --threshold 6' to reset tasks with low evaluation scores."
      else
        puts "💡 Hint: Use 'arnectl redo' to reset tasks with low evaluation scores."
      end
    end

    desc "resume [FOLDER_PATH]", "Resume an interrupted project"
    def resume(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found to resume.").red
        return
      end

      yaml_file = Dir.glob(File.join(folder_path, "*.yaml")).reject { |f| f.end_with?(".state.yaml") }.first
      if yaml_file.nil?
        puts Rainbow("❌ No YAML found in #{folder_path} to resume from").red
        return
      end

      puts Rainbow("🚀 Resuming #{folder_path}...").green
      apply(yaml_file)
    end

    desc "redo [FOLDER_PATH]", "Reset and retry tasks with low evaluation scores"
    method_option :threshold, type: :numeric, default: 6, desc: "Score threshold (default 6)"
    def redo(folder_path = nil)
      folder_path = begin
        resolve_media_folder([folder_path], options)
      rescue
        nil
      end
      folder_path ||= Dir.glob("out/*/").select { |f| File.exist?(File.join(f, ".state.yaml")) }.max_by { |f| File.mtime(f) }

      if folder_path.nil?
        puts Rainbow("❌ No project folders found to redo.").red
        return
      end

      state_file = File.join(folder_path, ".state.yaml")
      state = YAML.load_file(state_file)
      items = state["scenes"] || state["pages"] || []
      reset_count = 0

      puts Rainbow("🔄 Redoing tasks in #{folder_path} with score <= #{options[:threshold]}...").cyan

      items.each do |item|
        num = state["scenes"] ? item["scene"] : item["page"]
        prefix = state["scenes"] ? "video/scene_#{num}/video.mp4" : "pages/page_#{num}/illustration.png"
        artifact_file = File.join(folder_path, prefix)
        asset_json = "#{artifact_file}.asset.json"

        if File.exist?(asset_json)
          asset_data = JSON.parse(File.read(asset_json))
          # Check character eval score if it exists
          char_evals = asset_data.keys.select { |k| k.start_with?("eval_") }
          min_score = char_evals.map { |k| asset_data[k]["score"] }.min || 10
          
          if min_score <= options[:threshold]
            puts Rainbow("  🎯 Resetting #{state["scenes"] ? "Scene" : "Page"} #{num} (Score: #{min_score})").yellow
            
            # Move to trash
            trash_dir = File.join(folder_path, ".trash", Time.now.strftime("%Y%m%d_%H%M%S"))
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
        resume(folder_path)
      else
        puts Rainbow("🙌 No tasks found below the threshold. Everything looks good!").green
      end
    end

    no_commands do
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
