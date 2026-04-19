# 📖 Arneis User Manual

Welcome to the **Arneis (Media Harness)** User Manual. Arneis is a powerful orchestration tool designed to bridge the gap between high-level creative vision and low-level AI media generation. 

Inspired by `kubectl`, Arneis allows you to manage complex media projects using a declarative YAML-based approach.

## 🚀 What Arneis Can Do

Arneis orchestrates Google's state-of-the-art AI models to generate complex multi-part media artifacts:

- **Video Projects**: Create multi-scene videos with synchronized background music, narration, and high-quality video clips using **Veo**.
- **Kids Stories**: Generate illustrated stories with character consistency across chapters.
- **Comic Strips**: Build panel-by-panel comic narratives with consistent visual styles.
- **Parallel Execution**: Leverage Ruby Fibers to run multiple generation tasks (video, audio, images) in parallel, significantly reducing total production time.
- **Dependency Management**: Automatically resolve dependencies (e.g., generate the script before the video, and the video before the final montage).
- **Cost & Token Tracking**: Monitor your usage and expenditure in real-time.

---

## 🏗️ Supported Project Templates (CUJs)

Arneis uses a template-based system to handle different Critical User Journeys (CUJs). Each template defines its own orchestration logic and artifact requirements.

| Template | Description | Status |
| :--- | :--- | :--- |
| **VideoProject** | Multi-scene video with background music and montage. | ✅ **Done** |
| **KidsStory** | Illustrated storybook with character consistency. | 🏗️ **WIP** |
| **ComicStrip** (Fumetto) | Panel-by-panel comic narratives. | 🏗️ **WIP** |

---

## 💻 Sample CLI Invocations

Arneis is primarily interacted with via the `arnectl` command. For convenience, a `Justfile` is provided to wrap these commands.

### 1. Research & Ideation
Start by providing a raw research document or a simple prompt to generate a structured project specification.
```bash
just arnectl research-pitch data/samples/rubycon_research.md
```

### 2. Applying a Specification
Once you have a `.yaml` specification, "apply" it to start the generation process. This will create a project directory under `out/` and begin parallel execution of all tasks.
```bash
just arnectl apply data/samples/rubycon_sales_pitch.yaml
```

### 3. Checking Project Status
Monitor the progress of a running project. Arneis provides a rich, emoji-based status view.
```bash
just arnectl status out/20260418_225308_rubycon_sales_pitch/
```

### 4. Visualizing Dependencies
Generate a Mermaid.js dependency graph to understand how your project parts relate to each other.
```bash
just arnectl graph data/samples/rubycon_sales_pitch.yaml
```

### 5. Verification
Verify that all generated artifacts meet the required specifications (duration, format, etc.).
```bash
just arnectl verify out/latest_project/
```

---

## 🎬 How Video Creation Works

Video creation in Arneis is handled by the `VideoProject` class. It follows a structured pipeline:

1. **Specification**: You define a `VideoProject` YAML with a title, background music prompt, and a list of scenes.
2. **Decomposition**: Arneis breaks the project into atomic tasks:
   - **Background Music**: One task to generate the full-length track using **Lyria**.
   - **Scenes**: For each scene, Arneis generates:
     - An expanded visual prompt using **Gemini**.
     - A video clip using **Veo**.
     - (Optional) Narration audio using **Chirp** or **Gemini TTS**.
3. **Parallel Orchestration**: Tasks are executed in parallel where possible. For example, all 4 scenes and the background music can be generated simultaneously.
4. **Assembly**: Once all clips and audio are ready, Arneis uses standard tools (like `ffmpeg`) to assemble the final montage, overlaying music and stitching scenes together.
5. **Feedback Loop**: You can provide feedback on specific scenes to trigger a regeneration of just that part.

---

## 🔄 Resilience and Resuming

Arneis is designed for long-running media generation tasks. 

- **State Persistence**: Every project maintains a `.state.yaml` file in its output directory. This tracks the status of every task and artifact.
- **Stop & Resume**: You can safely stop the `arnectl` process (e.g., `Ctrl+C`) at any time. When you run `just arnectl apply` again on the same specification, Arneis will intelligently skip already-completed tasks and resume only what's missing or in progress.
- **Quiescence**: When stopping, Arneis attempts to reach a "quiescent" state, though some external AI calls (like Veo) may continue to process on the server side until their receipts are eventually checked.

---

## ⚖️ Automated Evaluations (EVALs)

Quality control is built directly into the orchestration loop. Arneis doesn't just generate media; it *judges* it.

- **The LLM-as-a-Judge**: After a video or image is generated, Arneis invokes a "Critic" model (typically Gemini 1.5 Pro or Flash) to evaluate the artifact against the original prompt.
- **Scoring**: Each artifact receives a score (e.g., ⭐ 9/10) and a qualitative assessment (👍 or 👎).
- **Automated Rejection**: If an artifact fails to meet a certain quality threshold (e.g., score < 5), it is marked as `⚖️ Needs Review` in the status output.
- **Custom Evals**: You can define custom evaluation criteria in your YAML specification to check for specific elements (e.g., "Ensure the brand logo is visible in the top right corner").

---

## 📊 Understanding the Status Output

When you run `arnectl status`, you get a comprehensive overview of your project's health:

```text
🔍 Checking status of out/20260418_225308_rubycon_sales_pitch/
Project: Rubycon 2026: Code, Community, and the Italian Coast
Status: 🟡 in_progress | Auth: ☁️ (Vertex)

Scenes:
  🟢 🎥 👍 Scene 1: Cinematic drone shot sweeping across the Rimini seafront at golden hour... (⭐ 9/10)
  🟢 🎥 👍 Scene 2: Close-up of a high-resolution laptop screen displaying elegant Ruby code... (⭐ 9/10)
  🟢 🎥 👍 Scene 3: Professional networking scene at a tech conference. Ruby developers... (⭐ 9/10) 🤡
  ⚖️  🎥 👎 Scene 4: A peaceful sunrise over the historic Rubicon river... (⭐ 4/10)

Project Tasks:
  🟢 🎵 Background Music 🤡
  ⚪ 🎞️  Final Montage

📊 Stats: 🪙 71281 (⬆️ 370 ⬇️ 911) | 💸 $16.01
```

### Legend:
- **Status Emojis**:
  - 🟢 **Done**: Artifact generated and verified.
  - 🟡 **In Progress**: Generation currently running.
  - ⚪ **Pending**: Waiting for dependencies or not yet started.
  - ⚖️ **Needs Review**: Artifact generated but scored poorly by automated evals.
- **Type Emojis**:
  - 🎥 Video Clip
  - 🎵 Audio/Music
  - 🎞️ Final Assembly
- **Evaluations**:
  - 👍 / 👎: Automated quality assessment.
  - ⭐ **X/10**: Quality score assigned by Gemini.
- **Stats**:
  - 🪙 **Total Tokens**: Input (⬆️) and Output (⬇️).
  - 💸 **Estimated Cost**: Calculated based on model pricing.
