# Arneis::Orchestrator - Manages task execution with dependency awareness.
# Refactored to use the 'async' gem for fiber-based concurrency.

require "async"
require "async/barrier"
require "async/semaphore"
require "zeitwerk"
require "json"

module Arneis
  class Orchestrator
    attr_reader :completed_tasks, :verify

    def initialize(async: true, pre_completed: [], verify: false)
      @tasks = {}
      @async_enabled = async
      @verify = verify
      @completed_tasks = Array(pre_completed).map(&:to_sym)
      # Limit concurrent AI operations to avoid rate limits
      @semaphore = Async::Semaphore.new(Arneis::Config.max_concurrent_tasks || 3)
    end

    def add_task(id, dependencies: [], outputs: {}, intent_prompt: nil, &block)
      @tasks[id.to_sym] = Task.new(id.to_sym, dependencies: dependencies.map(&:to_sym), outputs: outputs, intent_prompt: intent_prompt, &block)
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
                                 .select { |t| t.ready?(@completed_tasks) }
        break if runnable.empty?

        runnable.each do |task|
          task.execute
          verify_task(task) if @verify && task.status == :done
          # We mark it as completed even if it failed, so the loop can finish
          @completed_tasks << task.id
        end
      end
    end

    def run_async
      puts Rainbow("🏎️  Running orchestration in ASYNC mode (Fibers)...").green
      Async do |parent|
        task_fibers = {}

        # Loop until all tasks are scheduled
        loop do
          scheduled_ids = task_fibers.keys
          runnable = @tasks.values.reject { |t| @completed_tasks.include?(t.id) || scheduled_ids.include?(t.id) }
                                   .select { |t| t.ready?(@completed_tasks) }

          runnable.each do |task|
            task_fibers[task.id] = parent.async do
              @semaphore.acquire do
                task.execute
                verify_task(task) if @verify && task.status == :done
              end
              # Mark as completed (even if failed) so dependents can be evaluated (they might fail too or skip)
              @completed_tasks << task.id
            end
          end

          break if @tasks.values.all? { |t| @completed_tasks.include?(t.id) }

          # Check for real deadlocks
          if runnable.empty? && task_fibers.values.all?(&:finished?) && !@tasks.values.all? { |t| @completed_tasks.include?(t.id) }
             puts Rainbow("⚠️  Orchestration Deadlock detected! Circular dependencies might exist.").red
             break
          end

          sleep 0.1 
        end
      end
    end

    def verify_task(task)
      puts Rainbow("  🛡️  [VERIFY] Verifying task #{task.id}...").cyan
      evaluator = Evaluator.new
      
      # 1. Basic Asset Check
      v_result = Validator.verify_assets(task)
      task.verification_results << v_result.merge(type: "asset_integrity")
      unless v_result[:success]
        task.fail_verification(v_result[:message])
        save_verification_metadata(task)
        return
      end

      # 2. JSON/Logic Check (Tier 1)
      task.outputs.each do |path, type|
        if type == :json && File.exist?(path)
          j_result = evaluator.check_json(File.read(path))
          task.verification_results << j_result.merge(type: "json_logic", file: path)
          unless j_result[:success]
            task.fail_verification("JSON Logic Error: #{j_result[:message]}")
            save_verification_metadata(task)
            return
          end
        end
      end

      # 3. Multimodal Intent Check (Tier 2)
      if task.intent_prompt
        task.outputs.each do |path, type|
          if [:image, :video].include?(type) && File.exist?(path)
            m_result = evaluator.check_multimodal(path, task.intent_prompt)
            task.verification_results << m_result.merge(type: "multimodal_intent", file: path)
            unless m_result[:success]
              task.fail_verification("Intent Mismatch: #{m_result[:message]}")
              save_verification_metadata(task)
              return
            end
          end
        end
      end

      puts Rainbow("  ✅ Task #{task.id} verified successfully!").green
      save_verification_metadata(task)
    end

    def save_verification_metadata(task)
      task.outputs.each do |path, _type|
        asset_json = "#{path}.asset.json"
        data = if File.exist?(asset_json)
                 JSON.parse(File.read(asset_json))
               else
                 { asset_id: task.id.to_s, status: task.status.to_s }
               end
        
        data["verification"] = task.verification_results
        File.write(asset_json, JSON.pretty_generate(data))
      end
    end
  end
end
