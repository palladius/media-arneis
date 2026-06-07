# 🔍 Claude Investigation: Agent Death Loop (2026-06-07)

**Conversation**: `fd2e8d8d-4c5c-4c95-94ff-99c4e58e4952`
**GitHub Issue**: [#16](https://github.com/palladius/media-arneis/issues/16)
**Investigated by**: Claude Opus 4 (Thinking) in conversation `edda02e8-2951-40b7-b2e6-9991f699ff13`

---

## 🚨 The BIG Issue

**`just test` invokes real LLM calls.** The agent ran `just test` **19 times** and
`google_slides_exporter_spec.rb` **9 times**, each time hitting live Gemini/Imagen APIs.
This is not a fast local unit test suite — it's an expensive, slow, non-deterministic
integration test masquerading as a quick feedback loop.

The agent treated `just test` as a cheap "did my edit work?" check and looped on it
endlessly. **Every loop iteration burned real API calls and tokens.**

> **Fix in progress**: A branch is currently being worked on to decouple fast unit tests
> (mocked, <5s) from integration tests (real LLM calls). This is the #1 priority fix.

---

## 📊 Raw Data

### Error Log (all 8 errors in conversation)

| Step | Timestamp (UTC) | Error Type | Detail |
|---|---|---|---|
| 60 | 2026-06-06 15:53:47 | Invalid artifact path | Tried to write outside artifact dir |
| 96 | 2026-06-06 15:54:59 | Invalid tool args | `StartLine (1) > EndLine (0)` |
| 108 | 2026-06-06 15:55:09 | Invalid tool args | `StartLine (40) > EndLine (0)` |
| 214 | 2026-06-06 16:00:09 | Malformed function call | Empty function call body |
| 869 | 2026-06-06 22:08:12 | Invalid tool args | `StartLine (140) > EndLine (0)` |
| 881 | 2026-06-06 22:08:19 | File not found | `/home/riccardo/git/media-arneis/justfile` (wrong path — worktree!) |
| 1171 | 2026-06-07 06:54:36 | File not found | `lib/arneis/hydrator.rb` (wrong path) |
| **1866** | **2026-06-07 10:58:16** | **Max tokens (65536)** | **💥 Conversation killed** |

### All `just test` Runs (19 total — each hitting real LLM APIs!)

| # | Step | Timestamp (UTC) | Phase |
|---|---|---|---|
| 1 | 237 | 2026-06-06 16:00:42 | Initial dev |
| 2 | 388 | 2026-06-06 16:06:51 | Initial dev |
| 3 | 498 | 2026-06-06 17:14:41 | Pre-user-departure |
| 4 | 560 | 2026-06-06 17:16:22 | Pre-user-departure |
| 5 | 572 | 2026-06-06 17:17:06 | Pre-user-departure |
| 6 | 596 | 2026-06-06 21:53:24 | Overnight autonomous |
| 7 | 664 | 2026-06-06 21:55:05 | Overnight autonomous |
| 8 | 682 | 2026-06-06 21:58:17 | Overnight autonomous |
| 9 | 762 | 2026-06-06 22:04:12 | Overnight autonomous |
| 10 | 1312 | 2026-06-07 06:57:29 | Morning |
| 11 | 1373 | 2026-06-07 06:59:14 | Morning |
| 12 | 1446 | 2026-06-07 07:56:21 | Morning |
| 13 | 1544 | 2026-06-07 08:07:35 | Morning |
| 14 | 1578 | 2026-06-07 10:31:07 | **Death loop begins** |
| 15 | 1629 | 2026-06-07 10:33:19 | Death loop |
| 16 | 1640 | 2026-06-07 10:33:42 | Death loop |
| 17 | 1664 | 2026-06-07 10:35:33 | Death loop |
| 18 | 1797 | 2026-06-07 10:49:56 | Death loop |
| 19 | 1863 | 2026-06-07 10:51:31 | Death loop — last run before crash |

### The Spec File Death Loop (9 runs in ~2 minutes)

| # | Step | Timestamp (UTC) | Gap from previous |
|---|---|---|---|
| 1 | 1703 | 10:36:50 | — |
| 2 | 1711 | 10:37:08 | 18s |
| 3 | 1729 | 10:37:25 | 17s |
| 4 | 1747 | 10:37:40 | 15s |
| 5 | 1753 | 10:37:45 | 5s |
| 6 | 1763 | 10:37:55 | 10s |
| 7 | 1771 | 10:38:06 | 11s |
| 8 | 1837 | 10:51:05 | 13 min (edited code in between) |
| 9 | 1843 | 10:51:11 | 6s |

### File Churn (steps 1600–1866)

| File | Times touched | Operations |
|---|---|---|
| `google_slides_exporter_spec.rb` | 17 | view + replace loops |
| `power_colon.rb` | 11 | view + replace loops |
| `google_slides_exporter.rb` | 8 | view + replace loops |
| `arneis.rb` | 5 | edits |
| `plan.md` | 4 | updates |
| `power_colon_spec.rb` | 4 | edits |
| `google_auth_manager_spec.rb` | 3 | edits |
| `google_auth_manager.rb` | 3 | edits |
| `Justfile` | 3 | edits |

### Lost Steps

Steps **1876–1882** (7 steps) are missing from the transcript. The step index jumps
from 1875 (`VIEW_FILE` on `.env` at 10:58:41 UTC) directly to 1883 (`USER_INPUT` at
16:17:50 UTC — a **5 hour 19 minute gap**). Whatever the model attempted during those
7 steps was not persisted.

---

## 🧠 Analysis: Why the Agent Went Crazy

### Primary Cause: `just test` = real LLM calls

The agent's edit→test→edit→test loop would be _normal_ behavior if tests were fast
and deterministic. But `just test` hits live Gemini/Imagen APIs, which means:

1. **Each run is expensive** — burns API quota and tokens
2. **Each run is slow** — image generation takes 10-15s per call
3. **Each run is non-deterministic** — LLM outputs vary, so the same test can
   pass/fail for reasons unrelated to the code change
4. **Test output is huge** — LLM responses bloat the conversation context

The agent couldn't distinguish "my code is wrong" from "the LLM returned something
slightly different this time." So it kept editing and retrying.

### Secondary Cause: No circuit breaker

There was no mechanism to say "I've run this spec 7 times in 2 minutes and it's still
failing — I should stop and ask the human." The agent just kept going.

### Tertiary Cause: Autonomous auth attempts

The `PERMISSION_DENIED` error for Google Slides was a legitimate issue, but the agent
spent ~100+ steps trying to probe/fix credentials instead of immediately asking the
user to run `gcloud auth application-default login`.

### Contributing Factor: 19-hour session

1888 steps over 19 hours with no fresh conversation. Context accumulated until the
65K output token limit was breached.

---

## ⏱️ Full Timeline

```
Jun 6 17:53 CEST  — Session started (Gemini 3.5 Flash model)
Jun 6 19:15 CEST  — User: "going out, proceed in autonomy"
Jun 6 23:53-00:09 — Overnight: 4 runs of `just test`, file edits, commits
Jun 7 00:04 CEST  — User: "keep working, wife is in other room"
Jun 7 00:08-00:10  — 5 more background task runs (overnight work continues)
Jun 7 08:53 CEST  — User returns, runs /conductor:plan
Jun 7 10:31 CEST  — Death loop BEGINS: rapid test/edit cycles
Jun 7 10:36-10:38  — PEAK INSANITY: 9 spec runs in 2 minutes
Jun 7 10:49-10:51  — Second wave: more edit/test/edit cycles
Jun 7 12:58 CEST  — 💥 MAX TOKENS CRASH (step 1866)
Jun 7 12:58 CEST  — 7 steps LOST (1876-1882)
Jun 7 18:17 CEST  — User: "stop authenticating, ask ME to do it"
Jun 7 18:18 CEST  — Checkpoint 5: full context truncation
Jun 7 18:18 CEST  — User: "whats up?" — switched model to Gemini 3.1 Pro
```

---

## ✅ Code Status (Despite Everything)

- **101 tests passing** (`just test`)
- `GoogleSlidesExporter` implemented and integrated into `PowerColon`
- State persistence (`.state.yaml`) for update-in-place
- Branch: `202606-google-slides-export`
- Remaining: OAuth scopes for Google Slides/Drive API

---

## 💡 Action Items

- [x] **#1 PRIORITY — DONE** ✅ (merged to main as `1070352`): `just test` now points to
      `just unit-test` (mocked, <3s). Real API tests under `just integration-test`.
      Key commits: `674db24` (mock all generators), `578ab04` (LLM-as-judge integration suite).
- [ ] Add agent instructions: "Never run `just test` more than 3x in a row without
      stopping to report"
- [ ] Add agent instructions: "Never attempt authentication changes — always ask user"
- [ ] Break long sessions at ~500-1000 steps
- [ ] Run: `gcloud auth application-default login --scopes=https://www.googleapis.com/auth/presentations,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/cloud-platform`
