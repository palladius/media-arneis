=begin
Arneis::Orchestrator - Manages task execution with dependency awareness.
Refactored to use the 'async' gem for fiber-based concurrency.
=end

require 'async'
require 'async/barrier'
require 'async/semaphore'
require 'zeitwerk'

module Arneis
  class Orchestrator
    attr_reader :completed_tasks

    def initialize(async: true)
      @tasks = {}
      @async_enabled = async
      @completed_tasks = []
      # Limit concurrent AI operations to avoid rate limits
      @semaphore = Async::Semaphore.new(Arneis::Config.max_concurrent_tasks || 3)
    end

    def add_task(id, dependencies: [], &block)
      @tasks[id.to_sym] = Task.new(id.to_sym, dependencies: dependencies, &block)
    end

    def run
      if @async_enabled
        run_async
      else
        run_sync
      end
    end

    private

    def run_sync
      puts Rainbow("🔀 Running orchestration in SYNC mode...").yellow
      completed = []
      loop do
        runnable = @tasks.values.reject { |t| completed.include?(t.id) }
                                 .select { |t| (t.dependencies - completed).empty? }
        break if runnable.empty?

        runnable.each do |task|
          task.execute
          @completed_tasks << task.id
          completed << task.id
        end
      end
    end

    def run_async
      puts Rainbow("🚀 Running orchestration in ASYNC mode (Fibers)...").green
      Async do |parent|
        barrier = Async::Barrier.new
        completed = []
        task_fibers = {}

        # Loop until all tasks are scheduled
        loop do
          runnable = @tasks.values.reject { |t| completed.include?(t.id) || task_fibers.key?(t.id) }
                                   .select { |t| (t.dependencies - completed).empty? }
          
          runnable.each do |task|
            task_fibers[task.id] = parent.async do
              @semaphore.acquire do
                task.execute
              end
              @completed_tasks << task.id
              completed << task.id
            end
          end

          break if completed.size == @tasks.size
          # Wait a tiny bit for fibers to progress and dependencies to clear
          sleep 0.1 
        end
        
        barrier.wait
      end
    end
  end
end
