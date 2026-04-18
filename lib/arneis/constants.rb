=begin
Arneis::Constants - Centralized model names and other project-wide constants.
Based on recommendations in GEMINI.md.
=end

module Arneis
  module Models
    # Gemini Text & Evals
    GEMINI_FLASH = 'gemini-2.5-flash'
    GEMINI_PRO   = 'gemini-2.5-pro'
    
    # Veo Video Generation
    VEO_2       = 'veo-2.0-generate-001'
    VEO_DEFAULT = 'veo-3.0-generate-001' # confirmed via test script
    
    # Lyria Music Generation
    LYRIA_CLIP  = 'lyria-3-clip-preview'
    LYRIA_DEFAULT = 'lyria-3-pro-preview'    # High quality
    
    # Chirp Speech / Narration
    CHIRP_2     = 'chirp_2'
    CHIRP_DEFAULT = 'chirp_3'                # Latest GA
    
    # Imagen / Nano Banana
    NANO_BANANA_1 = 'gemini-2.5-flash-image'
    NANO_BANANA_PRO = 'gemini-3-pro-image-preview'
    NANO_BANANA_2 = 'gemini-3.1-flash-image-preview'
    IMAGEN_DEFAULT = NANO_BANANA_2
  end
  
  # Resource Pricing (Rough estimates)
  module Pricing
    COST_PER_VEO_GEN = 4.00
    COST_PER_LYRIA_GEN = 0.10
    COST_PER_IMAGEN_GEN = 0.05
    COST_PER_1K_TOKENS = 0.01
  end
end
