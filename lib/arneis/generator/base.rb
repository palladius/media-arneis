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
    end
  end
end
