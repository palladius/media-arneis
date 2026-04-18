=begin
Arneis::Generator::Base - Base class for all media generators.
=end

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

      def with_retry(max_retries: 3)
        retries = 0
        begin
          yield
        rescue => e
          if e.message.include?('429') && retries < max_retries
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
