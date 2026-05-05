# Arneis::Task - Represents a single unit of work in the orchestration.

module Arneis
  class Task
    attr_reader :id, :dependencies, :block, :check_status_block
    attr_accessor :outputs, :intent_prompt, :verification_results, :operation_id, :status

    def initialize(id, dependencies: [], outputs: {}, intent_prompt: nil, check_status_block: nil, &block)
      @id = id
      @dependencies = dependencies
      @outputs = outputs # Hash of file_path => type
      @intent_prompt = intent_prompt
      @check_status_block = check_status_block # New: Block to check status of polling tasks
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
        result = @block.call if @block
        if result && result[:status] == "polling"
          @status = :polling
          return result
        else
          @status = :done
          return {status: "done"}
        end
      rescue => e
        @status = :failed
        puts Rainbow("  ❌ Task #{@id} failed: #{e.message}").red
        return {status: "failed", message: e.message}
      end
    end

    def fail_verification(message)
      @status = :failed
      puts Rainbow("  ❌ Task #{@id} verification failed: #{message}").red
    end
  end
end
