# Arneis::Test::ExpensiveSuite - Orchestrates the full expensive test run.

require_relative "base"

module Arneis
  module Test
    class ExpensiveSuite < Base
      def initialize(output_dir: "out/tests/expensive/")
        super
        @tests = []
        @results = []
      end

      def add_test(name, &block)
        @tests << {name: name, block: block}
      end

      def run_all
        unless self.class.should_run?
          puts self.class.skip_message
          return
        end

        puts Rainbow("💎 Running Expensive Media Test Suite...").magenta.bold

        total_cost = 0.0
        total_time = 0.0

        @tests.each do |test|
          log_start(test[:name])
          start_ts = Time.now
          begin
            result = test[:block].call
            duration = (Time.now - start_ts).round(2)
            log_success(test[:name], time: duration, cost: result[:cost])
            @results << {name: test[:name], status: "PASS", time: duration, cost: result[:cost]}
            total_cost += result[:cost] || 0.0
            total_time += duration
          rescue => e
            log_failure(test[:name], e.message)
            @results << {name: test[:name], status: "FAIL", error: e.message}
          end
        end

        print_summary(total_cost, total_time)
      end

      private

      def print_summary(total_cost, total_time)
        puts "\n" + Rainbow("📊 Expensive Test Summary").cyan.bold
        puts "----------------------------"
        @results.each do |r|
          status_color = (r[:status] == "PASS") ? :green : :red
          puts "  #{Rainbow(r[:status]).color(status_color)} | #{r[:name]} (#{r[:time]}s, $#{r[:cost]})"
        end
        puts "----------------------------"
        puts Rainbow("💰 Total Cost: $#{total_cost.round(4)}").yellow.bold
        puts Rainbow("⏳ Total Time: #{total_time.round(2)}s").white.bold
      end
    end
  end
end
