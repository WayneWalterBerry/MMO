# Decision Memo: Player Skills System Architecture

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-21  
**Decision Level:** 1 (Design-level, ready for implementation review)  
**Status:** Proposed (awaiting team consensus)  
**Related:** `docs/design/player-skills.md` (full design), `design-directives.md` (earlier sketches)

---

## The Question

**How should player skills be modeled, acquired, and integrated with the verb system to create emergent gameplay while respecting the dark, tactile aesthetic?**

---

## Our Answer

**Binary skills model with discovery-based acquisition, integrated as a second gate in verb handler dispatch.**

---

## Key Design Decisions Ratified

### 1. Binary Skills (Have / Don't Have) in V1

```lua
player.skills = {
  lockpicking = false,  -- Player cannot PICK LOCK yet
  sewing = false,       -- Player cannot SEW yet
}
```

**Rationale:** Simplicity + discovery. Skills are milestones, not XP bars. When the player reads the lockpicking manual or practices packing enough times, the skill becomes available. Future proficiency levels are designed but not implemented until V2.

**Impact:** Simpler code, clearer UX. Players understand: "I can do this now because I learned."

---

### 2. Skills Unlock Alternatives, Not Replacements

A pin can **always** be used to prick and draw blood (no skill required). With lockpicking skill, it **also** picks locks.

```lua
-- Without skill:
PRICK SELF WITH pin → blood (works)
PICK LOCK WITH pin → [BLOCKED] "You don't know how to pick locks."

-- With skill:
PRICK SELF WITH pin → blood (still works)
PICK LOCK WITH pin → lock opens (now works)
```

**Rationale:** Respects player agency. No puzzle becomes unsolvable without a skill. Skills accelerate, don't gatekeep.

**Impact:** Puzzle design is less constrained. Every room has a no-skill path.

---

### 3. Skill + Tool + Verb Gating (Double Dispatch)

Verb handlers enforce two requirements in series:

```lua
-- Pseudo-code for PICK LOCK handler:
if not player.skills.lockpicking then
  return "[BLOCKED] You don't know how to pick locks."
end

if not tool.provides_tool or tool.provides_tool ~= "lockpick" then
  return "[BLOCKED] The pin is not suitable for picking locks."
end

-- Both gates pass → action allowed
```

**Rationale:** Separation of concerns. Skill system is orthogonal to tool capability system. Either gate can fail independently.

**Impact:** Engine code remains simple. Tool designer doesn't need to know about skill system; they define `requires_tool`. Skill designer doesn't need to know about tools; they define gate conditions.

---

### 4. Failure Has Consumable Consequences

When a player attempts a skilled action without the skill OR with low proficiency, the tool is consumed:

- **Failed lock pick:** Pin bends (bent-pin.lua created). Player must find another pin to retry.
- **Failed sewing:** Thread tangles (tangled-mess.lua created). Player must find new thread and needle.

**Rationale:** Teaches design language through play. Resources are finite. Consequences are real.

**Impact:** Players think twice before acting. Natural pacing: can't spam PICK LOCK 100 times.

---

### 5. Blood Writing Is Transgressive and Costly

```
PRICK SELF WITH pin
→ Player loses 5 HP
→ Blood object created (time-limited, ~5 game-minutes)
→ WRITE "text" ON paper WITH blood
→ Paper becomes permanent, visceral (paper-with-blood-writing.lua)
```

**Rationale:** Embodies the dark, tactile tone. Blood is not a convenience—it's a desperate measure. Health cost + resource limit + permanence all teach: "This matters."

**Impact:** Writing in blood feels transgressive (by design). Creates memorable moments. Teaches that player actions are recorded and consequential.

---

### 6. Paper Mutations Are File-Per-State

When the player writes on paper, the engine creates `paper-with-writing.lua` (or mutates in-place, team decides):

```lua
{
  id = "paper",
  name = "a sheet of paper with writing",
  written_text = "player's text here",
  written_with = "ink",  -- or "pencil" or "blood"
  on_look = function(self)
    return "A sheet of paper. The writing reads:\n\n  \"" .. self.written_text .. "\""
  end,
}
```

**Rationale:** Code-as-state. Player text is embedded in object definition. Persists across saves. Designer can inspect player-authored papers.

**Impact:** Supports future features (ERASE verb for pencil, searching for blood-written papers, etc.). Player creations are first-class objects.

---

### 7. Skill Discovery Is Multi-Path, Not Gated by Progression

Four acquisition methods:
1. **Find & Read:** Lockpicking Manual in library
2. **Practice:** Use pin to prick self multiple times
3. **NPC Teaching:** Character teaches during dialogue (future)
4. **Puzzle Solve:** Solving a puzzle teaches meta-skill about game verbs (future)

**Rationale:** No forced order. Player discovers skills naturally. Replay value: different players learn in different order.

**Impact:** Minimizes tutorial burden. Puzzle designer doesn't need to force a skill order. Teachers in room ("Find manual in library") naturally paces discovery.

---

## Implementation Notes

### For Engineers
- Add `player.skills` table (hash of skill_id → boolean)
- Verb handlers check `player.skills[required_skill]` before allowing action
- Tool lookup validates both `provides_tool` AND skill requirement
- Failed actions trigger failure mutation (bent-pin, tangled-mess)

### For Designers
- Create skill manuals as readable objects in rooms
- When tool is picked up, consider whether it needs an associated manual
- Mark blood writes as disturbing in design docs (signal intensity to team)
- Test that every puzzle has a no-skill solution

### For QA
- Verify skill gates work: attempt PICK LOCK without lockpicking (should block)
- Verify skill enablement works: read manual, attempt PICK LOCK (should enable)
- Verify consumable failures: failed lock pick leaves bent-pin in inventory
- Verify paper persistence: write on paper, quit game, reload, paper still has text

---

## Risk Assessment

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|----------|-----------|
| Players ignore skills; every puzzle solved one way | Low | Low | Design multiple paths; signal skill benefits in design docs |
| Blood writing feels gratuitous; alienates players | Medium | Medium | Document dark tone upfront; offer non-blood alternative (other instruments) |
| Consumable failures frustrate players | Low | Medium | Make failures recoverable; place multiple tools in room; design gentle early-game |
| Paper mutations slow down game loop | Low | Medium | Profile disk I/O; consider in-memory mutations with periodic flush |
| Player text breaks Lua parser | Low | High | Sanitize input (whitelist chars, escape quotes, truncate to 256 chars) |

---

## Decision Authority

**Level 1** (design-level decision). Affects game design, verb system, and object system. Does not affect architecture.

**Approvers needed:**
- Wayne "Effe" Berry (Product Owner)
- Bart (Architect) — for verb dispatch integration
- Game Design team consensus

**Timeline:** Proposal → Review (3–5 days) → Approval/Iteration → Implementation (1 week for MVP)

---

## Relation to Prior Decisions

**Supports:** Decision D-28 (Multi-Sensory Convention). Skills are discovered by feeling/smelling/tasting objects in dark room.

**Extends:** `design-directives.md` (Skill Interaction Matrix). This memo formalizes the design into implementation-ready specs.

**Adjacent to:** Failure Mode Design (`containment-constraints.md`). Bent pins and tangled threads are failure states, like "desk won't fit in sack."

---

## Open Questions for Team

1. **Paper mutations:** File-per-state (create new .lua) or in-place (modify existing)? File-per-state is cleaner, more visible to designers. In-place is simpler code.

2. **Proficiency levels:** Keep in design doc as future work, or prototype now? Recommend leaving for V2, but want team input.

3. **NPC teaching:** Out of scope for MVP, but should verb handlers reserve a `requires_teaching` gate for future? Recommendation: YES, add the gate now (unused, ready for V2).

4. **Blood availability:** Should blood persist across room changes? Current design: time-limited (clots after 5 min). Alternative: persistent until consumed. Which feels right for dark, urgent tone?

---

## Next Steps

1. ✅ Design doc written (`docs/design/player-skills.md`)
2. ⏳ Team reviews and approves this memo
3. ⏳ Engineers scope implementation
4. ⏳ Create skill manuals as objects (design work)
5. ⏳ Implement verb dispatch gates (engineer work)
6. ⏳ Test skill acquisition and gating (QA)

---

**Prepared by:** Comic Book Guy  
**Reviewed by:** (pending team input)  
**Approved by:** (pending decision)

*"This is a complex system, but I've kept it elegant. Simplicity in data model, depth in gameplay. That's the design sweet spot." — Comic Book Guy*
