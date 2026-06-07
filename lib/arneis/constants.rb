# Arneis::Constants - Centralized model names and other project-wide constants.
# Based on recommendations in GEMINI.md.

module Arneis
  module Models
    # Gemini Text & Evals
    GEMINI_FLASH = ENV["ARNEIS_FLASH_MODEL"] || "gemini-2.5-flash"
    GEMINI_PRO = ENV["ARNEIS_PRO_MODEL"] || "gemini-2.5-pro"

    # Generic main model (defaults to flash 2.5)
    MAIN = ENV["ARNEIS_MAIN_MODEL"] || GEMINI_FLASH

    # Veo Video Generation
    VEO_2 = ENV["ARNEIS_VEO_2_MODEL"] || "veo-2.0-generate-001"
    VEO_DEFAULT = ENV["ARNEIS_VEO_DEFAULT_MODEL"] || "veo-3.0-generate-001"

    # Lyria Music Generation
    LYRIA_CLIP = ENV["ARNEIS_LYRIA_CLIP_MODEL"] || "lyria-3-clip-preview"
    LYRIA_DEFAULT = ENV["ARNEIS_LYRIA_DEFAULT_MODEL"] || "lyria-3-pro-preview"

    # Chirp Speech / Narration
    CHIRP_2 = ENV["ARNEIS_CHIRP_2_MODEL"] || "chirp_2"
    CHIRP_DEFAULT = ENV["ARNEIS_CHIRP_DEFAULT_MODEL"] || "chirp_3"

    # Imagen / Nano Banana
    IMAGEN_DEFAULT = ENV["ARNEIS_IMAGEN_MODEL"] || "gemini-3.1-flash-image-preview"
  end

  # Resource Pricing (Rough estimates)
  module Pricing
    COST_PER_VEO_GEN = 4.00
    COST_PER_LYRIA_GEN = 0.10
    COST_PER_IMAGEN_GEN = 0.05
    COST_PER_1K_TOKENS = 0.01
  end
end
