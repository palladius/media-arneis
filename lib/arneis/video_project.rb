=begin
Arneis::VideoProject - Implementation of the Video Project template.
=end

require 'yaml'

module Arneis
  class VideoProject
    attr_reader :data, :title, :scenes

    def initialize(yaml_path)
      @data = YAML.load_file(yaml_path)
      validate!
      @title = @data['title']
      @scenes = @data['scenes']
    end

    def validate!
      raise "Invalid YAML: Missing 'title'" unless @data['title']
      raise "Invalid YAML: Missing 'scenes'" unless @data['scenes'].is_a?(Array)
      raise "Invalid YAML: 'scenes' cannot be empty" if @data['scenes'].empty?
    end

    def initialize_output(output_path)
      Dir.mkdir(output_path) unless Dir.exist?(output_path)
      @output_path = output_path
      state_file = File.join(output_path, '.state.yaml')
      initial_state = {
        'status' => 'initialized',
        'project_title' => @title,
        'created_at' => Time.now.to_s,
        'scenes' => @scenes.map { |s| s.merge('status' => 'pending') }
      }
      File.write(state_file, initial_state.to_yaml)
    end

    def process
      orchestrator = Orchestrator.new
      generator = Generator::Mock.new

      @scenes.each do |scene|
        scene_id = "scene_#{scene['scene']}"
        orchestrator.add_task(scene_id) do
          update_scene_status(scene['scene'], 'in_progress')
          generator.generate(scene['description'], File.join(@output_path, "scene_#{scene['scene']}.mp4"))
          update_scene_status(scene['scene'], 'done')
        end
      end

      orchestrator.run
      update_project_status('done')
    end

    private

    def update_scene_status(scene_num, status)
      state_file = File.join(@output_path, '.state.yaml')
      state = YAML.load_file(state_file)
      scene = state['scenes'].find { |s| s['scene'] == scene_num }
      scene['status'] = status if scene
      File.write(state_file, state.to_yaml)
    end

    def update_project_status(status)
      state_file = File.join(@output_path, '.state.yaml')
      state = YAML.load_file(state_file)
      state['status'] = status
      File.write(state_file, state.to_yaml)
    end
  end
end
