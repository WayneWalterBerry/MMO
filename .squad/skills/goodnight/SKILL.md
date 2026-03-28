---
name: "goodnight"
description: "End-of-session shutdown ceremony — newspaper, commit, checkpoint, cleanup"
domain: "squad-operations"
confidence: "high"
source: "manual — Wayne directive 2026-03-26"
---

## Context

When Wayne says "goodnight", "good night", "wrap it up", "end of day", or "closing time", the Coordinator runs this structured shutdown sequence. This is NOT a ceremony (no facilitator needed) — it's a Coordinator-driven sequential pipeline.

**Trigger phrases:** "goodnight", "good night", "wrap it up", "end of day", "closing time", "shut it down", "bedtime"

## Sequence

Execute these steps **in order**. Each step gates the next.

### Step 0 — Wait for In-Flight Agents

Check `list_agents` for any running background agents. If agents are still active:
- Report: `"⏳ Waiting on {N} agents to finish: {names}..."`
- Use `read_agent(wait: true, timeout: 300)` for each
- Collect and present their results normally (compact format)
- If any agent is stuck after 5 minutes, stop it and note what was lost

### Step 1 — Newspaper

Spawn Brockman (background) to write the **Evening Edition** newspaper. Include:
- What the team accomplished this session
- Key decisions made
- What's queued for tomorrow
- The comic strip and op-ed (per standing directive)
- Save to `newspaper/` with today's date

### Step 2 — Commit and Push

Run sequentially:
```
git add -A
git status
```
If there are staged changes:
```
git commit -m "session: {brief summary of session work}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin main
```
If nothing to commit, skip. If on a branch other than main, push to current branch instead.

### Step 3 — Checkpoint

Write a session checkpoint to the session state folder. Include:
- Summary of all work done
- Technical decisions and details
- Important files changed
- Next steps for tomorrow

### Step 4 — Compact Context

Signal to the platform that context should be compacted. This preserves the checkpoint while freeing context window for the next session.

### Step 5 — Nap (MANDATORY — never skip)

**⚠️ This step MUST complete before Step 6. Do NOT skip this step even if the session is closing — the decision inbox MUST be merged every night or the next session starts with stale team memory.**

Run the **nap** skill (`.copilot/skills/nap/SKILL.md`). This handles all context hygiene: compressing histories, pruning logs, archiving decisions, and cleaning orphaned files.

**Wait for nap to complete before proceeding to Step 6.** If nap times out after 5 minutes, report what was lost but still proceed to Step 6.

### Step 6 — Ralph Board Snapshot

Scan GitHub for current state:
- Open issues count + any urgent items
- Open PRs + their status
- Write a brief summary to `.squad/identity/now.md`

Format for `now.md`:
```markdown
# Current Focus

**Last session:** {date}
**Last user:** {name}

## What We Were Working On
{1-3 bullet summary of session focus}

## Board State
- Open issues: {N}
- Open PRs: {N}
- Urgent: {list or "none"}

## Tomorrow's Queue
{What's next, in priority order}
```

### Step 7 — Say Goodnight

After all steps complete, report final status:
```
🌙 Goodnight Wayne!

📰 Evening Edition published
✅ Committed & pushed ({N} files, {branch})
📸 Checkpoint saved
🧹 Decisions cleaned ({before}KB → {after}KB)
📋 Board: {N} issues open, {N} PRs pending

Tomorrow: {1-line summary of what's next}
```

## Patterns

- **Sequential, not parallel.** Each step depends on the previous one completing. Don't fan out.
- **Newspaper first, commit second.** The newspaper is content — it should be in the commit.
- **Board snapshot last.** It captures the true end-of-day state after all work is committed.
- **Don't skip steps on error.** If one step fails, log the error and continue to the next. Report all failures in the final summary.
- **Idempotent.** If "goodnight" is said twice, the second run should be a no-op (nothing to commit, checkpoint already saved, decisions already clean).

## Anti-Patterns

- **Don't run goodnight mid-session.** This is an end-of-day ritual. If Wayne asks for more work after goodnight, treat it as a new session.
- **Don't skip the newspaper.** Brockman writes the Evening Edition every session close — it's Wayne's preferred way to track progress.
- **Don't deep clean if decisions.md is already small.** If under 20KB, skip the archive step.
- **Don't wait forever on stuck agents.** 5-minute timeout, then kill and report.
