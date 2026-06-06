# Arneis::Orchestrator - Manages task execution with dependency awareness.
# Refactored to use the 'async' gem for fiber-based concurrency.

require "async"
require "async/barrier"
require "async/semaphore"
require "zeitwerk"
require "json"
require "rainbow"

module Arneis
  class Orchestrator
    attr_reader :completed_tasks, :verify, :eval_enabled

    def initialize(async: true, pre_completed: [], verify: false, eval: true)
      @tasks = {}
      @polling_tasks = {} # New: Stores tasks that need polling
      @async_enabled = async
      @verify = verify
      @eval_enabled = eval
      @completed_tasks = Array(pre_completed).map(&:to_sym)
      # Limit concurrent AI operations to avoid rate limits
      @semaphore = Async::Semaphore.new(Arneis::Config.max_concurrent_tasks || 3)
      @mutex = Thread::Mutex.new
    end

    def add_task(id, dependencies: [], outputs: {}, intent_prompt: nil, check_status_block: nil, &block)
      @tasks[id.to_sym] = Task.new(id.to_sym, dependencies: dependencies.map(&:to_sym), outputs: outputs, intent_prompt: intent_prompt, check_status_block: check_status_block, &block)
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
      puts Rainbow("⌛ Running orchestration in SYNC mode...").yellow
      loop do
        # 1. Process currently polling tasks
        @polling_tasks.each do |id, task|
          puts Rainbow("  🔍 Polling task #{id}...").cyan
          result = task.check_status_block.call
          if result[:status] == "done"
            puts Rainbow("  ✅ Task #{id} completed polling!").green
            task.status = :done # Update task status directly
            @completed_tasks << id
            @polling_tasks.delete(id)
          elsif result[:status] == "failed"
            puts Rainbow("  ❌ Task #{id} failed during polling: #{result[:message]}").red
            task.status = :failed # Update task status directly
            @completed_tasks << id
            @polling_tasks.delete(id)
          end
        end

        # 2. Find new runnable tasks (excluding those already polling)
        runnable = @tasks.values.reject { |t| @completed_tasks.include?(t.id) || @polling_tasks.key?(t.id) }
          .select { |t| t.ready?(@completed_tasks) }

        break if runnable.empty? && @polling_tasks.empty? # Stop if no runnable tasks and no polling tasks

        runnable.each do |task|
          task_result = task.execute # task.execute now returns a hash {status: ..., operation_id: ...}

          if task_result && task_result[:status] == "polling"
            puts Rainbow("  🔵 Task #{task.id} is polling (Operation: #{task_result[:operation_id]})...").blue
            task.status = :polling # Set task status to polling
            task.operation_id = task_result[:operation_id] # Store operation_id
            @polling_tasks[task.id] = task # Add task object to polling_tasks
          elsif task.status == :done
            verify_task(task) if @verify && task.status == :done
            @completed_tasks << task.id
          elsif task.status == :failed
            @completed_tasks << task.id
          end
        end

        sleep 1 # Small delay to avoid busy-waiting
      end
    end

    def run_async
      puts Rainbow("🏎️  Running orchestration in ASYNC mode (Fibers)...").green
      Async do |parent|
        task_fibers = {}
        polling_fibers = {} # New: Fibers dedicated to polling tasks

        # Loop until all tasks are scheduled and completed
        loop do
          # 1. Start/Resume polling for tasks that are in polling_tasks
          @polling_tasks.each do |id, task|
            unless polling_fibers.key?(id)
              polling_fibers[id] = parent.async do
                loop do
                  puts Rainbow("  🔍 Polling task #{id}...").cyan
                  result = task.check_status_block.call
                  if result[:status] == "done"
                    puts Rainbow("  ✅ Task #{id} completed polling!").green
                    task.status = :done
                    @completed_tasks << id
                    @polling_tasks.delete(id)
                    break # Exit polling loop for this task
                  elsif result[:status] == "failed"
                    puts Rainbow("  ❌ Task #{id} failed during polling: #{result[:message]}").red
                    task.status = :failed
                    @completed_tasks << id
                    @polling_tasks.delete(id)
                    break # Exit polling loop for this task
                  end
                  sleep 5 # Poll every 5 seconds
                end
              end
            end
          end
          # Clean up finished polling fibers
          polling_fibers.delete_if { |id, fiber| @completed_tasks.include?(id) }

          # 2. Find new runnable tasks (excluding those already polling or completed)
          scheduled_ids = task_fibers.keys
          runnable = @tasks.values.reject { |t| @completed_tasks.include?(t.id) || scheduled_ids.include?(t.id) || @polling_tasks.key?(t.id) }
            .select { |t| t.ready?(@completed_tasks) }

          runnable.each do |task|
            task_fibers[task.id] = parent.async do
              @semaphore.acquire do
                task_result = task.execute
                if task_result && task_result[:status] == "polling"
                  puts Rainbow("  🔵 Task #{task.id} is polling (Operation: #{task_result[:operation_id]})...").blue
                  task.operation_id = task_result[:operation_id]
                  task.status = :polling # Set task status to polling
                  @polling_tasks[task.id] = task # Add to polling tasks
                elsif task.status == :done
                  verify_task(task) if @verify && task.status == :done
                  @completed_tasks << task.id
                elsif task.status == :failed
                  @completed_tasks << task.id
                end
              end
            end
          end

          # Clean up finished execution fibers (not polling ones)
          task_fibers.delete_if { |id, fiber| @completed_tasks.include?(id) }

          # 3. Check termination condition
          # All tasks are either completed or failed, and no tasks are currently executing or polling
          all_tasks_finished = @tasks.values.all? { |t| @completed_tasks.include?(t.id) }
          no_active_fibers = task_fibers.values.all?(&:finished?)
          no_polling_fibers = polling_fibers.values.all?(&:finished?) # All polling is done

          break if all_tasks_finished && no_active_fibers && no_polling_fibers

          # 4. Detect deadlocks (optional, but good for debugging)
          if runnable.empty? && task_fibers.values.all?(&:finished?) && !all_tasks_finished
            puts Rainbow("⚠️  Orchestration Deadlock detected! Circular dependencies might exist.").red
            break
          end

          sleep 0.1 # Small delay to avoid busy-waiting
        end
      end
    end

    def verify_task(task)
      puts Rainbow("  🛡️  [VERIFY] Verifying task #{task.id}...").cyan

      begin
        # 1. Basic Asset Check
        v_result = Validator.verify_assets(task)
        task.verification_results << v_result.merge(type: "asset_integrity")
        unless v_result[:success]
          task.fail_verification(v_result[:message])
          save_verification_metadata(task)
          print_retry_hint(task)
          return
        end

        # Skip LLM evaluation if disabled
        unless @eval_enabled
          puts Rainbow("  ⏭️  [EVAL] Automated evaluation disabled (via flag or ENV)").yellow
          save_verification_metadata(task)
          return
        end

        @evaluator ||= Evaluator.new

        # 2. JSON/Logic Check (Tier 1)
        task.outputs.each do |path, type|
          if type == :json && File.exist?(path)
            j_result = @evaluator.check_json(File.read(path))
            task.verification_results << j_result.merge(type: "json_logic", file: path)
            unless j_result[:success]
              task.fail_verification("JSON Logic Error: #{j_result[:message]}")
              save_verification_metadata(task)
              print_retry_hint(task)
              return
            end
          end
        end

        # 3. Multimodal Intent Check (Tier 2)
        if task.intent_prompt
          task.outputs.each do |path, type|
            if [:image, :video].include?(type) && File.exist?(path)
              m_result = @evaluator.check_multimodal(path, task.intent_prompt)
              task.verification_results << m_result.merge(type: "multimodal_intent", file: path)
              unless m_result[:success]
                task.fail_verification("Intent Mismatch: #{m_result[:message]}")
                save_verification_metadata(task)
                print_retry_hint(task)
                return
              end
            end
          end
        end

        puts Rainbow("  ✅ Task #{task.id} verified successfully!").green
        save_verification_metadata(task)
      rescue => e
        puts Rainbow("  ❌ [VERIFY] Internal Error: #{e.message}").red
        puts e.backtrace.first(5)
        raise e
      end
    end

    def print_retry_hint(task)
      first_output = task.outputs.keys.first
      return unless first_output

      parts = first_output.split("/")
      out_idx = parts.index("out")
      run_id = if out_idx && parts[out_idx + 1]
        parts[out_idx + 1]
      else
        parts.first
      end

      run_dir = out_idx ? File.join("out", run_id) : run_id
      if Dir.exist?(run_dir)
        yamls = Dir.glob(File.join(run_dir, "*.yaml")).reject { |f| File.basename(f) == ".state.yaml" }
        kind = nil
        unless yamls.empty?
          begin
            spec_data = YAML.load_file(yamls.first)
            kind = spec_data["kind"]
          rescue
          end
        end
        kind ||= "CharacterImage"

        puts Rainbow("\nTo retry with eval feedback, run:").yellow +
          Rainbow(" arnectl generate #{kind} --retry #{run_id}").cyan
      end
    end

    def save_verification_metadata(task)
      @mutex.synchronize do
        task.outputs.each do |path, _type|
          asset_json = "#{path}.asset.json"
          data = if File.exist?(asset_json)
            JSON.parse(File.read(asset_json))
          else
            {asset_id: task.id.to_s, status: task.status.to_s}
          end

          data["verification"] = task.verification_results
          File.write(asset_json, JSON.pretty_generate(data))
        end
      end
    end
  end
end
