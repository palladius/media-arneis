=begin
Arneis::Cli - Implementation of the arnectl command-line interface.
=end

require 'thor'
require 'rainbow'
require 'yaml'

module Arneis
  class Cli < Thor
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

    desc "status FOLDER_PATH", "Show real-time status of a media project"
    def status(folder_path)
      puts Rainbow("🔍 Checking status of #{folder_path}...").yellow
      state_file = File.join(folder_path, '.state.yaml')
      unless File.exist?(state_file)
        puts Rainbow("❌ No state file found in #{folder_path}").red
        return
      end

      state = YAML.load_file(state_file)
      puts "Project: #{state['project_title']}"
      puts "Status: #{status_emoji(state['status'])} #{state['status']}"
      puts "\nScenes:"
      state['scenes'].each do |scene|
        puts "  #{status_emoji(scene['status'])} Scene #{scene['scene']}: #{scene['description']}"
      end
    end

    desc "stats FOLDER_PATH", "Show resource usage and cost for a media project"
    def stats(folder_path)
      puts Rainbow("📊 Calculating stats for #{folder_path}...").cyan
      # This will eventually pull from the state file and logs
      puts "Total Tokens: 0"
      puts "Estimated Cost: $0.00"
      puts "Time Elapsed: 0s"
    end

    desc "graph YAML_PATH", "Generate a Mermaid.js dependency graph for a project"
    method_option :output, type: :string, aliases: "-o", desc: "Output file (default: graph.md)"
    def graph(yaml_path)
      puts Rainbow("📊 Generating graph for #{yaml_path}...").cyan
      project = VideoProject.new(yaml_path)
      
      # We need a way to get the tasks from the project without running it
      # For now, let's just use a simplified version of what process does
      tasks = project.scenes.map do |scene|
        Arneis::Task.new("scene_#{scene['scene']}".to_sym)
      end
      
      # Add dependencies if they exist (need to update VideoProject or YAML to support them)
      # For now, let's assume sequential dependencies for the demo
      tasks.each_cons(2) do |prev, curr|
        curr.dependencies << prev.id
      end

      visualizer = Visualizer.new(tasks)
      mermaid = visualizer.to_mermaid
      
      output_file = options[:output] || "graph.md"
      content = "# Dependency Graph: #{project.title}\n\n```mermaid\n#{mermaid}\n```"
      File.write(output_file, content)
      
      puts Rainbow("✅ Graph generated and saved to #{output_file}").green
    end

    no_commands do
      def status_emoji(status)
        case status
        when 'done' then "🟢"
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
