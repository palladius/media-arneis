#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'optparse'
require 'rainbow'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'arneis'

# Parse options
options = {
  outputs: [],
  desktop: false,
  dry_run: false,
  verbose: false,
  clean: false,
  rotate_days: 7,
  auto_approve: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/extract-bestof.rb [options]"

  opts.on("-o", "--output DIR", "Specify destination directory (can be specified multiple times)") do |o|
    options[:outputs] << o
  end

  opts.on("-d", "--desktop", "Also copy to ~/Desktop/media-arneis/best-of/pics/") do
    options[:desktop] = true
  end

  opts.on("-c", "--clean", "Clean up (delete) old folders in out/ after extraction") do
    options[:clean] = true
  end

  opts.on("--rotate-days DAYS", Integer, "Threshold age in days for deleting old folders (default: 7)") do |days|
    options[:rotate_days] = days
  end

  opts.on("-y", "--yes", "Auto-approve deletion prompts (non-interactive)") do
    options[:auto_approve] = true
  end

  opts.on("-n", "--dry-run", "Show what would be copied and deleted without performing actions") do
    options[:dry_run] = true
  end

  opts.on("-v", "--verbose", "Print details for each file processed") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Add default output folder if none specified
if options[:outputs].empty?
  options[:outputs] << "out/best-of"
end

if options[:desktop]
  desktop_base = File.expand_path("~/Desktop/media-arneis/best-of")
  options[:outputs] << desktop_base
end

puts Rainbow("🔍 Scraping out/ folders for images and videos...").cyan
puts "Targets: #{options[:outputs].join(', ')}"
puts "Dry-run: #{options[:dry_run] ? 'ENABLED' : 'DISABLED'}"
if options[:clean]
  puts "Rotation: ENABLED (deleting folders older than #{options[:rotate_days]} days)"
end

extractor = Arneis::ExtractBestOf.new(
  source_dir: "out",
  targets: options[:outputs],
  dry_run: options[:dry_run],
  verbose: options[:verbose],
  clean: options[:clean],
  rotate_days: options[:rotate_days],
  auto_approve: options[:auto_approve]
)

result = extractor.run

if result[:success]
  stats = result[:stats]
  action_word = options[:dry_run] ? "Would copy" : "Processed"
  
  puts Rainbow("\n✨ Done!").green
  puts "  - Total source files found: #{stats[:found]}"
  puts "  - #{action_word} new files: #{stats[:copied]}"
  puts "  - Files skipped (identical): #{stats[:skipped]}"
  puts "  - Files overwritten (changed size): #{stats[:overwritten]}"
  
  dest_desc = options[:dry_run] ? "Files would be saved to" : "Files saved to"
  puts "  - #{dest_desc}: #{options[:outputs].join(', ')}"
  
  if options[:clean]
    del_desc = options[:dry_run] ? "Folders would be deleted" : "Folders deleted"
    deleted_names = (result[:deleted] || []).map { |d| File.basename(d) }
    puts "  - #{del_desc} (older than #{options[:rotate_days]} days): #{deleted_names.size} #{deleted_names.any? ? '(' + deleted_names.join(', ') + ')' : ''}"
  end

  if stats[:errors] > 0
    puts Rainbow("  - Errors encountered: #{stats[:errors]}").red
  end
else
  puts Rainbow("❌ Extraction failed: #{result[:error]}").red
  exit 1
end
