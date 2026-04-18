
A more complex version of  ~/git/gemini-cli-demos/demos/mcp-video-creation
* BDD: https://docs.google.com/document/d/14dIZF1yAcDUzgVtKoSq9ZuEEsvwXA-JcdUEwxHWynOY/edit?tab=t.0

* implement with GC + Conductor

## Usage

```bash
# Apply a media plan
just arnectl apply rubycon_pitch.yaml

# Check status
just arnectl status out/latest_folder

# Generate a dependency graph (Mermaid.js)
just arnectl graph rubycon_pitch.yaml
```
