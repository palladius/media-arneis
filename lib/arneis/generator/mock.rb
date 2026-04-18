=begin
Arneis::Generator::Mock - Mock generator for testing purposes.
=end

module Arneis
  module Generator
    class Mock < Base
      def generate(prompt, output_file)
        puts "  [MOCK] Generating media for prompt: '#{prompt}' -> #{output_file}"
        sleep(rand(0.5..2.0)) # Simulate generation time
        File.write(output_file, "Mock content for: #{prompt}")
        { tokens: 100, cost: 0.01, time: 1.5 }
      end
    end
  end
end
