=begin
Arneis::Validator - Verifies the integrity and type of generated media artifacts.
Uses the system 'file' command to check for expected media headers.
=end

require 'rainbow'

module Arneis
  class Validator
    VALID_TYPES = {
      video: [/ISO Media/, /MP4/, /MPEG/],
      audio: [/MPEG/, /Audio/, /WAV/],
      image: [/PNG/, /JPEG/],
      text: [/text/, /ASCII/],
      markdown: [/text/, /ASCII/, /Markdown/]
    }.freeze

    def self.verify(file_path, type)
      unless File.exist?(file_path)
        return { success: false, message: "File not found: #{file_path}" }
      end

      # Run system 'file' command
      file_info = `file "#{file_path}"`
      expected_patterns = VALID_TYPES[type]

      if expected_patterns.any? { |pattern| file_info =~ pattern }
        { success: true, info: file_info.strip, metadata: extract_metadata(file_path, file_info) }
      else
        { success: false, info: file_info.strip, message: "Type mismatch: expected #{type}, got #{file_info.strip}" }
      end
    end

    def self.validate_and_rename!(file_path, type)
      result = verify(file_path, type)
      unless result[:success]
        if File.exist?(file_path)
          new_path = "#{file_path}.NOT_GOOD"
          puts Rainbow("    🚫 ARTIFACT INVALID! Renaming to #{File.basename(new_path)}").red
          FileUtils.mv(file_path, new_path)
          result[:renamed_to] = new_path
        else
          puts Rainbow("    ❌ ARTIFACT MISSING! Expected: #{File.basename(file_path)}").red
        end
      end
      result
    end

    def self.extract_metadata(file_path, file_info)
      {
        size_bytes: File.size(file_path),
        file_info: file_info.strip,
        ts_verified: Time.now.iso8601
      }
    end
  end
end
