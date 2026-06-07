require "spec_helper"
require "yaml"

RSpec.describe "Documentation version consistency" do
  let(:version_file_path) { File.expand_path("../../VERSION", __dir__) }
  let(:user_manual_path) { File.expand_path("../../docs/USER MANUAL.md", __dir__) }
  let(:skill_path) { File.expand_path("../../docs/skills/how-to-use-media-arneis/SKILL.md", __dir__) }

  let(:expected_version) { File.read(version_file_path).strip }

  it "defines version correctly in USER MANUAL.md" do
    expect(File.exist?(user_manual_path)).to be(true), "USER MANUAL.md not found at #{user_manual_path}"
    manual_content = File.read(user_manual_path)
    # Check if the version line exists and matches
    # e.g., "**Arneis (Media Harness) Version: 0.2.6**"
    expect(manual_content).to include("Version: #{expected_version}"), "USER MANUAL.md version does not match VERSION file content ('#{expected_version}')"
  end

  it "defines version correctly in SKILL.md frontmatter" do
    expect(File.exist?(skill_path)).to be(true), "SKILL.md not found at #{skill_path}"
    skill_content = File.read(skill_path)
    
    # Parse YAML frontmatter
    frontmatter = if skill_content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
      begin
        YAML.safe_load($1)
      rescue => e
        nil
      end
    end

    expect(frontmatter).not_to be_nil, "Could not parse YAML frontmatter in SKILL.md"
    expect(frontmatter["version"].to_s).to eq(expected_version), "SKILL.md frontmatter version ('#{frontmatter["version"]}') does not match VERSION file ('#{expected_version}')"
  end
end
