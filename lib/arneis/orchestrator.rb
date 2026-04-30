# Arneis::Orchestrator - Manages task execution with dependency awareness.
# Refactored to use the 'async' gem for fiber-based concurrency.

require "async"
require "async/barrier"
require "async/semaphore"
require "zeitwerk"

module Arneis
  class Orchestrator
    attr_reader :completed_tasks

    def initialize(async: true, pre_completed: [])
      @tasks = {}
      @async_enabled = async
      @completed_tasks = Array(pre_completed).map(&:to_sym)
      # Limit concurrent AI operations to avoid rate limits
      @semaphore = Async::Semaphore.new(Arneis::Config.max_concurrent_tasks || 3)
    end

    def add_task(id, dependencies: [], &block)
      @tasks[id.to_sym] = Task.new(id.to_sym, dependencies: dependencies.map(&:to_sym), &block)
    end

    def run
      return if @tasks.empty?

      if @async_enabled
        run_async
      else
        run_sync
      end
    end

    private

    def run_sync
      puts Rainbow("🔀 Running orchestration in SYNC mode...").yellow
      loop do
        runnable = @tasks.values.reject { |t| @completed_tasks.include?(t.id) }
                                 .select { |t| (t.dependencies - @completed_tasks).empty? }
        break if runnable.empty?

        runnable.each do |task|
          task.execute
          # We mark it as completed even if it failed, so the loop can finish
          @completed_tasks << task.id
        end
      end
    end

    def run_async
      puts Rainbow("🚀 Running orchestration in ASYNC mode (Fibers)...").green
      Async do |parent|
        task_fibers = {}

        # Loop until all tasks are scheduled
        loop do
          scheduled_ids = task_fibers.keys
          runnable = @tasks.values.reject { |t| @completed_tasks.include?(t.id) || scheduled_ids.include?(t.id) }
                                   .select { |t| (t.dependencies - @completed_tasks).empty? }

          runnable.each do |task|
            task_fibers[task.id] = parent.async do
              @semaphore.acquire do
                task.execute
              end
              # Mark as completed (even if failed) so dependents can be evaluated (they might fail too or skip)
              @completed_tasks << task.id
            end
          end

          break if @tasks.values.all? { |t| @completed_tasks.include?(t.id) }

          # Check for real deadlocks (no tasks runnable and all fibers finished, but not all tasks in completed_tasks)
          # This should only happen if there are circular dependencies
          if runnable.empty? && task_fibers.values.all?(&:finished?) && !@tasks.values.all? { |t| @completed_tasks.include?(t.id) }
             puts Rainbow("⚠️  Orchestration Deadlock detected! Circular dependencies might exist.").red
             break
          end

          sleep 0.1 
        end
      end
    end  end
end
