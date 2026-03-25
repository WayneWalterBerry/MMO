### 2026-03-25T15:00:00Z: D-SWIMLANE-SQUAD-ARCHITECTURE Implementation

**By:** Bart (Architecture Lead)  
**Scope:** Squad operational model — swimlanes as enforceable queues  
**Status:** Implemented  
**Affects:** routing.md, Ralph (work monitor), all agents

---

## Decision Summary

Swimlanes are the Squad's operational contract. They are **enforceable queues, not visualizations**. Each swimlane is owned by exactly one agent, maps to a `squad:{member}` label, and drives work autonomously through the golden loop: Issue → labeled → swimlane → agent pulls → works → PR → Done.

---

## D-BLOCKED-SWIMLANE: Blocked/Needs Human Lane Definition

**What:** Issues that cannot proceed without human action (design decision, code review, input data) move to a "Blocked / Needs Human" lane with mandatory status emission.

**How:**
1. Agent identifies a blocker (missing decision, design conflict, data required)
2. Agent moves issue to blocked lane (use GitHub project board or `blocked` label)
3. Agent emits status in issue comment:
   - **What is blocked** — specific task or step
   - **Why** — root cause of blocker
   - **What is needed** — exact input, decision, or data required
   - **Who acts** — name the decision-maker or reviewer
4. Agent does not continue work until blocker is resolved

**Why this matters:**
- Prevents ambiguous "pending" states with no context
- Makes blockers visible and actionable
- Creates accountability: someone knows they own the unblock
- Agents can move on to other work in the meantime

**Example Status Emission:**
```
@wayne — Issue blocked on D-DOOR-DESIGN. Need game design decision:
1. Should locked doors require UNLOCK before OPEN, or use single verb?
2. What's the initial locked state for cellar_door?

Moved to Blocked/Needs Human. Awaiting design review before proceeding.
```

---

## D-RALPH-PULL-INTEGRATION: Ralph Monitors but Respects Autonomy

**What:** Ralph (work monitor) watches for stalled work in swimlanes but does NOT double-spawn agents already actively working.

**Rules:**
1. **Monitor:** Ralph detects when issues have been in "Ready" lane > N days without agent pickup
2. **Spawn:** Ralph can spawn the agent to review and pull their swimlane
3. **Respect autonomy:** Ralph checks for active PRs or "In Progress" status before spawning
4. **No double-spawn:** If the agent already has work in progress, Ralph does not spawn
5. **Escalate:** If agent doesn't respond after spawn, Ralph flags for Lead review (never manual card dragging)

**Why this matters:**
- Prevents agent queue overflow/pile-up
- Avoids redundant spawns that waste compute and confuse work tracking
- Keeps agents autonomous while ensuring no work falls through cracks

**Implementation Notes:**
- Ralph queries GitHub project board or label states to detect swimlane status
- Ralph checks `linked PR` field or branch patterns to detect active work
- Spawn only if: ready > N days AND no active PR AND not in "In Progress"

---

## D-HUMAN-BOARD-BOUNDARIES: Humans Define, Squad Executes

**What:** Humans (Wayne, Leads) define the swimlane system structure and review gates. Squad agents execute movement and closure of work.

**Human responsibilities:**
- Define swimlane names and groupings (workstream, priority, owner)
- Set review criteria and quality gates
- Triage issues and assign `squad:{member}` labels
- Unblock agents (make design decisions, provide data, approve PRs)
- Close decision loops (merge PRs, close issues)

**Squad responsibilities:**
- Move cards between lanes (automated by labels and GitHub Actions)
- Pull work from Ready lane, move to In Progress
- Open PRs, move to Review lane
- Move to Blocked/Needs Human with status emission (agent-initiated)
- Move to Done upon PR merge (GitHub Actions automated)
- Emit status updates for visibility

**Anti-patterns to prevent:**
- ❌ Humans manually dragging cards (except for triage and review gates)
- ❌ Squad agents bypassing swimlane protocol
- ❌ Swimlanes used as passive visualization instead of control mechanism
- ❌ "Pending" states without clarity or human contact

**Why this matters:**
- Clear separation of concerns: design vs. execution
- Humans stay focused on decisions, not logistics
- Squad (agents + automation) becomes reliable and scalable
- System is auditable: every card movement is traceable to automation or decision

---

## Implementation Checklist

- [x] Update `routing.md` with Swimlane Architecture section
- [x] Document Blocked Lane Protocol
- [x] Document Ralph's monitoring rules
- [x] Document human boundaries and anti-patterns
- [ ] Configure GitHub project board swimlanes (Lead task)
- [ ] Set up GitHub Actions for automated card movement (Lead task)
- [ ] Brief Ralph on autonomy rules (Lead task)
- [ ] Brief all agents on swimlane protocol (Lead task)

