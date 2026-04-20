=begin
Arneis::MarketingConfig - Platform-specific prompt templates for marketing assets.
Defines style, aspect ratio, and tone for LinkedIn, Instagram, and X.
=end

module Arneis
  module MarketingConfig
    PLATFORMS = {
      linkedin: {
        aspect_ratio: "16:9",
        style: "professional, clean, minimalist, corporate infographic style",
        text_requirement: "formal, data-driven, includes title and professional hashtags",
        suffix: "linkedin"
      },
      instagram_stories: {
        aspect_ratio: "9:16",
        style: "vibrant, lifestyle, high-contrast, trendy, visual-heavy",
        text_requirement: "minimal text, punchy call-to-action, emotional resonance",
        suffix: "instagram_story"
      },
      x_twitter: {
        aspect_ratio: "16:9",
        style: "sharp, high-energy, digital-native, tech-focused",
        text_requirement: "short, punchy text, community hashtags, optimized for mobile feed",
        suffix: "x_twitter"
      }
    }

    def self.prompt_for(platform, project_title, context)
      config = PLATFORMS[platform]
      return nil unless config

      "Create a high-fidelity marketing image for '#{project_title}'. 
      Style: #{config[:style]}. 
      Tone: #{config[:text_requirement]}. 
      Context: #{context}. 
      Ensure the composition matches a #{config[:aspect_ratio]} aspect ratio."
    end
  end
end
