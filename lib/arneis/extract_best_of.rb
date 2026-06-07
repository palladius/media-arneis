# frozen_string_literal: true

require "time"

module Arneis
  class ExtractBestOf
    IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .webp .gif].freeze
    VIDEO_EXTENSIONS = %w[.mp4 .mov .avi .mkv .webm].freeze
    
    attr_reader :source_dir, :targets, :dry_run, :verbose, :clean, :rotate_days, :auto_approve

    def initialize(source_dir: "out", targets: [], dry_run: false, verbose: false, clean: false, rotate_days: 7, auto_approve: false)
      @source_dir = source_dir
      @targets = targets.map { |t| File.expand_path(t) }
      @dry_run = dry_run
      @verbose = verbose
      @clean = clean
      @rotate_days = rotate_days
      @auto_approve = auto_approve
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
        
        # Determine asset type subdirectory (pics or videos)
        ext = File.extname(src_path).downcase
        type_sub = IMAGE_EXTENSIONS.include?(ext) ? "pics" : "videos"
        
        # Determine category subfolder (rubycon, family, or nil)
        cat_sub = subfolder_for(src_path)

        targets.each do |target_base|
          # Build target directory structure: [target_base]/[pics|videos]/[rubycon|family]?
          dest_dir = File.join(target_base, type_sub)
          dest_dir = File.join(dest_dir, cat_sub) if cat_sub
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

      deleted_folders = []
      if clean
        rotation_res = rotate_old_folders
        deleted_folders = rotation_res[:deleted] || []
      end

      { success: true, stats: stats, deleted: deleted_folders }
    end

    def rotate_old_folders
      folders_to_delete = find_old_folders
      return { success: true, deleted: [] } if folders_to_delete.empty?

      if dry_run
        return { success: true, deleted: folders_to_delete, dry_run: true }
      end

      # Prompt if not auto-approved
      unless auto_approve
        puts "\n" + Rainbow("⚠️  The following #{folders_to_delete.size} folder(s) in '#{source_dir}' are older than #{rotate_days} days and will be moved to the trash:").yellow
        folders_to_delete.each { |dir| puts "  - #{dir}" }
        print "Are you sure you want to move them to trash? [y/N]: "
        response = begin
          if ENV["RSPEC_RUNNING"] == "true"
            "y" # Auto-approve in tests to prevent blocking
          else
            $stdin.gets&.strip
          end
        rescue
          nil
        end
        unless %w[y yes].include?(response&.downcase)
          puts Rainbow("❌ Operation cancelled by user.").red
          return { success: false, deleted: [], error: "Cancelled by user" }
        end
      end

      # Create timestamped trash directory under [source_dir]/.trash/
      trash_base = File.join(source_dir, ".trash")
      trash_dir = File.join(trash_base, Time.now.strftime("%Y%m%d_%H%M%S"))

      # Perform trashing (moving folders)
      deleted_folders = []
      folders_to_delete.each do |dir_path|
        begin
          if verbose
            puts "  🗑️  Trashing #{dir_path} -> #{trash_dir}/"
          end
          FileUtils.mkdir_p(trash_dir) unless Dir.exist?(trash_dir)
          FileUtils.mv(dir_path, File.join(trash_dir, File.basename(dir_path)))
          deleted_folders << dir_path
        rescue => e
          warn "Error trashing #{dir_path}: #{e.message}" if verbose
        end
      end

      { success: true, deleted: deleted_folders }
    end

    def find_old_folders
      return [] unless Dir.exist?(source_dir)

      # Glob first-level directories under source_dir
      subdirs = Dir.glob(File.join(source_dir, "*/")).map { |d| File.expand_path(d) }

      subdirs.select do |dir_path|
        dir_name = File.basename(dir_path)

        # Exclude best-of
        next false if dir_name == "best-of"
        # Exclude targets
        next false if targets.any? { |t| dir_path.start_with?(t) }
        # Exclude hidden directories
        next false if dir_name.start_with?(".")

        # Check age
        age = get_folder_age(dir_path)
        age && age > rotate_days
      end
    end

    def get_folder_age(dir_path)
      folder_name = File.basename(dir_path)
      age = folder_age_in_days(folder_name)
      return age if age

      # Fallback to mtime of .state.yaml or folder
      state_file = File.join(dir_path, ".state.yaml")
      mtime = File.exist?(state_file) ? File.mtime(state_file) : File.mtime(dir_path)
      (Time.now - mtime) / (24 * 3600.0)
    end

    def folder_age_in_days(folder_name)
      if folder_name =~ /^(\d{8})_(\d{6})/
        date_str = $1
        time_str = $2
        begin
          folder_time = Time.strptime("#{date_str}_#{time_str}", "%Y%m%d_%H%M%S")
          (Time.now - folder_time) / (24 * 3600.0)
        rescue
          nil
        end
      else
        nil
      end
    end

    def subfolder_for(path)
      path_lower = path.downcase
      if %w[rubycon yukihiro antigravity openclaw hermes].any? { |kw| path_lower.include?(kw) }
        "rubycon"
      elsif %w[alessandro sebastian riccardo ale seby kids family].any? { |kw| path_lower.include?(kw) }
        "family"
      else
        nil
      end
    end

    def find_files
      all_files = Dir.glob(File.join(source_dir, "**/*"))
      allowed_extensions = IMAGE_EXTENSIONS + VIDEO_EXTENSIONS
      
      all_files.select do |path|
        next false unless File.file?(path)

        # Check extension
        ext = File.extname(path).downcase
        next false unless allowed_extensions.include?(ext)

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
