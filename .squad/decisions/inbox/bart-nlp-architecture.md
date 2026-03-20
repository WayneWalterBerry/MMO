# Architecture Analysis: Goal-Oriented Parsing (Tier 3)

**Author:** Bart (Architect)
**Date:** 2026-03-25
**Status:** Proposal — Ready for Review
**Affects:** Parser pipeline, game loop, object metadata, verb dispatch

---

## 1. Current Pipeline Gaps

### Where Parsing Happens in loop/init.lua

The parsing pipeline lives inside the `while true` loop at line 253, executed per-input:

```
Input → trim → strip trailing "?" → split on " and " → per sub-command:
  → preprocess_natural_language (NLP patterns → verb, noun)    [line 306]
  → parse (first-word split → verb, noun)                      [line 308]
  → Tier 1: context.verbs[verb] exact dispatch                 [line 318]
  → Tier 2: parser.fallback (Jaccard phrase matching)           [line 324]
  → Fail visibly                                                [line 331]
```

Each sub-command is **independently dispatched**. There is no cross-command awareness — no planner looks at the full input before dispatching individual pieces.

### How Compound Commands Split

Lines 287–301: Greedy left-to-right split on ` and `:

```
"get a match and light it" → ["get a match", "light it"]
```

This works for **explicit player-sequenced commands** where the player has already decomposed the plan. It does NOT work when the player states a **goal** without specifying intermediate steps:

```
"light the candle"  →  Single command. No splitting.
                       LIGHT handler fires. Checks for fire_source tool.
                       Player doesn't have one. Fails: "You have nothing to light it with."
```

The player knows what they want. The engine knows what's needed. Neither bridges the gap.

### Context Available at Parse Time

At dispatch time, the full game state is accessible via `context`:

| Field | Content | Useful for Planning |
|-------|---------|-------------------|
| `ctx.registry` | All objects, full state | ✅ Can query any object's FSM, transitions, requirements |
| `ctx.current_room` | Room + contents list | ✅ Knows what's reachable |
| `ctx.player.hands[1..2]` | Held items | ✅ Knows what player is carrying |
| `ctx.player.worn` | Worn items + bag contents | ✅ Full inventory |
| `ctx.player.state` | Flags (has_flame, bloody, etc.) | ✅ Player condition |
| `ctx.last_object` | Last successfully found object | ⚠️ Useful but fragile across planning |
| `ctx.verbs` | All registered handlers | ✅ Knows what actions exist |
| `ctx.parser` | Tier 2 matcher instance | Not needed for planning |

**Key insight:** Everything the planner needs is already on `context`. No new data pipelines required.

### Pronoun Resolution — Current State

Lines 488–509 in verbs/init.lua: `find_visible` is wrapped with a closure that:

1. Checks if keyword is "it", "one", or "that" → resolves to `ctx.last_object`
2. On successful find, stores the found object as `ctx.last_object` (plus loc, parent, surface)

**Can we extend it?** Yes, but carefully:

- Current: tracks ONE object. A planner generating multi-step sequences would overwrite `last_object` at each step.
- Solution: the planner should resolve all object references BEFORE generating the action sequence. Don't rely on pronoun tracking during plan execution — resolve everything to concrete object IDs.
- Post-plan pronoun state: after executing a planned sequence, `last_object` should point to the final target (the candle, not the match). This matches player expectation.

---

## 2. Proposed Tier 3: Goal Decomposition

### Position in Pipeline

```
Input → trim → strip "?" → split on " and " → per sub-command:
  → NLP preprocess
  → parse (verb + noun)
  → Tier 1: exact verb dispatch
       ↓ (handler returns "need_plan" or fails with known prerequisite)
  → [NEW] Tier 3: Goal Decomposition
       → Query target object's prerequisites
       → Build action sequence (backward chaining)
       → Execute sequence step-by-step through Tier 1
       → Stop on first failure
  → Tier 2: Jaccard fallback (unchanged, runs if Tier 3 doesn't engage)
  → Fail visibly
```

### When Tier 3 Engages

Tier 3 does NOT engage on every command. It engages when:

1. **Tier 1 dispatch succeeds** but the verb handler **detects a missing prerequisite** (e.g., LIGHT handler finds no fire_source tool)
2. The target object has **declared prerequisites** in its metadata
3. The prerequisites are **satisfiable** from current game state

This is critical: Tier 3 is not a replacement for Tier 1 or Tier 2. It's a **recovery mechanism** that fires when the player's intent is clear but the prerequisites aren't met.

### Interface Contract

```lua
-- Input to Tier 3
local plan_request = {
    verb = "light",           -- what the player wants to do
    target = candle_obj,      -- resolved object
    missing = "fire_source",  -- what capability is missing
    context = ctx,            -- full game state
}

-- Output from Tier 3
local plan = {
    steps = {
        { verb = "open", noun = "matchbox", object_id = "matchbox" },
        { verb = "get",  noun = "match",    object_id = "match-1" },
        { verb = "strike", noun = "match on matchbox", object_id = "match" },
        -- original command executes last (now fire_source is available)
    },
    final_verb = "light",
    final_noun = "candle",
}
```

### Execution Model

Each planned step feeds back through Tier 1 dispatch:

```lua
for _, step in ipairs(plan.steps) do
    local handler = ctx.verbs[step.verb]
    if handler then
        handler(ctx, step.noun)
        -- Verify postcondition (did the step actually succeed?)
        if not verify_postcondition(step, ctx) then
            -- Plan failed at this step. Stop. Don't continue.
            print("(You'll need to do that yourself.)")
            return
        end
    end
end
-- All prerequisites met. Execute the original command.
handler(ctx, original_noun)
```

**Stop-on-failure is mandatory.** If step 2 fails (matchbox is empty, no matches left), the plan aborts. The player sees the failure message from the verb handler itself — no special error handling needed.

---

## 3. Prerequisite Table Architecture

### Object-Owned Prerequisites

Each object declares what its verbs need. This is consistent with Wayne's architecture: **objects own their behavior**. The prerequisite data lives alongside the existing FSM transitions.

```lua
-- candle.lua (proposed addition)
transitions = {
    {
        from = "unlit", to = "lit", verb = "light",
        requires_tool = "fire_source",
        -- NEW: prerequisite chain for goal decomposition
        prerequisites = {
            { need = "fire_source", -- capability needed
              sources = {           -- how to get it
                  { object_keyword = "match", required_state = "lit" },
              },
            },
        },
        message = "The wick catches the flame...",
        fail_message = "You have nothing to light it with.",
    },
},
```

```lua
-- match.lua (proposed addition)
transitions = {
    {
        from = "unlit", to = "lit", verb = "strike",
        requires_property = "has_striker",
        -- NEW: what the planner needs to know
        prerequisites = {
            { need = "holding",     -- must be in player's hands
              resolve = "get" },    -- verb to satisfy this
            { need = "has_striker", -- need a striker surface
              sources = {
                  { object_keyword = "matchbox", property = "has_striker" },
              },
            },
        },
        message = "You drag the match head across the striker...",
    },
},
```

### Why Object-Owned (Not a Central Table)

Three reasons:

1. **Locality.** A content creator editing `candle.lua` sees everything about candle behavior in one file. They don't need to update a separate prerequisites database.

2. **Composability.** Different candles could have different prerequisites. A magic candle might require a spell component instead of fire. The prerequisite system is per-transition, not per-verb.

3. **Existing pattern.** This is exactly how `requires_tool` and `requires_property` already work — they're fields on transition tables. Prerequisites extends this pattern, doesn't replace it.

### Backward Chaining Resolution

The planner resolves prerequisites backward from the goal:

```
GOAL: light candle
  → needs: fire_source
  → source: match (state: lit)
  → SUBGOAL: strike match
    → needs: holding match
    → SUBGOAL: get match
      → needs: match accessible
      → source: matchbox (must be open, accessible=true)
      → SUBGOAL: open matchbox
        → needs: holding matchbox (or matchbox reachable)
        → matchbox is in room — SATISFIED
      → open matchbox — RESOLVED
    → get match from matchbox — RESOLVED
  → needs: has_striker surface
    → matchbox has has_striker — SATISFIED
  → strike match on matchbox — RESOLVED
→ light candle with lit match — RESOLVED
```

Output plan: `[open matchbox, get match, strike match on matchbox, light candle]`

### The "Holding" Prerequisite

Many actions require holding the target. This is the most common prerequisite and can be inferred without explicit declaration:

```lua
-- Implicit rule (engine-level, not object-level):
-- If a verb handler calls find_in_inventory and fails,
-- but the object is visible in the room, "get" is a prerequisite.
```

This avoids cluttering every object with `{ need = "holding", resolve = "get" }`. The planner can infer it.

---

## 4. Implementation Feasibility in Lua

### Can We Do GOAP in Pure Lua?

Yes, but we don't need full GOAP. Full GOAP (Goal-Oriented Action Planning, as in F.E.A.R.) uses:

- World state as a set of boolean predicates
- Actions with preconditions and effects
- A* search through state space

Our problem is simpler. We have:

- A small, fixed set of prerequisite types (holding, tool capability, object state, surface property)
- Short chains (typically 2–5 steps)
- Deterministic prerequisites (no probability, no branching choices)

**What we actually need: backward-chaining dependency resolver.** This is closer to a build system (Make/Ninja) than a game AI planner. Each prerequisite is a "target" that must be "built" before the final target.

### Performance

**Planning depth:** The candle example is 4 steps deep. Most chains will be 2–3. Maximum realistic depth: 5–6 (multi-tool crafting).

**Object scan:** The planner needs to scan room contents + inventory for objects that can satisfy a prerequisite. Typical room: 10–20 objects. Inventory: 2–6 items. Total scan per prerequisite: ~25 objects.

**Total work per plan:** 5 prerequisites × 25 object scans × trivial table lookups = ~125 iterations. In Lua, this is **sub-millisecond**. Not even worth benchmarking.

**Memory:** Prerequisite tables are 3–5 entries per transition. Maybe 50 objects in the entire game have prerequisites. Total additional memory: ~2KB of Lua tables. Negligible.

### Complexity Estimate

| Component | Lines of Code | Time Estimate |
|-----------|--------------|---------------|
| Prerequisite resolver (backward chainer) | ~80–120 | 1 day |
| Plan executor (step-by-step with verification) | ~40–60 | Half day |
| Prerequisite metadata on existing objects | ~5–10 per object, ~15 objects | Half day |
| Integration into loop/init.lua | ~20–30 | 2 hours |
| Tests (plan generation + execution) | ~100–150 | 1 day |
| **Total** | **~300–450** | **~3 days** |

This is a **day-and-a-half of engine work** plus a day of content tagging and testing. Not a week.

---

## 5. What Changes, What Doesn't

### NO CHANGE Required

| Component | Why |
|-----------|-----|
| **Verb handlers** | Already atomic. Already check for tools/prerequisites and fail with messages. The planner calls them unchanged. |
| **FSM engine** | Transitions, guards, ticks — all untouched. The planner reads FSM data but doesn't modify the engine. |
| **Tier 2 parser** | Jaccard matcher stays as-is. Tier 3 is orthogonal. |
| **Mutation system** | Object rewriting is unaffected. |
| **Containment validator** | Weight, size, capacity checks — unchanged. |

### EXTEND (Add New Behavior)

| Component | Change |
|-----------|--------|
| **Object files** (candle.lua, match.lua, etc.) | ADD `prerequisites` tables to transitions that have `requires_tool` or `requires_property` |
| **loop/init.lua** | ADD Tier 3 invocation between Tier 1 failure-with-known-reason and Tier 2 fallback |
| **NLP preprocessing** | EXTEND for prepositional phrase extraction ("light candle with match" → verb=light, noun=candle, instrument=match). Currently "with X" is only handled in specific verbs (sew, strike). |
| **Context tracker** | EXTEND `ctx.last_object` to `ctx.last_objects` (plural) — track last 2–3 objects for richer pronoun resolution during planned sequences |

### NEW Modules

| Module | Purpose | Size |
|--------|---------|------|
| `engine/planner/init.lua` | Backward-chaining prerequisite resolver + plan executor | ~150–180 lines |
| `engine/planner/rules.lua` | Implicit prerequisite rules (e.g., "if not holding, try get") | ~40–60 lines |

---

## 6. Risk Assessment

### Risk 1: Infinite Prerequisite Loops

**Scenario:** Object A requires tool from Object B. Object B requires tool from Object A.

**Mitigation:** The backward chainer maintains a visited-set of `(object_id, verb)` pairs. If it encounters a pair it's already planning for, it aborts with "no plan found." This is standard cycle detection — ~5 lines of code.

```lua
local visited = {}
local function resolve(obj_id, verb, depth)
    local key = obj_id .. ":" .. verb
    if visited[key] then return nil, "cycle" end
    if depth > MAX_PLAN_DEPTH then return nil, "too_deep" end
    visited[key] = true
    -- ... resolve ...
end
```

**MAX_PLAN_DEPTH = 6.** Any chain longer than 6 steps is probably a design error, not a legitimate puzzle. Fail loudly.

### Risk 2: Wrong Inferences

**Scenario:** Player says "light the candle." Planner infers they need to strike a match. But there's also a lit fireplace in the room. The planner picks the match path; the player wanted to use the fireplace.

**Mitigation:** The planner should prefer **already-available** tools over tools that require additional steps. Priority order:

1. Player already has a lit fire_source (match, candle, torch) → no plan needed, just execute
2. Room contains a fire_source (lit fireplace) → suggest "use fireplace" but don't force
3. Player has an unlit fire_source → plan to light it
4. Room has an unlit fire_source → plan to get + light it

This is a simple priority sort on the `sources` list, not complex AI.

### Risk 3: Player Override ("I just want to strike the match")

**Scenario:** Player types "strike match." They just want to strike it, not light anything. The planner should NOT infer a follow-up goal.

**Mitigation:** Tier 3 only engages on **failure with known missing prerequisite**. If the player says "strike match" and they're holding a match near a matchbox, Tier 1 handles it directly. No planning. Tier 3 never sees it.

Tier 3 is a **recovery** mechanism, not a mind-reading mechanism. It asks: "The player wanted X, X failed because Y is missing, can I satisfy Y?" It does NOT ask: "The player did X, what might they want to do next?"

### Risk 4: Narrative Coherence

**Scenario:** The planner executes 4 steps silently. The player sees rapid-fire output:

```
> light the candle
You slide the matchbox tray open with your thumb.
You take a wooden match.
You drag the match head across the striker strip...
The wick catches the flame and curls to life...
```

**Is this good or bad?** It's a design question, not an engineering question. Options:

1. **Silent execution** — just do it, show results (feels magical, may confuse)
2. **Narrated execution** — preface with "You'll need to prepare first..." (clear, may feel patronizing)
3. **Confirmation** — "You'll need to open the matchbox, get a match, and strike it. Proceed?" (safe, breaks flow)

**Recommendation:** Option 2 — narrated, no confirmation. The engine states what it's doing. The player learns the chain for next time. No flow interruption.

```
You'll need a flame first...
You slide the matchbox tray open. You take a match and strike it
against the strip -- it catches with a hiss.
The wick catches the flame and curls to life, casting a warm amber glow.
```

### Risk 5: State Mutation During Plan Execution

**Scenario:** Step 2 of the plan changes game state in a way that invalidates step 3.

**Example:** Player has 2 full hands. Plan says "get match" but both hands are full. The verb handler correctly fails with "Your hands are full."

**Mitigation:** Each step goes through the real verb handler, which checks all preconditions. The planner does NOT simulate — it executes for real. If a step fails, the plan aborts. The world state is consistent because every step used the real validation.

The only risk is partial execution: the player ends up with an open matchbox but no match in hand. This is fine — they're further along than when they started, and the failure message tells them what went wrong.

---

## 7. Recommendation

**Build it in two phases:**

### Phase 1: Prerequisite Metadata + Planner Core (2 days)

1. Add `prerequisites` tables to candle.lua and match.lua transitions
2. Build `engine/planner/init.lua` — backward chainer + plan executor
3. Wire into loop/init.lua — single integration point
4. Test with the candle-match-matchbox chain

### Phase 2: Implicit Rules + Broader Coverage (1 day)

1. Add implicit "holding" prerequisite (engine-level, not per-object)
2. Add implicit "accessible" prerequisite (containers must be open)
3. Tag remaining objects with prerequisites (lantern, fireplace, etc.)
4. Play test the full game with planning enabled

**Phase 1 is the proof of concept.** If it works for the candle chain, it works for everything. Phase 2 is just expanding coverage.

### What I Need From the Team

- **Comic Book Guy:** Review prerequisite chains for all lightable/usable objects. Are there chains I'm missing? Objects that should NOT auto-plan? (Some puzzles should stay manual — the player figuring out the chain IS the puzzle.)
- **Nelson:** Plan a test pass specifically for goal-oriented commands. "light candle" without preparation, "light candle" with partial preparation (match in hand but not lit), "light candle" when already lit.
- **Wayne:** Design call on narrative style (silent vs. narrated vs. confirmation). This affects player experience more than any technical decision.

---

*Filed by Bart. This is analysis, not implementation. No code was changed.*
