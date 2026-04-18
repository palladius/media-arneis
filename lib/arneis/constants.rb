=begin
Arneis::Constants - Centralized model names and other project-wide constants.
=end

module Arneis
  module Models
    # Gemini Text & Evals
    GEMINI_FLASH = 'gemini-2.5-flash'
    GEMINI_PRO   = 'gemini-2.5-pro'
    
    # Veo Video Generation
    VEO_DEFAULT = 'veo-2.0-generate-001' # From list_models and skills
    VEO_3_1     = 'veo-3.1-generate-preview'
    
    # Lyria Music Generation
    LYRIA_CLIP  = 'lyria-3-clip-preview' # From musicgen-lyria3 skill
    LYRIA_PRO   = 'lyria-3-pro-preview'
    
    # Audio / TTS / Narration
    CHIRP_DEFAULT = 'gemini-3.1-flash-tts-preview' # From VideoProject template / skills
    
    # Image Generation
    NANOBANANA = 'gemini-3.1-flash-image-preview'
  end
  
  # Resource Pricing (Rough estimates)
  module Pricing
    COST_PER_VEO_GEN = 0.50
    COST_PER_LYRIA_GEN = 0.10
    COST_PER_1K_TOKENS = 0.01
  end
end
