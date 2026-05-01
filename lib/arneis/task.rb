# Arneis::Task - Represents a single unit of work in the orchestration.

module Arneis
  class Task
    attr_reader :id, :dependencies, :status, :block
    attr_accessor :outputs, :intent_prompt, :verification_results

    def initialize(id, dependencies: [], outputs: {}, intent_prompt: nil, &block)
      @id = id
      @dependencies = dependencies
      @outputs = outputs # Hash of file_path => type
      @intent_prompt = intent_prompt
      @block = block
      @status = :pending
      @verification_results = []
    end

    def ready?(completed_tasks)
      @dependencies.all? { |dep| completed_tasks.include?(dep) }
    end

    def execute
      @status = :in_progress
      begin
        @block.call if @block
        @status = :done
      rescue => e
        @status = :failed
        puts Rainbow("  ❌ Task #{@id} failed: #{e.message}").red
        # We don't re-raise, as the orchestrator handles the flow
      end
    end

    def fail_verification(message)
      @status = :failed
      puts Rainbow("  ❌ Task #{@id} verification failed: #{message}").red
    end
  end
end
