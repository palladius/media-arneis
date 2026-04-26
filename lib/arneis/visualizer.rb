# Arneis::Visualizer - Generates visual representations of the dependency graph.
# Currently supports Mermaid.js syntax.

module Arneis
  class Visualizer
    def initialize(tasks)
      @tasks = tasks
    end

    def to_mermaid
      lines = ["graph LR"]
      lines << "  classDef scene fill:#f9f,stroke:#333,stroke-width:2px;"
      lines << "  classDef project fill:#ccf,stroke:#333,stroke-width:2px;"

      @tasks.each do |task|
        id_str = task.id.to_s
        emoji = if id_str.include?("scene")
          "🎥 "
        elsif id_str.include?("music")
          "🎵 "
        elsif id_str.include?("montage")
          "🎞️ "
        else
          "📝 "
        end

        task_label = "#{emoji}#{id_str}"
        style = id_str.include?("scene") ? ":::scene" : ":::project"
        lines << "  #{task.id}[\"#{task_label}\"]#{style}"

        task.dependencies.each do |dep|
          lines << "  #{dep} --> #{task.id}"
        end
      end
      lines.join("\n")
    end
  end
end
