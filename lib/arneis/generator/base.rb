# Arneis::Generator::Base - Base class for all media generators.

module Arneis
  module Generator
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def generate(prompt, output_file = nil, timeout: 60)
        raise NotImplementedError, "Subclasses must implement generate"
      end

      protected

      def dryrun?
        Config.dryrun?
      end

      def maybe_mock(output_file, type, prompt)
        puts Rainbow("  🌵 [DRYRUN] Mocking #{type.to_s.upcase} for: #{prompt[0..50]}...").yellow
        FileUtils.mkdir_p(File.dirname(output_file)) if output_file
        File.write("#{output_file}.mock", "MOCK_#{type.to_s.upcase}_DATA: #{prompt}")
        {status: "mocked", tokens: 0, cost: 0.0, time: 0}
      end

      def after_creation(output_file, type)
        return unless output_file && File.exist?(output_file)
        Validator.validate_and_rename!(output_file, type)
      end

      def with_retry(max_retries: 3)
        retries = 0
        begin
          yield
        rescue => e
          if e.message.include?("429") && retries < max_retries
            wait_time = 2**retries
            puts Rainbow("  ⏳ [RATE LIMIT] 429 detected. Retrying in #{wait_time}s... (Attempt #{retries + 1}/#{max_retries})").yellow
            sleep(wait_time)
            retries += 1
            retry
          end
          raise e
        end
      end
    end
  end
end
