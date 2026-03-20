### 2026-03-19T23:58:27Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Nelson must write his test-pass output file incrementally AS HE PLAYS -- not just at the end. Each command/response pair gets appended to the file immediately. This way if the session crashes or times out, the transcript so far is preserved. Write to test-pass/YYYY-MM-DD-pass-NNN.md and append after each interaction.
**Why:** User request -- if Nelson's session dies mid-play, you lose the whole transcript. Streaming to file preserves progress.
