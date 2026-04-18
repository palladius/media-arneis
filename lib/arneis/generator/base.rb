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

      def generate(prompt)
        raise NotImplementedError, "Subclasses must implement generate"
      end
    end
  end
end
