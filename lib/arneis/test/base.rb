=begin
Arneis::Test::Base - Common logic for expensive, real-media integration tests.
Ensures tests only run when explicitly requested via ARNEIS_EXPENSIVE_TESTS=true.
=end

require 'rainbow'
require 'fileutils'

module Arneis
  module Test
    class Base
      def self.should_run?
        ENV['ARNEIS_EXPENSIVE_TESTS'] == 'true' || ENV['ARNEIS_EXPENSIVE_TESTS'] == '1'
      end

      def self.skip_message
        Rainbow("⏭️  Skipping expensive LLM tests. To run, set ARNEIS_EXPENSIVE_TESTS=true").yellow
      end

      def initialize(output_dir: 'out/tests/expensive/')
        @output_dir = output_dir
        FileUtils.mkdir_p(@output_dir)
      end

      def log_start(test_name)
        puts Rainbow("🚀 Starting Expensive Test: #{test_name}...").cyan.bold
      end

      def log_success(test_name, stats = {})
        puts Rainbow("✅ Test Passed: #{test_name}").green.bold
        puts Rainbow("   - Time: #{stats[:time]}s").gray if stats[:time]
        puts Rainbow("   - Cost: $#{stats[:cost]}").gray if stats[:cost]
      end

      def log_failure(test_name, error)
        puts Rainbow("❌ Test Failed: #{test_name}").red.bold
        puts Rainbow("   - Error: #{error}").red
      end
    end
  end
end
