# Arneis::Generator::Mock - Mock generator for testing purposes.

module Arneis
  module Generator
    class Mock < Base
      def generate(prompt, output_file, *args)
        puts "  [MOCK] Generating media for prompt: '#{prompt}' -> #{output_file}"
        sleep(rand(0.1..0.5)) unless ENV["RSPEC_RUNNING"] == "true"
        File.write(output_file, "Mock content for: #{prompt}")
        {status: "done", tokens: 100, cost: 0.01, time: 0.5}
      end
    end
  end
end
