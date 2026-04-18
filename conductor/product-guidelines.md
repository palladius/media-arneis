# Product Guidelines: Media Harness (Arneis)

## Tone & Voice
- **Playful & Enthusiastic:** The CLI and UI should feel "alive" and celebratory. Use emojis liberally to signify status, milestones, and successes (e.g., 🟢, 🚀, 🎨, 🎞️).
- **Clear but Informal:** While technical details are important, the language should be accessible to a "Media Creator" who may not be a deep software engineer.

## Branding & Naming
- **Primary Name:** **Arneis** (the soul of the project).
- **Functional Name:** **Media Harness**.
- **CLI Command:** **`arnectl`** (inspired by `kubectl`).
- **Identity:** A blend of technical precision ("Harness") and creative potential ("Arneis" / wine-inspired richness).

## User Experience (UX) Principles
- **Visual "Alive" Feedback:** Provide real-time, colorful progress updates. Use dependency mapping to show what's waiting on what (e.g., using arrows or indented tree views).
- **Technical Transparency:** Always provide the "why" behind the "what". Include token counts, execution times, and cost estimates for every generation.
- **Low Latency Interaction:** Status checks should be sub-second ("Larry-Sergey latency").
- **Seamless Asynchronicity:** The user should feel that the system is working hard in the background without blocking their flow.

## Error Handling & Recovery
- **Guardrailed Auto-Correction:** When a generation fails or is malformed, the system should attempt an automated fix using an LLM based on guardrailed EVALs.
- **Max Retry Policy:** The system should attempt this auto-correction a maximum of **3 times**.
- **Escalation Protocol:** If all 3 retry attempts fail, the system should prompt the user with: **"I tried everything, now you tell me!"**
- **Non-Destructive Failures:** Never delete failed work. Archive problematic artifacts to `.trash/` with a timestamp and a "reason" log.
- **Cascading Awareness:** If a parent task fails or is archived, all dependent tasks must be automatically marked as "unready" or "archived" to maintain consistency.

## Visual Identity
- **Status Indicators:**
  - 🟢 **Done:** Task successfully completed.
  - 🟡 **In Progress:** Model currently generating media.
  - ⚪ **Ready:** Dependencies met, waiting for execution.
  - 🩶 **Waiting:** Dependent on another task.
  - 🔴 **Failed:** Error encountered (and auto-correction exhausted).
- **Progress Bars:** Use colorful, text-based progress bars for long-running tasks like video generation.
