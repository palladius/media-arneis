# Arneis::CharactersCli - Subcommand for character management.

require "thor"
require "rainbow"

module Arneis
  class CharactersCli < Thor
    desc "list", "List all characters"
    def list
      puts Rainbow("👥 Listing characters from data/characters/...").cyan.bold
      characters = Character.all
      if characters.empty?
        puts Rainbow("  ⚠️  No characters found.").yellow
        return
      end

      characters.each do |c|
        img_str = (c.image_count > 0) ? Rainbow("#{c.image_count} 🖼️").green : Rainbow("0 🖼️").red
        id_str = Rainbow("📂 #{c.id}/").blue.ljust(18)
        name_str = "#{c.emoji} #{c.nationality_emoji} #{Rainbow(c.name.ljust(12)).yellow}"
        nick_str = "(#{Rainbow(c.nickname.ljust(10)).white})"
        puts "  #{id_str} #{name_str} #{nick_str} | #{img_str}"
      end
    end

    desc "show NAME", "Show details for a character"
    def show(name)
      if %w[--help -h].include?(name)
        help("show")
        return
      end
      char = Character.find(name)
      unless char
        puts Rainbow("❌ Character not found: #{name}").red
        return
      end

      puts Rainbow("👤 Character: #{char.full_name} #{char.emoji} #{char.nationality_emoji}").cyan.bold
      puts "  #{Rainbow("Nickname:").white} #{char.nickname}"

      img_count = char.image_count
      img_status = (img_count > 0) ? Rainbow("#{img_count} images").green : Rainbow("No images").red
      puts "  #{Rainbow("Reference:").white} 📂 #{char.consistency_images_dir} (#{img_status})"

      if char.personality
        puts "\n  #{Rainbow("🧠 Personality:").magenta}"
        puts char.personality.split("\n").map { |l| "    #{l}" }.join("\n")
      end

      if char.visual_look
        puts "\n  #{Rainbow("🎨 Visual Look:").blue}"
        puts char.visual_look.split("\n").map { |l| "    #{l}" }.join("\n")
      end

      puts ""
    end
  end
end
