
A more complex version of  ~/git/gemini-cli-demos/demos/mcp-video-creation
* BDD: https://docs.google.com/document/d/14dIZF1yAcDUzgVtKoSq9ZuEEsvwXA-JcdUEwxHWynOY/edit?tab=t.0

* implement with GC + Conductor

## Usage

```bash
# Research a project and generate a pitch YAML
just arnectl research-pitch data/samples/rubycon_research.md

# Apply a media plan
just arnectl apply data/samples/rubycon_sales_pitch.yaml

# Check status
just arnectl status out/latest_folder

# Generate a dependency graph (Mermaid.js)
just arnectl graph data/samples/rubycon_sales_pitch.yaml
```
