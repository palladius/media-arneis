=begin
Arneis::Visualizer - Generates visual representations of the dependency graph.
Currently supports Mermaid.js syntax.
=end

module Arneis
  class Visualizer
    def initialize(tasks)
      @tasks = tasks
    end

    def to_mermaid
      lines = ["graph LR"]
      lines << "  classDef scene fill:#f9f,stroke:#333,stroke-width:2px;"
      @tasks.each do |task|
        task_label = task.id.to_s
        lines << "  #{task.id}[\"#{task_label}\"]:::scene"
        task.dependencies.each do |dep|
          lines << "  #{dep} --> #{task.id}"
        end
      end
      lines.join("\n")
    end
  end
end
