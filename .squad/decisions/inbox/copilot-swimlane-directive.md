### 2026-03-25T14:52:00Z: D-SWIMLANE-SQUAD-ARCHITECTURE
**By:** Wayne Berry (via Copilot)
**Scope:** Squad operational model — swimlanes as enforceable queues

**Core Principle:** Swimlanes are the contract. Squad is the executor.

**Rules:**
1. **GitHub swimlanes define what work exists and how it's partitioned** — Squad agents pull from those lanes and execute autonomously
2. **One swimlane = one owning agent** — single-agent ownership is mandatory, shared ownership is not allowed
3. **Drive Squad with labels + swimlanes, not free-text prompts** — labels map 1:1 to agent queues (squad:{member})
4. **'Pending' is not a valid state** — use a 'Blocked / Needs Human' swimlane for stuck items with status emission
5. **Squad updates the board, humans don't micromanage** — humans define lanes/triggers/review; Squad moves cards/updates fields/closes loops
6. **Worktrees + lanes for parallelism safety** — swimlanes = logical isolation (what agents should touch), worktrees = physical isolation (what agents can touch)
7. **Golden loop:** Issue created → labeled → appears in swimlane → agent pulls → works in worktree → PR created → card moves to Done → status emitted

**Swimlane groupings:** Workstream, Owner, Repository, Priority (not ephemeral fields)
**Anti-patterns:** Mixing agent responsibilities in same lane, using swimlanes as visualization instead of control, humans dragging cards manually

**Affects:** All agents, Ralph (work monitor), routing.md, team.md