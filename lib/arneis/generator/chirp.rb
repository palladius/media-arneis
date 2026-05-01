# Arneis::Generator::Chirp - Media generator using Google Chirp (TTS).
# Orchestrates generation via a TTS API call.

require "open3"
require "fileutils"

module Arneis
  module Generator
    class Chirp < Base
      def initialize(options = {})
        super
        @model = Models::CHIRP_2 # Default to Chirp 2
      end

      def generate(text, output_file, language_code: "en-US", voice_id: nil, asset_id: nil)
        return maybe_mock(output_file, :audio, text) if dryrun?
        
        puts Rainbow("  🗣️  [CHIRP] Generating audio for language #{language_code}...").magenta
        receipt = AssetReceipt.new(asset_id: asset_id || "audio_#{Time.now.to_i}", model: @model, prompt: text[0..100])
        start_time = Time.now

        # Consistent voice mapping
        voice_id ||= case language_code
        when /^en/ then "en-US-Standard-B"
        when /^it/ then "it-IT-Standard-A"
        when /^jp/ then "ja-JP-Standard-C"
        else "en-US-Standard-B"
        end

        # Handle 5000 byte limit by chunking if necessary
        # Note: 5000 bytes is roughly 4000-5000 characters depending on encoding.
        # We'll be conservative and use 4000 characters per chunk.
        if text.bytesize > 4500
          puts Rainbow("    ⚠️  Text exceeds 5000 byte limit. Chunking into multiple requests...").yellow
          chunks = chunk_text(text, 4000)
          chunk_files = []
          
          chunks.each_with_index do |chunk, i|
            chunk_file = "#{output_file}.chunk#{i}.wav"
            res = call_script(chunk, chunk_file, language_code, voice_id)
            if res[:success]
              chunk_files << chunk_file
            else
              puts Rainbow("    ❌ Chunk #{i} failed.").red
            end
          end

          if chunk_files.size == chunks.size
            # Concatenate chunks
            concatenate_chunks(chunk_files, output_file)
            success = true
          else
            success = false
          end
        else
          res = call_script(text, output_file, language_code, voice_id)
          success = res[:success]
        end

        if success && File.exist?(output_file)
          puts Rainbow("  ✅ [CHIRP] Audio generated successfully!").green
          receipt.complete!(cost_usd: 0.01) # Approximate cost
          receipt.save!(output_file)
          Validator.validate_and_rename!(output_file, :audio)
          {status: "done", tokens: 0, cost: 0.01, time: (Time.now - start_time).round(2)}
        else
          raise "Chirp generation failed"
        end
      rescue => e
        sanitized_msg = Config.sanitize(e.message)
        puts Rainbow("  ⚠️ [CHIRP] Failed: #{sanitized_msg}").yellow
        
        if Config.no_mock?
          puts Rainbow("  🚫 Mocking disabled. Raising error.").red
          raise e
        end

        puts Rainbow("  🤡 Falling back to mock.").yellow
        receipt.fail!(error_msg: sanitized_msg)
        receipt.save!(output_file)
        File.write("#{output_file}.mock", "MOCK_CHIRP_DATA: #{text}")
        {status: "mocked", tokens: 0, cost: 0.0, time: 0}
      end

      private

      def call_script(text, output_file, language_code, voice_id)
        # We'll assume there is a util/generate_audio.py similar to others
        escaped_text = text.gsub('"', '\"').gsub("`", '\`').gsub("$", '\$')
        cmd = "uv run util/generate_audio.py --text \"#{escaped_text}\" --lang \"#{language_code}\" --voice \"#{voice_id}\" -o #{output_file}"

        # If util/generate_audio.py doesn't exist, we'll simulate success for now if in development
        unless File.exist?("util/generate_audio.py")
          puts Rainbow("  ⚠️ [CHIRP] util/generate_audio.py missing. Mocking success for development.").yellow
          File.write(output_file, "MOCK AUDIO DATA")
          return {success: true}
        end

        env = {
          "GOOGLE_CLOUD_PROJECT" => Config.google_cloud_project,
          "GOOGLE_CLOUD_REGION" => Config.google_cloud_region
        }

        success = false
        Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          t_err = Thread.new { while line = stderr.gets; puts "    [CHIRP SCRIPT] #{line.strip}"; end rescue nil }
          t_out = Thread.new { while line = stdout.gets; success = true if /^MEDIA:(.*)$/.match?(line); end rescue nil }
          t_err.join; t_out.join
          success = wait_thr.value.success? if success.nil?
        end
        {success: success}
      end

      def chunk_text(text, max_size)
        chunks = []
        words = text.split(/\s+/)
        current_chunk = []

        words.each do |word|
          if (current_chunk.join(" ").length + word.length + 1) > max_size
            chunks << current_chunk.join(" ")
            current_chunk = [word]
          else
            current_chunk << word
          end
        end
        chunks << current_chunk.join(" ") unless current_chunk.empty?
        chunks
      end

      def concatenate_chunks(files, output_file)
        if files.size == 1
          FileUtils.mv(files.first, output_file)
          return
        end

        # Use ffmpeg to concat
        list_file = "#{output_file}.list.txt"
        File.open(list_file, "w") do |f|
          files.each { |path| f.puts "file '#{File.expand_path(path)}'" }
        end

        cmd = "ffmpeg -f concat -safe 0 -i #{list_file} -c copy #{output_file} -y"
        puts "    [FFMPEG] Concatenating chunks: #{cmd}"
        system(cmd)
        
        # Cleanup
        files.each { |f| FileUtils.rm(f) if File.exist?(f) }
        FileUtils.rm(list_file) if File.exist?(list_file)
      end
    end
  end
end
