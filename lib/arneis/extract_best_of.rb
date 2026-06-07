# frozen_string_literal: true

require "fileutils"

module Arneis
  class ExtractBestOf
    IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .webp .gif].freeze
    
    attr_reader :source_dir, :targets, :dry_run, :verbose

    def initialize(source_dir: "out", targets: [], dry_run: false, verbose: false)
      @source_dir = source_dir
      @targets = targets.map { |t| File.expand_path(t) }
      @dry_run = dry_run
      @verbose = verbose
    end

    def run
      unless Dir.exist?(source_dir)
        return { success: false, error: "Source directory '#{source_dir}' does not exist." }
      end

      # Find matching files
      matching_files = find_files

      stats = {
        found: matching_files.size,
        copied: 0,
        skipped: 0,
        overwritten: 0,
        errors: 0
      }

      matching_files.each do |src_path|
        # Deterministic safe name
        relative_path = src_path.sub(/^#{Regexp.escape(source_dir)}\//, "")
        safe_name = relative_path.gsub(/[\/\\]/, "_")
        subfolder = subfolder_for(src_path)

        targets.each do |target_dir|
          dest_dir = subfolder ? File.join(target_dir, subfolder) : target_dir
          dest_path = File.join(dest_dir, safe_name)

          if File.exist?(dest_path)
            if File.size(dest_path) == File.size(src_path)
              stats[:skipped] += 1
              next
            else
              stats[:overwritten] += 1
            end
          else
            stats[:copied] += 1
          end

          next if dry_run

          begin
            FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
            FileUtils.cp(src_path, dest_path)
          rescue => e
            stats[:errors] += 1
            warn "Error copying #{src_path} to #{dest_path}: #{e.message}" if verbose
          end
        end
      end

      { success: true, stats: stats }
    end

    def subfolder_for(path)
      path_lower = path.downcase
      category = if path_lower.include?("rubycon") || path_lower.include?("yukihiro")
        "rubycon"
      elsif %w[alessandro sebastian riccardo ale seby kids family].any? { |kw| path_lower.include?(kw) }
        "family"
      else
        "misc"
      end

      # Determine template kind from the run directory's spec YAML
      parts = path.split('/')
      run_dir_name = parts[1]
      template = nil

      if run_dir_name && run_dir_name != "best-of"
        run_dir_path = File.join(source_dir, run_dir_name)
        if Dir.exist?(run_dir_path)
          yaml_files = Dir.glob(File.join(run_dir_path, "*.yaml")).reject { |f| File.basename(f) == ".state.yaml" }
          if yaml_files.any?
            begin
              data = YAML.load_file(yaml_files.first)
              template = data["kind"] if data.is_a?(Hash)
            rescue
              # Ignore parsing errors
            end
          end
        end
      end

      if template
        File.join(category, template)
      else
        category
      end
    end



    def find_files
      all_files = Dir.glob(File.join(source_dir, "**/*"))
      
      all_files.select do |path|
        next false unless File.file?(path)

        # Check extension
        ext = File.extname(path).downcase
        next false unless IMAGE_EXTENSIONS.include?(ext)

        # Exclude target directories to prevent infinite loops / double copies
        abs_path = File.expand_path(path)
        next false if targets.any? { |td| abs_path.start_with?(td) }

        # Also explicitly exclude default best-of path in case it is relative or resolved differently
        next false if path.start_with?("#{source_dir}/best-of/") || path.include?("/best-of/")

        # Exclude hidden directories (like .trash)
        parts = path.split('/')
        next false if parts.any? { |part| part.start_with?('.') && part != '.' && part != '..' }

        true
      end
    end
  end
end
