# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Research & analysis | Frink | Deep dives, fact-finding, competitive analysis, technical investigation |
| Documentation | Brockman | READMEs, API docs, guides, changelogs, release notes, onboarding |
| Project management | Chalmers | Scope, priorities, planning, risk, work decomposition, status tracking |
| Scope & priorities | Chalmers | What to build next, trade-offs, decisions |
| Game design | Comic Book Guy | Mechanics, world rules, puzzles, player interactions, object/verb design |
| Architecture & code structure | Bart | Folder structure, module boundaries, engine design, system patterns, code organization |
| Object design & building | Flanders | .lua object files, FSM states, mutate metadata, sensory properties, real-world object simulation |
| Puzzle design & conceptualization | Sideshow Bob | Multi-step puzzles, prerequisite chains, object interaction design, puzzle research |
| Object testing | Lisa | FSM transition verification, mutate field testing, sensory property checks, object-level test reports |
| Room/world design | Moe | Room .lua files, map layouts, environment design, spatial relationships, room documentation |
| UI & text presentation | Smithers | Text output formatting, room description rendering, error messages, help system, player feedback UX |
| Parser pipeline & NLU | Smithers | Parser tiers 1-5, verb recognition, noun resolution, disambiguation, GOAP UX, command parsing |
| Web builds & deploys | Gil | Build pipeline, GitHub Pages deploy, web/index.html, bootstrapper.js, game-adapter.lua, browser bugs |
| Linting & code quality | Wiggum | meta-lint rules, mutation-edge-check, lint.py, wrapper scripts, CI lint steps, lint config, rule registry |
| Code review | Chalmers | Review PRs, check quality, suggest improvements |
| Async issue work (bugs, tests, small features) | @copilot 🤖 | Well-defined tasks matching capability profile |
| Session logging | Scribe | Automatic — never needs routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, evaluate @copilot fit, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up issue and complete the work | Named member |
| `squad:copilot` | Assign to @copilot for autonomous work (if enabled) | @copilot 🤖 |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, evaluating @copilot's capability profile, assigning the right `squad:{member}` label, and commenting with triage notes.
2. **@copilot evaluation:** The Lead checks if the issue matches @copilot's capability profile (🟢 good fit / 🟡 needs review / 🔴 not suitable). If it's a good fit, the Lead may route to `squad:copilot` instead of a squad member.
3. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
4. When `squad:copilot` is applied and auto-assign is enabled, `@copilot` is assigned on the issue and picks it up autonomously.
5. Members can reassign by removing their label and adding another member's label.
6. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

### Lead Triage Guidance for @copilot

When triaging, the Lead should ask:

1. **Is this well-defined?** Clear title, reproduction steps or acceptance criteria, bounded scope → likely 🟢
2. **Does it follow existing patterns?** Adding a test, fixing a known bug, updating a dependency → likely 🟢
3. **Does it need design judgment?** Architecture, API design, UX decisions → likely 🔴
4. **Is it security-sensitive?** Auth, encryption, access control → always 🔴
5. **Is it medium complexity with specs?** Feature with clear requirements, refactoring with tests → likely 🟡

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
8. **@copilot routing** — when evaluating issues, check @copilot's capability profile in `team.md`. Route 🟢 good-fit tasks to `squad:copilot`. Flag 🟡 needs-review tasks for PR review. Keep 🔴 not-suitable tasks with squad members.

## Swimlane Architecture

**Swimlanes are enforceable queues, not visualizations.** Each swimlane represents an agent's work queue and maps directly to a `squad:{member}` label on GitHub Issues.

### Core Model

- **One swimlane = one owning agent** — single-agent ownership is mandatory. No shared swimlanes or cross-owner lanes.
- **Labels are swimming** — when an issue gets a `squad:{member}` label, it **appears in that agent's swimlane** and enters their queue.
- **Golden loop:** Issue created → labeled (`squad:{member}`) → appears in swimlane → agent pulls → works in worktree → PR created → PR merged → card moves to Done → status emitted

### Swimlane States

- **Backlog** — issues waiting to be triaged (have `squad` label, no member assigned)
- **Ready** — issues with `squad:{member}` label, waiting for agent to pull
- **In Progress** — agent is working (PR open, linked to issue)
- **Review** — PR open, awaiting code review or QA sign-off
- **Blocked / Needs Human** — agent cannot proceed; requires human input or action. See **Blocked Lane Protocol** below.
- **Done** — PR merged, issue closed

### Blocked Lane Protocol

When an agent cannot proceed on an issue:

1. **Move the issue to "Blocked / Needs Human"** (use a GitHub project board or label: `blocked`)
2. **Emit status:** In the issue, post a comment with:
   - **What is blocked:** The specific task or step
   - **Why it's blocked:** The root cause or blocker
   - **What input is needed:** Exactly what decision/data/review is required
   - **Who needs to act:** Name the decision-maker or reviewer
3. **Agent waits:** The agent does not continue work until the blocker is resolved and the issue is moved out of the blocked lane

**Example:**
```
@wayne — This is blocked on D-DOOR-DESIGN. We need to decide:
1. Should doors auto-open or require UNLOCK + OPEN verbs?
2. What's the locked state initial value for each door?

Moved to Blocked / Needs Human. Waiting on game design review.
```

### Ralph's Role (Work Monitor)

Ralph monitors swimlanes and detects stalled work but **respects agent autonomy**:

- **Monitor:** Ralph watches for issues that have been in "Ready" for > N days without being picked up
- **Spawn:** If an agent hasn't picked up their work, Ralph can spawn the agent to review and pull issues
- **Respect autonomy:** Ralph does NOT spawn if the agent already has a PR open or is actively working (in "In Progress" lane). No double-spawning.
- **Escalate if needed:** If the agent still doesn't respond after spawn, Ralph flags for Lead review (not for manual card dragging)

### Human Boundaries

**Humans define the system; Squad executes it:**

- **Humans define:** Lane names, swimlane groupings (workstream/owner/priority), issue triggers, review criteria
- **Squad moves:** Cards/issues between lanes, updates status fields, closes loops (merges PRs, closes issues)
- **Anti-pattern:** Humans manually dragging cards without automation. Humans should not be the execution layer.

### Anti-Patterns

❌ **Mixing agent responsibilities in the same lane** — Each lane should route to ONE agent. If two agents need to work on it, create TWO linked issues with separate swimlanes.

❌ **Using swimlanes as passive visualization** — Swimlanes are the control mechanism. Labels + swimlanes drive work; swimlanes are not just a view of work.

❌ **Humans dragging cards manually** — If the system requires manual card dragging, the system design is broken. Automation (labels, GitHub Actions, Ralph) should move cards.

❌ **Pending state without clarity** — "Pending" with no context is a dead lane. Use "Blocked / Needs Human" with emitted status instead.
