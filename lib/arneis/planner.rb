# Arneis::Planner - Manages versioned Markdown plans (__revN.md).
# Handles revision extraction, comparison, and invalidation.

require "yaml"

module Arneis
  class Planner
    attr_reader :project_path

    def initialize(project_path)
      @project_path = project_path
    end

    # Returns all plan files matching the __revN.md pattern
    def all_plans
      Dir.glob(File.join(@project_path, "*__rev*.md")).sort_by do |f|
        extract_revision(f)
      end
    end

    # Returns the plan with the highest revision number
    def latest_plan
      all_plans.last
    end

    # Extracts the revision number from the filename or frontmatter
    # Filename pattern: anything__rev(\d+).md
    def extract_revision(file_path)
      # Priority 1: Filename
      if File.basename(file_path) =~ /__rev(\d+)\.md$/
        return $1.to_i
      end

      # Priority 2: Frontmatter (if exists)
      begin
        content = File.read(file_path)
        if content =~ /^rev:\s*(\d+)$/
          return $1.to_i
        end
      rescue
      end

      0
    end

    # Validates that a plan has the correct internal revision marker
    def valid_plan?(file_path)
      rev_from_name = extract_revision(file_path)
      content = File.read(file_path)
      # Check for rev: N inside the file
      content.include?("rev: #{rev_from_name}")
    end

    # Compares two plans (as hashes) and returns changes
    def diff_scenes(old_plan, new_plan)
      old_scenes = old_plan.dig("spec", "scenes") || []
      new_scenes = new_plan.dig("spec", "scenes") || []

      diff = {added: [], modified: [], removed: []}

      old_map = old_scenes.each_with_object({}) { |s, m| m[s["scene"]] = s }
      new_map = new_scenes.each_with_object({}) { |s, m| m[s["scene"]] = s }

      new_map.each do |id, scene|
        if old_map.key?(id)
          diff[:modified] << id if scene["description"] != old_map[id]["description"]
        else
          diff[:added] << id
        end
      end

      old_map.each_key do |id|
        diff[:removed] << id unless new_map.key?(id)
      end

      diff
    end
  end
end
