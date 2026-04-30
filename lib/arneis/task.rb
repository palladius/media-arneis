# Arneis::Task - Represents a single unit of work in the orchestration.

module Arneis
  class Task
    attr_reader :id, :dependencies, :status, :block

    def initialize(id, dependencies: [], &block)
      @id = id
      @dependencies = dependencies
      @block = block
      @status = :pending
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
  end
end
