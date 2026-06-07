# Arneis::PowerColon - Automated, text-to-presentation generation engine.
# Compiles structured YAML configurations and Markdown content files into slide decks.

require "yaml"
require "fileutils"
require "rainbow"
require "json"
require "time"

module Arneis
  class PowerColon
    attr_reader :presentation_title, :slides, :output_path, :data, :metadata

    # 1x1 pixel yellow PNG byte string
    TINY_PNG = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\fIDATx\x9cc\xfc\xcf\xb0\x02\x00\x04\x81\x01\x80\x80\xc3\xa6\xed\x00\x00\x00\x00IEND\xaeB\x60\x82".freeze

    def initialize(yaml_path)
      puts Rainbow("💧 Hydrating and validating PowerColon from #{yaml_path}...").cyan
      @yaml_path = yaml_path

      # Hydrate (Deep Merge with Template)
      h_result = Arneis::Hydrator.hydrate(yaml_path)
      unless h_result[:success]
        error = Arneis::Schema::ValidationError.new("Hydration Failed: #{h_result[:message]}", {hydration: [h_result[:message]]}, yaml_path)
        puts error.report
        raise error
      end

      # Validate against Schema
      full_data = h_result[:data]
      contract = Arneis::Schema.contract_for(full_data["kind"])

      unless contract
        raise "Unknown project kind: #{full_data["kind"]}"
      end

      val_result = contract.new.call(full_data)
      unless val_result.success?
        error = Arneis::Schema::ValidationError.new("Validation Error", val_result.errors.to_h, yaml_path)
        puts error.report
        raise error
      end

      # Extract Spec
      @data = full_data["spec"]
      @metadata = full_data["metadata"]
      @presentation_title = @data["presentation_title"]
      @slides = @data["slides"]

      if @slides.nil? || @slides.empty?
        ideate_slides!
      end

      @mutex = Thread::Mutex.new
    end

    def initialize_output(output_path)
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
      FileUtils.mkdir_p(File.join(output_path, "assets"))
      @output_path = output_path

      # Copy YAML to output folder
      FileUtils.cp(@yaml_path, File.join(output_path, File.basename(@yaml_path))) if @yaml_path

      # Create initial state file
      state_file = File.join(output_path, ".state.yaml")
      state = {
        "original_command" => "arnectl " + ARGV.join(" "),
        "presentation_title" => @presentation_title,
        "status" => "initialized",
        "slides" => @slides.map { |s| s.merge("status" => "pending") }
      }
      File.write(state_file, state.to_yaml)
    end

    def process(async: true, verify: false, dryrun: false, eval: true)
      if dryrun
        puts Rainbow("🌵 [DRYRUN] Validation complete. Running orchestration with MOCKS...").yellow
      else
        update_status("in_progress")
      end

      state_file = File.join(@output_path, ".state.yaml")
      current_state = begin
        YAML.load_file(state_file)
      rescue
        {"slides" => [], "status" => "initialized"}
      end

      pre_completed = []
      current_state["slides"]&.each_with_index do |s, idx|
        if s["status"] == "done" || s["status"] == "verified"
          pre_completed << "slide_#{idx}"
        end
      end

      orchestrator = Orchestrator.new(async: async, pre_completed: pre_completed, verify: verify, eval: eval)
      imagen_generator = Generator::Imagen.new
      slide_task_ids = []

      @slides.each_with_index do |slide, idx|
        slide_id = "slide_#{idx}"
        slide_task_ids << slide_id

        state_slide = current_state["slides"]&.at(idx)
        if state_slide && (state_slide["status"] == "done" || state_slide["status"] == "verified")
          puts Rainbow("  ⏭️  Skipping Slide #{idx + 1} (already done)").blue
          next
        end

        # Identify if slide has an image task
        has_image = slide["style"] == "left_image" || slide["image"]
        image_config = slide["image"] || {}
        target_filename = image_config["filename"] || "slide_#{sprintf("%02d", idx + 1)}_illustration.png"
        image_output = File.join(@output_path, "assets", target_filename)

        outputs = has_image ? {image_output => :image} : {}
        slide_title = slide["title"] || "Slide #{idx + 1}"
        if slide["file"] && File.exist?(slide["file"])
          markdown_content = File.read(slide["file"])
          if (match = markdown_content.match(/^#\s+(.*)$/))
            slide_title = match[1]
          end
        end

        intent_prompt = image_config["prompt"] || slide["file"] || slide_title

        orchestrator.add_task(slide_id, outputs: outputs, intent_prompt: intent_prompt) do
          update_slide_status(idx, "in_progress")

          if has_image
            # Run image generation
            aspect_ratio = image_config["aspect_ratio"] || "3:4"
            prompt = image_config["prompt"] || (slide["file"] ? "Illustration for slide: #{File.basename(slide["file"], ".*")}" : "Illustration for slide: #{slide_title}")

            # Check for dryrun or mock mode
            if dryrun || !Config.no_mock?
              puts Rainbow("  🤡 [MOCK] Copying cute placeholder image for slide #{idx + 1}...").yellow
              FileUtils.mkdir_p(File.dirname(image_output))

              mock_src = if aspect_ratio == "3:4"
                "assets/power-colon/images/mock/coming_soon_3x4.png"
              elsif aspect_ratio == "4:3"
                "assets/power-colon/images/mock/coming_soon_4x3.png"
              else
                "assets/power-colon/images/mock/coming_soon_1x1.png"
              end

              if File.exist?(mock_src)
                FileUtils.cp(mock_src, image_output)
              else
                File.write(image_output, TINY_PNG)
              end

              File.write("#{image_output}.mock", "MOCK_IMAGE_DATA: #{prompt}")
              update_slide_status(idx, "verified")
            else
              # Real generation call
              res = imagen_generator.generate(prompt, image_output, aspect_ratio: aspect_ratio, asset_id: "Slide#{idx + 1}.image")
              if res[:status] == "done" || res[:status] == "mocked"
                update_slide_status(idx, "verified")
              else
                update_slide_status(idx, "failed", "Image generation failed")
              end
            end
          else
            update_slide_status(idx, "done")
          end
        end
      end

      # Final Assembly Task
      assembly_id = "final_assembly"
      orchestrator.add_task(assembly_id, dependencies: slide_task_ids, outputs: {File.join(@output_path, "presentation.html") => :text}) do
        puts Rainbow("📖 Assembling final HTML presentation...").magenta
        generate_html_presentation
        generate_export_metadata
      end

      orchestrator.run
      update_status("done")
    end

    def primary_artifact
      File.join(@output_path, "presentation.html")
    end

    private

    def generate_html_presentation
      html_file = File.join(@output_path, "presentation.html")

      slides_html = @slides.map.with_index do |slide, idx|
        slide_title = slide["title"] || "Slide #{idx + 1}"
        slide_content = slide["content"] || ""

        if slide["file"] && File.exist?(slide["file"])
          markdown_content = File.read(slide["file"])
          if (match = markdown_content.match(/^#\s+(.*)$/))
            slide_title = match[1]
          end
          slide_content = markdown_content.gsub(/^#\s+.*$/, "").strip
        end

        style_class = slide["style"]
        image_html = ""

        if style_class == "left_image" || slide["image"]
          image_config = slide["image"] || {}
          target_filename = image_config["filename"] || "slide_#{sprintf("%02d", idx + 1)}_illustration.png"
          image_path = File.join("assets", target_filename)
          image_html = "<div class='slide-image'><img src='#{image_path}' alt='Illustration'></div>"
        end

        <<-HTML
        <section class="slide #{style_class}">
          <div class="slide-container">
            #{image_html}
            <div class="slide-text">
              <h2>#{slide_title}</h2>
              <div class="content">#{slide_content}</div>
            </div>
          </div>
        </section>
        HTML
      end.join("\n")

      template = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{@presentation_title}</title>
        <style>
          body { font-family: 'Outfit', sans-serif; background: #0f0f13; color: #f0f0f5; margin: 0; }
          .slideshow { display: flex; flex-direction: column; gap: 40px; padding: 40px; }
          .slide { background: #1a1a24; border-radius: 12px; padding: 40px; min-height: 400px; display: flex; box-shadow: 0 8px 32px rgba(0,0,0,0.5); }
          .slide-container { display: flex; width: 100%; gap: 40px; }
          .left_image .slide-container { flex-direction: row; }
          .slide-image { flex: 1; display: flex; align-items: center; justify-content: center; }
          .slide-image img { max-width: 100%; border-radius: 8px; box-shadow: 0 4px 16px rgba(0,0,0,0.3); }
          .slide-text { flex: 2; display: flex; flex-direction: column; justify-content: center; }
          h2 { color: #58a6ff; margin-top: 0; }
          .content { font-size: 1.2rem; line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="slideshow">
          #{slides_html}
        </div>
      </body>
      </html>
      HTML

      File.write(html_file, template)
      puts Rainbow("✅ Compiled HTML presentation saved to #{html_file}").green
    end

    def generate_export_metadata
      export_file = File.join(@output_path, "slides_export.json")
      slides_export = @slides.map.with_index do |slide, idx|
        slide_title = slide["title"] || "Slide #{idx + 1}"
        slide_content = slide["content"] || ""

        if slide["file"] && File.exist?(slide["file"])
          markdown_content = File.read(slide["file"])
          if (match = markdown_content.match(/^#\s+(.*)$/))
            slide_title = match[1]
          end
          slide_content = markdown_content.gsub(/^#\s+.*$/, "").strip
        end

        image_config = slide["image"] || {}
        target_filename = image_config["filename"] || "slide_#{sprintf("%02d", idx + 1)}_illustration.png"
        image_path = File.join("assets", target_filename) if slide["style"] == "left_image" || slide["image"]

        {
          "index" => idx + 1,
          "title" => slide_title,
          "style" => slide["style"],
          "content" => slide_content,
          "image_path" => image_path,
          "image_aspect_ratio" => image_config["aspect_ratio"]
        }
      end

      data = {
        "presentation_title" => @presentation_title,
        "export_timestamp" => Time.now.iso8601,
        "slides" => slides_export
      }

      File.write(export_file, JSON.pretty_generate(data))
      puts Rainbow("✅ Exported presentation metadata to #{export_file}").green
    end

    def update_slide_status(slide_idx, status, error_msg = nil)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        slide = state["slides"]&.at(slide_idx)
        if slide
          slide["status"] = status
          slide["error"] = error_msg if error_msg
        end
        File.write(state_file, state.to_yaml)
      end
    end

    def update_status(status)
      @mutex.synchronize do
        state_file = File.join(File.expand_path(@output_path), ".state.yaml")
        state = YAML.load_file(state_file)
        state["status"] = status
        File.write(state_file, state.to_yaml)
      end
    end

    def ideate_slides!
      topic = @data["topic"] || @presentation_title
      num_slides = @data["slides_count"] || 5
      is_fun = @data["fun"] || false

      puts Rainbow("🧠 [GEMINI] Running inline ideation for topic: '#{topic}'...").magenta

      idea = nil
      if Config.dryrun?
        idea = {
          "presentation_title" => topic,
          "slides" => (1..num_slides).map do |i|
            style = if i == 1
              "title_slide"
            else
              ((i == 2) ? "left_image" : "default")
            end
            {
              "style" => style,
              "title" => "Slide #{i} Title",
              "content" => "- Bullet 1\n- Bullet 2",
              "image" => (style == "left_image") ? {"prompt" => "Illustration", "aspect_ratio" => "3:4"} : nil
            }
          end
        }
      else
        gemini = Generator::Gemini.new
        prompt = <<~PROMPT
          You are an expert presentation designer. Create a slide deck outline on the topic: "#{topic}" with exactly #{num_slides} slides.
          The tone should be #{is_fun ? "fun, humorous, and engaging" : "professional and informative"}.

          For each slide, specify:
          1. Title
          2. Style (must be one of: 'title_slide', 'chapter', 'default', 'left_image')
          3. Markdown content (bullet points, etc.)
          4. Optional image details (prompt, aspect_ratio e.g. 3:4 if style is left_image)

          Output the response strictly as a JSON object of this structure (raw JSON text, NO markdown formatting block around it):
          {
            "presentation_title": "Title of presentation",
            "slides": [
              {
                "style": "title_slide",
                "title": "Title",
                "content": "Subtitle or content"
              },
              {
                "style": "left_image",
                "title": "Title",
                "content": "- Bullet point 1\\n- Bullet point 2",
                "image": {
                  "prompt": "Description of image",
                  "aspect_ratio": "3:4"
                }
              }
            ]
          }
        PROMPT

        resp = gemini.generate(prompt)
        clean_content = resp[:content].gsub("```json", "").gsub("```", "").strip
        begin
          idea = JSON.parse(clean_content)
        rescue => e
          puts Rainbow("❌ Failed to parse Gemini response inside PowerColon ideation: #{e.message}").red
          # Fallback
          idea = {
            "presentation_title" => topic,
            "slides" => [
              {"style" => "title_slide", "title" => topic, "content" => "Failed to ideate"}
            ]
          }
        end
      end

      @slides = idea["slides"]&.map do |slide|
        s = {}
        slide.each { |k, v| s[k.to_s] = v }
        s
      end || []
    end
  end
end
