# Implementation Plan: Integrate Google AI Models for real media generation

## Phase 1: Infrastructure & Configuration
- [ ] Task: Set up `dotenv` gem to load environment variables.
- [ ] Task: Create a central configuration class for API keys.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Gemini & Text Generation
- [ ] Task: Implement `Arneis::Generator::Gemini` using `ruby_llm`.
- [ ] Task: Update `VideoProject` to use Gemini for scene descriptions/text.
- [ ] Task: Verify Gemini integration with a small test script.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Real Media Generators (Veo, Lyria, Chirp)
- [ ] Task: Implement `Arneis::Generator::Veo` for video generation.
- [ ] Task: Implement `Arneis::Generator::Lyria` and `Arneis::Generator::Chirp`.
- [ ] Task: Update the `Orchestrator` to handle real API latencies.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Resource Tracking & Stats
- [ ] Task: Implement token and cost logging in the state file.
- [ ] Task: Update `arnectl stats` to report real usage metrics.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
