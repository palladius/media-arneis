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
      image: [/PNG/, /JPEG/]
    }.freeze

    def self.verify(file_path, type)
      unless File.exist?(file_path)
        return { success: false, message: "File not found: #{file_path}" }
      end

      # Run system 'file' command
      file_info = `file "#{file_path}"`
      expected_patterns = VALID_TYPES[type]

      if expected_patterns.any? { |pattern| file_info =~ pattern }
        { success: true, info: file_info.strip }
      else
        { success: false, info: file_info.strip, message: "Type mismatch: expected #{type}, got #{file_info.strip}" }
      end
    end
  end
end
