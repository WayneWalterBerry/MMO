# Game Design Review: NPC + Combat Phase 4 Implementation Plan

**Reviewer:** Comic Book Guy (CBG), Game Designer  
**Date:** 2026-08-20  
**Document Reviewed:** `plans/npc-combat/npc-combat-implementation-phase4.md` (v1.0 DRAFT)  
**Status:** **CONDITIONAL APPROVE** (4 blockers, 3 recommendations)

---

## Executive Summary

Phase 4 is a **well-structured** execution plan with **clear dependency chains**, **balanced scope**, and **solid game design fundamentals**. The crafting loop (kill → butcher → cook → eat / kill → harvest → craft) addresses Phase 3's resource extraction gaps and establishes the ecosystem as a production system. **However**, four gameplay design issues require resolution before implementation can proceed:

1. **Stress system severity tuning** — Current thresholds risk making the game unplayable during playtesting
2. **Crafting reward incentive hierarchy** — Silk recipes lack sufficient differentiation from cooking
3. **Spider web trap scope creep** — Size-based trap mechanics introduce complexity not justified by Level 1 gameplay
4. **Pack tactics coordination cost** — Alpha/beta/omega roles add AI complexity with unclear payoff for V1 playtesting

These are **gameplay-scoped** — not architecture or implementation issues. All can be addressed with metadata tweaks, but they must be locked in BEFORE code starts.

---

## Gameplay Loop Quality: ✅ STRONG

### Butchery System
**Assessment:** Excellent design that solves a real Phase 3 problem. Wolf corpses (furniture template) were dead-end assets. Butchering converts them to **crafting inputs**, establishing the resource flow loop.

**Strengths:**
- Tool requirement (knife) creates meaningful inventory constraint
- Product variety (3 meat, 2 bone, 1 hide) teaches material differentiation
- Duration (5 min game time) consistent with existing `cook` verb precedent
- Narration (start → complete) gives satisfying activity beats

**Design Quality:** 8/10 — This is textbook good-design: problem → solution → immediate payoff.

---

## Crafting Balance: ⚠️ **BLOCKER #1 — Silk Recipe Incentive Hierarchy**

### The Problem
Silk crafting recipes (2 bundles → 1 rope; 1 bundle → 2 bandages) feel **interchangeable with cooking** from a player reward perspective. Both are:
- Inputs from creature death (meat/silk both drop on kill)
- 1:1 or 2:1 conversion ratios
- Single-purpose use (eat meat OR use bandage)

**BLOCKER:** Players will have no incentive to craft silk over simply cooking meat during Level 1 playtesting. This makes the spider ecology feel optional instead of essential.

### Specific Concerns

**Q1: Rope Use Case (WAVE-4)**
- Plan assumes rope is useful "for climbing" or "binding" — but these verbs don't exist in Phase 1
- Rope becomes a crafted item with *no gameplay use* until Phase 5
- Spider silk earned in Phase 4 is dead inventory weight until Level 2

**Q2: Bandage Healing (Section 10, Q6)**
- Recommendation: "Option A (instant): +5 HP immediately"
- Problem: Silk bandages heal *identically* to cooking wolf meat + eating it
  - Meat: cook (1 step) + eat (1 step) = +35 nutrition, heal 8 HP
  - Bandage: craft (1 step, requires 1 silk) + use (1 step) = +5 HP
- Bandages are **strictly worse** than cooking — less healing, equal steps, requires silk (consumable resource)

### Why This Matters for Level 1 Gameplay
The spider is the only creature that produces silk. If silk has no immediate use, players:
1. Kill spider once (curiosity) → get silk
2. Notice bandages heal less than food
3. Never craft silk again (use food instead)
4. Spider ecology loop is broken for playtesting

This undermines the **Phase 4 theme: "Resources flow through the crafting pipeline."**

### **BLOCKER #1: REQUIRED DECISION**
Choose ONE of these before WAVE-1 code starts:

**Option A (Recommended):** Give rope immediate use in Level 1
- `hang rope` in bedroom → tie noose → alternative puzzle solution (dark, desperate flavor)
- Or: `climb rope` in courtyard well → access pool without fall damage
- Or: `tie rope to hook` → swing over gap in path
- **Benefit:** Makes spider silk immediately valuable; spider becomes non-optional

**Option B:** Boost bandage healing to match food
- Change to +15 HP (comparable to cooked wolf meat)
- Or: Add secondary effect: "bandage stops bleeding for 1 hour" (treatment matching)
- **Benefit:** Craft reward feels meaningful vs. cooking

**Option C:** Defer all silk crafting to Phase 5
- Remove silk recipes from Phase 4 entirely
- Spider still drops silk; players collect it as Phase 5 prerequisite
- Reduces Phase 4 scope, but loses the "crafting loop" completeness
- **Downside:** Loses on PHASE 4 THEME

**CBG Recommendation:** Option A. Rope use-case in Level 1 maintains the immersion of "every object has a purpose" and makes spider ecology feel integral, not optional.

---

## Stress Injury System: ⚠️ **BLOCKER #2 — Severity Tuning (Thresholds Unbalanced)**

### The Design
Section 5, lines 504-532: Three severity levels with progression triggers.

```lua
levels = {
    { name = "shaken",      threshold = 1 },  -- -1 attack penalty
    { name = "distressed",  threshold = 3 },  -- -2 attack, +0.2 flee bias
    { name = "overwhelmed", threshold = 5 },  -- -4 attack, +0.5 flee bias, 50% movement penalty
}
```

Stress sources:
- Witness creature death: +1
- Near-death combat: +2
- First kill (one-time): +3
- Witness gore (butchery): +1

### The Problem: **Stress Escalates Too Quickly**

**Scenario:** Player fights first combat vs. wolf.

1. Initiates combat: 0 stress
2. Gets hit; health < 10%: +2 stress → **Distressed** (threshold 3 reached? NO, at 2)
3. Kills wolf: +3 stress (first kill) → **5 stress total → Overwhelmed** ✓
4. Status: -4 attack penalty, 50% movement penalty, +50% flee bias
5. Can't move (50% penalty), can't attack (-4), fleeing constantly

**Result:** Player is **combat-ineffective and movement-crippled after single victory.** This violates the pedagogical principle: *failure teaches, success should reward*.

### Why This Breaks Level 1 Playtesting

**Current stress curve:**
- After 1 wolf kill: overwhelmed (can barely move or fight)
- Only cure: rest 2 hours in safe room (real-world ~2 minutes)
- During cure, time advances → spoilage triggers on food (if food preservation exists)

**Player experience:**
1. Kill wolf (exciting!) → overwhelmed (punished?)
2. Can't explore → must hide 2 hours
3. Food spoils while resting
4. Resource loss for emotional consequence feels cheap

This is **the opposite of fair design**. Stress should be a *consequence of failure*, not a *tax on success*.

### **BLOCKER #2: REQUIRED DECISION**

Choose ONE before WAVE-3 code starts:

**Option A (Aggressive):** Raise thresholds dramatically
- Shaken: threshold 3 (down from 1)
- Distressed: threshold 6 (down from 3)
- Overwhelmed: threshold 10 (down from 5)
- **Benefit:** Player needs multiple trauma events to be severely stressed; single kill doesn't cripple
- **Downside:** Stress feels less threatening

**Option B (Conservative):** Reduce severity of debuffs
- Overwhelmed: -2 attack (down from -4), +20% flee bias (down from 50%), NO movement penalty
- **Benefit:** Player can still function; stress is a hindrance, not a wall
- **Downside:** Stress feels less impactful

**Option C (Pedagogical):** Remove first-kill stress spike
- First kill does NOT inflict +3 stress (remove this trigger)
- Keep witness-death (+1) and near-death (+2) only
- **Benefit:** Victory is rewarding, not punished; players learn confidence before earning caution
- **Downside:** One fewer stress source

**CBG Recommendation:** **Option C + Option B combined**. Remove the first-kill spike, and dial back overwhelmed debuffs. This creates a **learning curve**: 
- First kill: minimal stress (confidence building)
- Multiple kills / witness deaths: stress accumulates gradually
- Overwhelmed state is uncomfortable but not gamebreaking

---

## Spider Ecology: ⚠️ **BLOCKER #3 — Web Trap Complexity (Scope Creep for V1)**

### The Design (Section 4, WAVE-4)

Spider webs are traps:
```lua
trap = {
    affects_sizes = {"tiny", "small"},  -- rat, spider, bat (not player, cat, wolf)
    effect = "immobilize",
    escape_difficulty = 3,  -- 1-5 scale
}
```

### The Problem: **Size-Based Trap Mechanics Are Premature for Level 1**

**Current Level 1 creatures:**
- Rat (tiny) — trapped by web
- Cat (small) — **not trapped?**
- Wolf (medium) — not trapped
- Spider (small) — not trapped (creator exception?)
- Bat (tiny) — trapped by web

**Questions left unanswered in the plan:**
1. Does `affects_sizes` include the spider itself? If so, spiders trap themselves (design flaw). If not, special-case logic needed.
2. Cat is labeled "small" — does it get trapped? Plan doesn't clarify.
3. What triggers escape? Section 4 says "escape_difficulty = 3" but no mechanics for HOW a trapped creature escapes.
4. Can player see trapped creatures? Does web narration change when occupied?

### Why This Matters

**Web-trap mechanic introduces:**
- Size/scale system on creatures (new metadata field needed on all 5 creatures)
- Trap state machine (empty → occupied → escaped)
- Creature escape resolution (difficulty checks with no skill system in Level 1)
- Web narration variations (trapped vs. empty)

This is **not just code complexity** — it's a **gameplay complexity** that Level 1 playtesting doesn't need.

**Current use case in Level 1:**
- Spider creates web in cellar
- Rat wanders in and gets trapped
- Spider attacks trapped rat
- Player witnesses this behavior (emergent, cool!)

**That's it.** Players don't interact with trap mechanics directly.

### **BLOCKER #3: REQUIRED DECISION**

Choose ONE before WAVE-4 code starts:

**Option A (Simplified):** Web is impassable obstacle, not a trap
- Spider creates web in room
- Web blocks NPC movement (rats can't pass, must go around)
- Player can walk through (sticky but passable per design)
- Removes: size system, escape difficulty, trap state machine
- **Benefit:** Simpler, still emergent (spider uses web to corral prey)
- **Downside:** Less "trap" feeling

**Option B (Deferred):** Implement size system in Level 2
- Phase 4 creates webs as scenery objects (no trap mechanics)
- Web blocks movement for any NPC (size-agnostic)
- Phase 5: add size system + escape mechanics with full creature AI
- **Benefit:** Phase 4 focus stays on crafting loop; trap complexity gets dedicated phase
- **Downside:** Web feels less interactive in V1

**Option C (As Planned):** Full trap implementation
- Implement size system, trap state, escape difficulty
- Accept ~40 LOC additional complexity in creatures/init.lua
- **Benefit:** Full simulation, deeper NPC behavior
- **Downside:** Untestable without creature escape skill system (which doesn't exist in Phase 1)

**CBG Recommendation:** **Option A**. Simplify web-as-obstacle. This maintains the emergent behavior (spider uses web to herd prey, player observes ecology) without introducing trap mechanics that won't be playtested for months. **Spider ecology is about the SPIDER'S behavior, not about trap puzzles.**

---

## Pack Tactics: ⚠️ **BLOCKER #4 — Coordination Complexity vs. V1 Payoff**

### The Design (Section 5, WAVE-5)

Pack tactics system:
```lua
pack_tactics = {
    role_selection = function(wolves, ctx)
        -- Alpha (highest aggression), Beta, Omega (reserve)
    end,
    coordination = {
        alpha = { target_zone = "torso", priority = 1 },
        beta  = { target_zone = "legs", priority = 0.8, delay = 1 },
        omega = { target_zone = "arms", priority = 0.5 },
    },
}
```

### The Problem: **Combat Zone Targeting Is Undefined**

**Missing from plan:**
1. **Zone targeting resolution** — If alpha aims torso, beta aims legs, how does engine choose which zone actually takes damage?
   - Current combat (Phase 3) uses random zone selection, not AI-chosen zones
   - Plan doesn't specify if this requires new combat engine feature

2. **Beta delay mechanic** — "delay = 1" but what is the unit? 1 second real-time? 1 game turn? 1 minute game-time?
   - Section 5 line 794 says wolves coordinate, but timing is vague

3. **Omega reserve condition** — "condition: alpha_injured" but how much injury? Health < 50%? Last hit landed damage?

4. **Testing complexity** — How do you verify pack tactics in deterministic tests without simulating full multi-wolf combat?

### Why This Matters for V1 Playtesting

**Current Level 1 NPC spawning:**
- 2 wolves in bedroom (pack scenario) - rare encounter
- 1 wolf in courtyard, 1 cat in garden - no pack

**Expected player encounters with pack tactics:**
- Bedroom assault: 2 wolves coordinate against player
- That's the main scenario in Level 1

**Current design flow:**
1. Player enters bedroom at 2 AM
2. 2 wolves present (respawn from Phase 3)
3. Wolves form pack, assign alpha/beta roles
4. Alpha attacks torso, beta attacks legs
5. Result: ... player takes 2x damage? Different zones = different narrative?

**The real problem:** Without explicit zone-targeting in the combat engine, **pack tactics narration becomes incoherent**. If combat says "wolf bites your arm" and then "other wolf claws your leg," that's fine. But if they're *choosing* zones based on role, engine must honor it — and Phase 3 combat doesn't.

### Opportunity Cost

**Resources to implement pack tactics:**
- Coordination engine: ~100 LOC (Bart)
- Territorial marking: ~80 LOC (Bart)
- Two new test files: ~60 test LOC (Nelson)

**Alternative use of same resources (Option B below):**
- Enhanced single-wolf AI (ambush positioning near web, defensive posture when injured)
- This provides **equivalent gameplay depth** with **half the complexity**

### **BLOCKER #4: REQUIRED DECISION**

Choose ONE before WAVE-5 code starts:

**Option A (As Planned):** Full pack tactics implementation
- Implement role assignment, coordination delays, zone preferences
- Accept ~80 LOC added complexity for Level 1 playtesting
- **Benefit:** Multi-wolf combat is coordinated and tactical
- **Downside:** Requires combat engine changes; hard to test; 2-wolf encounters rare in Level 1

**Option B (Simplified):** Solo-wolf AI improvement instead
- Instead of pack tactics, improve individual wolf behavior
- Add defensive positioning (flee when health < 20%, position behind furniture)
- Add ambush behavior (wait near web before striking)
- Same LOC budget, **more emergent variety** for single-wolf encounters (which are more common)
- **Benefit:** Better AI with fewer dependencies; more 1v1 encounters feel fresh
- **Downside:** No pack tactical feel

**Option C (Deferred):** Defer pack tactics to Phase 5 polish
- Level 1: wolves fight independently (current behavior)
- Phase 5: add pack coordination once combat zone system is mature
- Frees ~180 LOC from Phase 4 budget
- **Benefit:** Simpler Phase 4; pack tactics gets dedicated phase
- **Downside:** Multi-wolf encounters in Level 1 feel flat

**CBG Recommendation:** **Option B**. The 2-wolf bedroom encounter is iconic but *rare*. The payoff from pack tactics for V1 playtesting is minimal. Instead, invest in **individual wolf AI**: ambush positioning, defensive retreat, smart positioning. This provides equivalent gameplay depth with a *100% testable* design — every wolf encounter improves.

---

## Recommendations: Improvements (Not Blockers)

### Recommendation 1: Territorial Marking Needs Narration

**Section 5, Q5 (line 1051-1056):** Plan recommends "Option B (smell only)."

**Add:** When player enters territory-marked room for first time, narration should trigger:
- "You catch the scent of a territorial marking — a warning."
- Or in darkness: "You feel a strange, subtle scent in the air... animal territory."

**Why:** Without narration, territorial mechanics are invisible. Players won't understand why wolves seem to "own" certain rooms. This is **immersion-critical**.

**Effort:** ~5 lines in creature behavior dispatch. Include in WAVE-5.

---

### Recommendation 2: Loot Table Conditional Kills Need Definition

**Section 2, WAVE-2 (line 86):** Loot tables support conditional drops:
```lua
conditional = {
    fire_kill = { { template = "charred-hide" } },
    poison_kill = { { template = "tainted-meat" } },
}
```

**Missing:** How does the engine know a creature died to fire vs. poison? Section 4 mentions `death_context.kill_method` (line 414) but doesn't specify the enum.

**Current Phase 3 kills:**
- Weapon damage (no poison/fire in Level 1)
- Disease (rabies, venom)
- Starvation (future)

**Action:** Add to WAVE-0 (Q section) or WAVE-2 spec:
- Define `kill_method` enum: `"weapon"`, `"fire"`, `"poison"`, `"disease"`, `"starvation"`
- Specify which are available in Level 1 (hint: just `"weapon"`)
- Defer conditional drops to Phase 5+ when fire/poison kills exist

**Benefit:** Prevents half-implemented code. Keeps Phase 4 scope clear.

---

### Recommendation 3: Stress Cure Duration Feedback

**Section 3, WAVE-3 (line 520-524):**
```lua
cure = {
    method = "rest",
    duration = "2 hours",  -- game time
    requires = { safe_room = true },
}
```

**Missing:** How does player know they're curing? No narration, no progress indicator.

**Add to stress.lua:**
- `cure_narration_complete = "The trembling subsides. Your breathing steadies. You feel calm again."`
- `cure_narration_ticking = "You're starting to feel more at ease."` (optional, at 50% cure progress)

**Why:** Matches bear-trap.md pattern (heal action gives feedback). Players should know rest is working.

---

## Design Audit: Architecture Alignment

### Principles Compliance: ✅ **STRONG**

Phase 4 adheres to core design principles:

| Principle | Compliance | Evidence |
|-----------|-----------|----------|
| **P1: Objects inanimate** | ✅ | Creatures exist; no NPC system in Phase 4 |
| **P3: FSM + state tracking** | ✅ | Loot tables, stress levels, web traps use FSM |
| **P4: Composite encapsulation** | ✅ | Silk bundles → rope/bandage (output-focused) |
| **P6: Sensory space** | ✅ | Web visibility in darkness via `on_feel` |
| **P7: Spatial relationships** | ✅ | Pack tactics, territorial marking are spatial |
| **P8: Engine executes metadata** | ✅ | Stress triggers from combat hooks; territory from presence |
| **P9: Material consistency** | ✅ | Silk is material; wolf-hide is crafting input |
| **D-14: Code mutation IS state** | ✅ | Creatures don't carry mutable stress state; stress is injury metadata |

---

## Risk Assessment Revisited (Section 6)

Plan's risk register is **strong**. Adding two risks:

### New Risk: Butchery Time-Skip Edge Case (Medium Likelihood, Low Impact)

**Issue:** If player butchers a corpse while it's actively respawning, does the new creature spawn inside the corpse-being-butchered?

**Mitigation:** Specify in WAVE-1: corpse becomes locked (immutable) during butchery. New spawns cannot appear in same location until butchery completes.

### New Risk: Stress Spiral (High Likelihood if Blocker #2 Unfixed, High Impact)

**Issue:** If stress thresholds aren't tuned, player enters non-recoverable state: too stressed to fight effectively, must hide for 2 hours, food spoils, forced death.

**Mitigation:** Lock Q2 answer before WAVE-3 code. Run micro-playtest scenario: "Kill 1 wolf, track stress level" with Wayne observer.

---

## Summary Table: Four Blockers

| # | Issue | Wave | Severity | Status |
|---|-------|------|----------|--------|
| 1 | Silk recipe incentive hierarchy | W4 | **HIGH** | **Requires decision before code** |
| 2 | Stress severity tuning (overwhelmed debuffs too strong) | W3 | **HIGH** | **Requires decision before code** |
| 3 | Web trap size-based mechanics (premature complexity) | W4 | **MEDIUM** | **Requires simplification decision** |
| 4 | Pack tactics coordination (AI complexity vs. payoff) | W5 | **MEDIUM** | **Requires scope decision** |

---

## Decision Framework: Wayne Input Required

**Before WAVE-0 completes**, lock answers to:

1. **Q-CBG-1:** Silk rope use case in Level 1? (Choose Option A/B/C from Blocker #1)
2. **Q-CBG-2:** Stress thresholds & debuff severity? (Choose Option A/B/C from Blocker #2)
3. **Q-CBG-3:** Web trap complexity? (Choose Option A/B/C from Blocker #3)
4. **Q-CBG-4:** Pack tactics scope? (Choose Option A/B/C from Blocker #4)

These decisions can be documented in `.squad/decisions/inbox/wayne-phase4-design-decisions.md` and referenced in WAVE-0 assignments.

---

## Final Assessment

**Phase 4 plan is WELL-ARCHITECTED.** The dependency chain is clean, agent assignments are conflict-free, and testing gates are rigorous. The crafting loop addresses a real Phase 3 gap. Butchery, loot tables, stress injury, spider webs, and silk crafting are all *good ideas*.

**However, four gameplay-scoped decisions are **unresolved** and must be locked before implementation.** These are not architecture issues or style nits — they directly impact **how fun Phase 1 playtesting will be**:

1. Is silk crafting **rewarding** enough to feel like a loop? (Or does food always win?)
2. Does stress **teach caution** or **punish success**?
3. Are web traps **emergent** or **scripted**?
4. Do pack tactics **add depth** or **add busywork**?

---

## VERDICT

**CONDITIONAL APPROVE** ✅

**Phase 4 can proceed to WAVE-0 ONLY AFTER:**
1. Wayne answers Q-CBG-1 through Q-CBG-4
2. Answers documented in `.squad/decisions/inbox/`
3. Blockers converted to spec changes in updated plan

**Proceed to code only when all four blockers are resolved.**

---

## Next Steps (If Wayne Approves Conditionally)

1. Wayne provides Q-CBG answers (30 min)
2. CBG updates Section 10 in plan with Wayne's decisions
3. Bart uses updated plan for WAVE-0 GUID assignment
4. Plan re-submitted to CBG as final (5 min review)
5. Full approval issued → WAVE-0 begins

---

**Signed:** Comic Book Guy, Game Designer  
**Date:** 2026-08-20  
**License:** Creative Direction (Design Department Authority)

---

*This review is filed as `.squad/decisions/inbox/cbg-phase4-review.md` for team merge into `.squad/decisions.md` during WAVE-0.*
