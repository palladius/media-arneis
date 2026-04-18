=begin
Arneis::Orchestrator - Manages the execution of tasks based on their dependencies.
Uses Ruby Fibers for concurrency.
=end

require 'fiber'

module Arneis
  class Orchestrator
    attr_reader :tasks, :completed_tasks

    def initialize
      @tasks = []
      @completed_tasks = []
    end

    def add_task(id, dependencies: [], &block)
      @tasks << Task.new(id, dependencies: dependencies, &block)
    end

    def run
      fibers = @tasks.map do |task|
        Fiber.new do
          until task.ready?(@completed_tasks)
            Fiber.yield
          end
          task.execute
          @completed_tasks << task.id
        end
      end

      until fibers.all? { |f| !f.alive? }
        fibers.each { |f| f.resume if f.alive? }
      end
    end
  end
end
