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
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/extract-bestof.rb [options]"

  opts.on("-o", "--output DIR", "Specify destination directory (can be specified multiple times)") do |o|
    options[:outputs] << o
  end

  opts.on("-d", "--desktop", "Also copy to ~/Desktop/media-arneis/best-of/pics/") do
    options[:desktop] = true
  end

  opts.on("-n", "--dry-run", "Show what would be copied without copying") do
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
  options[:outputs] << "out/best-of/pics"
end

if options[:desktop]
  desktop_dir = File.expand_path("~/Desktop/media-arneis/best-of/pics")
  options[:outputs] << desktop_dir
end

puts Rainbow("🔍 Scraping out/ folders for images...").cyan
puts "Targets: #{options[:outputs].join(', ')}"
puts "Dry-run: #{options[:dry_run] ? 'ENABLED' : 'DISABLED'}"

extractor = Arneis::ExtractBestOf.new(
  source_dir: "out",
  targets: options[:outputs],
  dry_run: options[:dry_run],
  verbose: options[:verbose]
)

result = extractor.run

if result[:success]
  stats = result[:stats]
  action_word = options[:dry_run] ? "Would copy" : "Processed"
  
  puts Rainbow("\n✨ Done!").green
  puts "  - Total source images found: #{stats[:found]}"
  puts "  - #{action_word} new files: #{stats[:copied]}"
  puts "  - Files skipped (identical): #{stats[:skipped]}"
  puts "  - Files overwritten (changed size): #{stats[:overwritten]}"
  
  dest_desc = options[:dry_run] ? "Files would be saved to" : "Files saved to"
  puts "  - #{dest_desc}: #{options[:outputs].join(', ')}"
  
  if stats[:errors] > 0
    puts Rainbow("  - Errors encountered: #{stats[:errors]}").red
  end
else
  puts Rainbow("❌ Extraction failed: #{result[:error]}").red
  exit 1
end
