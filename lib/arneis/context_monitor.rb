# frozen_string_literal: true

require "fileutils"

module Arneis
  # Monitors the current Gemini CLI conversation transcript for context size.
  # Warns when the number of steps exceeds a threshold, helping prevent
  # agents from running into token limits.
  class ContextMonitor
    BRAIN_DIR = File.expand_path("~/.gemini/antigravity-cli/brain")
    DEFAULT_THRESHOLD = 1000

    # Count the number of steps (lines) in a conversation's transcript.
    #
    # @param conversation_id [String] The UUID of the conversation.
    # @return [Integer] The number of steps in the transcript.
    def self.count_steps(conversation_id)
      transcript = File.join(BRAIN_DIR, conversation_id, ".system_generated", "logs", "transcript.jsonl")
      return 0 unless File.exist?(transcript)

      File.foreach(transcript).count
    end

    # Find the conversation ID with the most recently modified transcript.
    #
    # @return [String, nil] The conversation ID, or nil if none found.
    def self.find_latest_conversation
      return nil unless Dir.exist?(BRAIN_DIR)

      conversations = Dir.children(BRAIN_DIR)
        .select { |d| File.directory?(File.join(BRAIN_DIR, d)) }
        .select { |d|
          File.exist?(File.join(BRAIN_DIR, d, ".system_generated", "logs", "transcript.jsonl"))
        }

      return nil if conversations.empty?

      conversations.max_by { |d|
        File.mtime(File.join(BRAIN_DIR, d, ".system_generated", "logs", "transcript.jsonl"))
      }
    end

    # Check the current conversation's step count and emit a warning if it exceeds the threshold.
    #
    # @param conversation_id [String] The UUID of the conversation to check.
    # @param threshold [Integer] The step count that triggers the warning (default: 1000).
    def self.check_and_warn!(conversation_id, threshold: DEFAULT_THRESHOLD)
      steps = count_steps(conversation_id)
      return if steps <= threshold

      warn "\n" + "=" * 80
      warn "⚠️  CONTEXT SIZE WARNING  ⚠️"
      warn "Current conversation has #{steps} steps (threshold: #{threshold})."
      warn "You are approaching the token limits of the context window."
      warn "Consider starting a fresh session to avoid degraded performance."
      warn "=" * 80 + "\n"
    end
  end
end
