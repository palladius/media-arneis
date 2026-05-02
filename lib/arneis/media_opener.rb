# Arneis::MediaOpener - Logic for opening media files across platforms.

require "rbconfig"
require "rainbow"

module Arneis
  module MediaOpener
    def self.open(path)
      return unless path && File.exist?(path)

      puts Rainbow("📂 Opening primary artifact: #{path}...").cyan
      case RbConfig::CONFIG["host_os"]
      when /mswin|mingw|cygwin/
        system "start #{path}"
      when /darwin/
        system "open #{path}"
      when /linux|bsd/
        # Check if xdg-open exists to avoid silent failures
        if system("which xdg-open > /dev/null 2>&1")
          system "xdg-open #{path} > /dev/null 2>&1"
        else
          puts Rainbow("⚠️  xdg-open not found. Cannot open #{path} automatically.").yellow
        end
      end
    end
  end
end
