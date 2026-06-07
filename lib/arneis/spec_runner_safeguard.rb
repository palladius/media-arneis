# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

module Arneis
  class SpecRunnerSafeguard
    HISTORY_FILE = "tmp/.spec_history.json"

    def self.check!(files)
      return unless File.exist?(HISTORY_FILE)

      begin
        history = JSON.parse(File.read(HISTORY_FILE))
      rescue
        history = {}
      end

      files.each do |file|
        abs_path = File.expand_path(file)
        if history[abs_path] && history[abs_path]["consecutive_failures"].to_i >= 3
          # Print a loud visual banner to warn the developer or agent
          warn "\n" + "=" * 80
          warn "🚨  CIRCUIT BREAKER TRIGGERED  🚨"
          warn "Spec file '#{file}' has failed 3 consecutive times."
          warn "Halted execution to prevent endless test-fix loops."
          warn "Please manually review the failure before retrying."
          warn "=" * 80 + "\n"
          raise "🚨 CIRCUIT BREAKER: Spec file '#{file}' has failed 3 times consecutively. Halting to prevent loop."
        end
      end
    end

    def self.record_run!(files, passed)
      begin
        history = File.exist?(HISTORY_FILE) ? JSON.parse(File.read(HISTORY_FILE)) : {}
      rescue
        history = {}
      end

      files.each do |file|
        abs_path = File.expand_path(file)
        history[abs_path] ||= {"consecutive_failures" => 0}

        if passed
          history[abs_path]["consecutive_failures"] = 0
        else
          history[abs_path]["consecutive_failures"] = history[abs_path]["consecutive_failures"].to_i + 1
        end
        history[abs_path]["last_run"] = Time.now.iso8601
      end

      FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
      File.write(HISTORY_FILE, JSON.pretty_generate(history))
    end
  end
end
