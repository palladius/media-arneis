=begin
Arneis::Orchestrator - Manages the execution of tasks based on their dependencies.
Uses Threads for true parallelism of blocking IO tasks.
=end

require 'thread'

module Arneis
  class Orchestrator
    attr_reader :tasks, :completed_tasks

    def initialize
      @tasks = []
      @completed_tasks = []
      @mutex = Mutex.new
    end

    def add_task(id, dependencies: [], &block)
      @tasks << Task.new(id, dependencies: dependencies, &block)
    end

    def run
      threads = @tasks.map do |task|
        Thread.new do
          # Wait for dependencies to be completed
          loop do
            is_ready = false
            @mutex.synchronize do
              is_ready = task.ready?(@completed_tasks)
            end
            break if is_ready
            sleep(0.2) # Wait a bit before checking again
          end

          task.execute

          @mutex.synchronize do
            @completed_tasks << task.id
          end
        end
      end

      threads.each(&:join)
    end
  end
end
