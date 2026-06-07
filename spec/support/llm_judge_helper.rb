# spec/support/llm_judge_helper.rb
# RSpec custom helper and matchers for LLM-as-judge media evaluations.

require "rspec/expectations"
require_relative "../../lib/arneis"

RSpec::Matchers.define :meet_media_criteria do |expected_behavior|
  match do |actual_file_path|
    unless File.exist?(actual_file_path)
      @message = "File does not exist at #{actual_file_path}"
      next false
    end

    # If dryrun? is true, we mock a successful judgment to avoid calling real Gemini during dryruns
    if Arneis::Config.dryrun?
      @message = "Mocked judgment (dry-run)"
      next true
    end

    evaluator = Arneis::Evaluator.new
    ext = File.extname(actual_file_path).downcase

    if ext == ".wav" || ext == ".mp3"
      puts "  ⚖️  [LLM JUDGE] Evaluating audio #{actual_file_path} against: '#{expected_behavior}'..."
      
      prompt = <<~PROMPT
        You are a music and audio auditor. Listen to the provided audio.
        Does the audio accurately match this style/intent description: "#{expected_behavior}"?
        Check for instrumentation, tempo, mood, genre, or clarity as described.

        Output format:
        SUCCESS: <true/false>
        REASON: <brief explanation of your verdict>
      PROMPT

      begin
        gemini = Arneis::Generator::Gemini.new
        res = gemini.generate(prompt, audio: [actual_file_path])
        text = res[:content]
        
        success = text.match(/SUCCESS:\s*(true|false)/i)&.captures&.first&.downcase == "true"
        @message = text.match(/REASON:\s*(.*)/m)&.captures&.first&.strip || "No reason provided"
        success
      rescue => e
        @message = "Audio evaluation failed: #{e.message}"
        false
      end
    else
      # Image or Video
      puts "  ⚖️  [LLM JUDGE] Evaluating visual asset #{actual_file_path} against: '#{expected_behavior}'..."
      res = evaluator.check_multimodal(actual_file_path, expected_behavior)
      @message = res[:message]
      res[:success]
    end
  end

  failure_message do |actual_file_path|
    "Expected #{actual_file_path} to meet criteria: '#{expected_behavior}', but judge failed.\n   Judge Reason: #{@message}"
  end

  failure_message_when_negated do |actual_file_path|
    "Expected #{actual_file_path} NOT to meet criteria: '#{expected_behavior}', but it did.\n   Judge Reason: #{@message}"
  end
end
