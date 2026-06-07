# Specification: Agent Safeguards - Spec Failure Circuit Breaker & Context Warnings

## Overview
Implement safety mechanisms in the Media Harness developer/testing loop to prevent LLM agents from entering endless edit-test death loops and to warn about context bloat.

## Functional Requirements
1. **Spec Failure Circuit Breaker**:
   - If the same spec file is run 3 times consecutively and fails each time without passing, the test runner/harness must trigger a circuit breaker.
   - Upon trigger, the harness must halt execution immediately, print a detailed summary of the failures, and ask for human guidance.
2. **Context Size Warnings**:
   - Monitor the conversation steps count or active log size.
   - If the number of steps in the current conversation transcript exceeds 1000, display a prominent, colored warning in the CLI output alerting the agent/user that they are approaching the token limits and should consider starting a fresh session.
3. **Emergency Auth Resolution**:
   - Explicitly document and ensure that authentication-related failures (e.g., Google OAuth scope denials for Slides or Drive) never trigger autonomous retry attempts; they must immediately halt and prompt the user to run the authentication login command.

## Acceptance Criteria
- Running a spec file 3 times in a row with failures halts the runner and prompts for user feedback.
- CLI outputs a loud warning when steps count exceeds 1000.
- Spec tests pass under the unit-test suite.
