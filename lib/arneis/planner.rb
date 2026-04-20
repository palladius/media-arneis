=begin
Arneis::Planner - Manages versioned Markdown plans (__revN.md).
Handles revision extraction, comparison, and invalidation.
=end

require 'yaml'

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
  end
end
