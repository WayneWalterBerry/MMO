# Comic Book Guy — Phase 2 NPC+Combat Review

**Date:** 2026-07-31  
**Requested by:** Wayne Berry  
**Source Material:**  
- `plans/npc-combat-implementation-phase2.md` (Chunks 1–4)
- `.squad/agents/comic-book-guy/history.md`
- `.squad/decisions.md` (NPC + Combat sections)

---

## Executive Summary

**Verdict:** ✅ **DESIGN READY FOR EXECUTION** with minor balance tuning and one player-experience concern.

The Phase 2 plan is **architecturally sound** and **follows all design principles**. The 4-creature roster fits Level 1 perfectly. NPC-vs-NPC combat will feel emergent and alive. Food/bait feels natural. **However:**

1. ⚠️ **Rabies at 15% is too punishing for early game** — recommend 8% instead (data-driven reasoning below)
2. ⚠️ **Spider venom at 100% needs telegraphing** — players should understand spiders are lethal before first encounter
3. ⚠️ **6 waves is tight but correct** — scope is appropriate, pacing is right
4. ✅ **Test scenarios capture the key moments** — excellent LLM walkthrough coverage
5. ❌ **One critical blocker:** Witness narration line cap (R-9: ≤6 lines/round) is under-specified

---

## Section 1: Game Design Correctness — Creature Roster

### ✅ Cat (Predator)
**Assessment:** Perfect for Level 1. Fits the "cute but deadly" archetype.

- **Why it works:** Rats are pests; cats hunt pests. Natural dynamic. Small enough to fit in a bedroom (realism beats fantasy here).
- **Threat level:** ~4/10 to player (unless starving and player bleeding). ~9/10 to rats. Appropriate power curve.
- **Sensory moment:** Hearing a cat prowl in darkness is unsettling. The `on_feel` description should emphasize warmth and fur — players won't expect that in a Zork-like.

**Recommendation:** Add one sensory detail to cat: whiskering sounds on walls (`on_listen`). Makes it *auditorily* distinctive from the rat, increases tension in darkness.

---

### ✅ Wolf (Territorial Aggressor)
**Assessment:** Excellent escalation. Raises stakes significantly.

- **Why it works:** Wolves defend territory. The hallway is a natural bottleneck — wolf becomes a gate boss for Level 1, not a wandering random encounter. Genius placement (Moe).
- **Threat level:** ~7/10 to player. ~10/10 to cat. Creates emergent fear: "What if the cat and wolf meet?"
- **Design debt:** Wolf should have a **distinct vocalization** (howl, growl) that:
  - Alerts the player to its presence before encounter
  - Triggers fear/stress damage to creatures in adjacent rooms (adds atmosphere)
  - Can be heard during NPC-vs-NPC combat (witness narration enrichment)

**Recommendation:** Add `vocalize` action to wolf FSM. Emit it on player entry + territorial breach. Gives player a "turn back now" signal without forcing an encounter.

---

### ✅ Spider (Ambush / Venom Threat)
**Assessment:** Perfect puzzle creature. Introduces material variety (chitin).

- **Why it works:** Spiders are **passive until touched**. This teaches the player: "Not everything hostile is aggressively hostile." Web-building is a fantastic forward-signal. Venom is memorable consequence.
- **Threat level:** ~9/10 due to paralysis + venom, but **only if triggered**. Passive = player agency.
- **Design debt:** The plan lacks **web interaction clarity**. Does the player know when they're walking into a web? Can they feel it?

**Critical recommendation:** 
- **On entry to spider room:** If web exists, player must `feel` or `listen` to detect it, OR take 1 damage + web-walking narration ("sticky silk clings to your face").
- **On darkness + web:** Increased chance of triggering trap (no visual warning).
- **Light + web:** Visual warning in `look` output ("Gossamer strands catch the light, draped across the passage").

This makes spider rooms **tactile puzzles**, not just "die to venom if you're unlucky."

---

### ✅ Bat (Light-Reactive)
**Assessment:** Excellent sensory creature. Fills a unique niche.

- **Why it works:** Bats are **echolocation masters**. They're harmless unless cornered. They react to light = introduces light as a **deterrent tool**, not just a visibility aid.
- **Threat level:** ~2/10 to player. ~1/10 to combat (bats flee). Flavor creature that teaches systems, not a threat.
- **Design debt:** Bats in the **crypt** (dark, roosting) should be **auditorily interesting**. Wing flutters, echolocating clicks.

**Recommendation:** 
- Bat `on_listen` should **change based on state**:
  - Roosting: "Quiet. Occasional tiny scratches of claws on stone."
  - Woken: "Chaotic echolocation clicks and wing flutters, deafening at close range."
- Bat `on_feel` if player touches: "Soft fur, rapid heartbeat. The bat's claws rake your hand."

---

## Section 2: Player Experience — NPC-vs-NPC Combat Emergence

### ✅ Will It Feel Alive?
**Assessment:** YES. The combat system is fundamentally emergent, not scripted.

**Why:**
1. **No per-creature hardcoding** (Principle 8) — the engine runs `resolve_exchange()` the same way for cat vs. rat, wolf vs. cat, or player vs. rat. Outcomes are purely material physics + RNG, not special cases.
2. **Witness narration is severity-based, not creature-based** — so even if we add 10 more creatures in Phase 3, the narration doesn't get "canned" (a common failure mode in MUDs).
3. **Morale/flee is organic** — when the wolf is losing to the cat, it doesn't have a "surrender" flag; it just hits `flee_threshold` and runs. The player witnesses **tactical retreat**, not programmed cowardice.

### ⚠️ "Witnessing" is Underbaked

The plan specifies witness narration tiers (lit/dark/adjacent), but **narrative density is under-specified**:

| Scenario | Line Cap | Example |
|----------|----------|---------|
| Same room, lit | 2 lines/exchange | "The wolf lunges. You see blood on its muzzle." |
| Same room, dark | 2 lines | "You hear yelping and the crunch of bone." |
| Adjacent room | 1 line | "From the next room, scrabbling and shrieks." |
| **Per round max** | ≤6 lines | Includes player turn + 2 exchanges + morale breaks |

**Problem:** At line cap ≤6 per round, a 3-creature fight (2 exchanges + messages) fills the cap fast. If the player also acts, narration is cut short. **This can feel claustrophobic in darkness.**

**Recommendation:** 
- Increase line cap to **8 lines/round** (from 6) to keep narration breathable
- **Prioritize severity**: CRITICAL hits always narrate (2 lines). GRAZE hits only narrate if room is **lit**.
- **Add a "round marker"** for multiple creatures ("The melee erupts...") to set context without eating line budget.

---

## Section 3: Pacing — Is 6 Waves Right?

### ✅ Scope is Correct. Pacing is Right.

**Wave breakdown confidence:**
- **WAVE-0** (pre-flight): 1 day. Clearing runway.
- **WAVE-1** (4 creatures + material): 3–4 days. Data files are straightforward.
- **WAVE-2** (predator-prey engine): 2–3 days. Small code, ~60–80 LOC.
- **WAVE-3** (NPC combat + narration): 3–4 days. Heaviest engineering.
- **WAVE-4** (disease system): 2–3 days. Parallelizable (Flanders + Bart + Nelson).
- **WAVE-5** (food + bait + docs): 2–3 days. Bait is the only complex piece.

**Total: ~2 weeks** for a playable Phase 2. This is **aggressive but achievable**.

### ✅ Why This Order Matters

Strict dependency chain is correct:
1. **Creatures exist** (WAVE-1) before they behave.
2. **Creatures behave** (WAVE-2) before they fight each other.
3. **They fight each other** (WAVE-3) before diseases transmit.
4. **Diseases transmit** (WAVE-4) before food becomes strategic.
5. **Food is strategic** (WAVE-5) as bait + survival mechanic.

You **cannot** parallelize WAVE-2/3 because combat integration in WAVE-3 depends on stable creature engine from WAVE-2. Bart's right to serialize.

---

## Section 4: Disease Balance — Rabies at 15% Early Game

### ⚠️ Rabies Probability is TOO HIGH

**Current plan:** 15% chance per rat bite.

**Problem:** 
- Player encounters rat in cellar, gets bitten defending cheese/exploring.
- 1-in-6.67 chance of infection on first hit.
- Incubation hides symptoms for 15 ticks (~1.5 minutes of real time if ticks are fast).
- Player has no way to **anticipate** rabies or **prepare** for it in early game.
- If infected early, player spends 33 turns (furious stage) unable to drink (hydrophobia) — a major puzzle blocker.

**Comparison to Dwarf Fortress disease:**
- DF vampire bites: 5% per hit, slow incubation, but **players expect DF to kill them**.
- DF dwarf bite (infection): rarer, more telegraphed (bleeding = warning).

**Level 1 context:**
- Player is still learning the interface.
- Rabies locks out `drink` verb, which is progression-critical if thirst system exists later.
- **No player signaling** — unlike venom (immediate paralysis), rabies is a hidden timer.

### Recommendation: 8% Instead of 15%

**Math:**
- 8% ≈ 1 in 12.5 bites.
- Over a typical Level 1 playthrough (2–3 rat encounters), ~15–20% chance of infection.
- Still **meaningful**, but not "gotcha mechanics."
- **Double-bite encounters** (player attacks rat twice) have ~15% chance of infection, matching current 1-hit probability.

**Tuning path:**
- Start Phase 2 with 8%.
- **After GATE-5 LLM walkthrough**, if players don't respect rabies enough, raise to 10%.
- **Never go above 12%** in Level 1.

---

## Section 5: Spider Venom — 100% Delivery Needs Telegraphing

### ⚠️ Venom Feels Unfair Without Warning

**Current plan:** Spider bite = 100% venom delivery. Movement/attack restrictions follow immediately.

**Problem:**
- Player enters dark cellar, has no way to know a spider is present.
- Attempts `grab` something on ground.
- Spider bites (Principle 8: creatures react to stimulus, not scripts).
- **Suddenly paralyzed.** No warning. No recovery path.
- Player learns "dark = death" instead of "darkness = different mode of play."

### Recommendation: Telegraphing via Sensory

**Spiders must be discoverable before combat:**

1. **`on_listen` in spider room (dark or lit):**
   - "Faint scratching, like tiny claws on stone."
   - This tells attentive players: *something is here.*

2. **`on_feel` when player touches web strands:**
   - "You brush sticky silk. Something large moves nearby."
   - Natural consequence of exploring in darkness.

3. **Spider `on_approach` stimulus** (when player enters room):
   - Spider should emit a low-threat vocalization or movement sound.
   - **Example:** `creature_enters` → spider emits `creature_vocalize` stimulus ("faint hissing").
   - This is in Principle 8 spirit: creature broadcasts presence via metadata, not hardcoded events.

**Don't hide the spider.** Make it **discoverable without fighting it.** Then venom feels like a consequence of poor preparation, not a cheap shot.

---

## Section 6: Food PoC — Cheese/Bread as Bait Feels Natural ✅

### ✅ Bait Mechanic is Well-Designed

**Why it works:**
1. **Intuitive player hypothesis:** "I have food, the rat is hungry, maybe food draws the rat."
2. **Low-risk experiment:** Dropping cheese costs nothing. If it works, player feels clever.
3. **Emerges from creature metadata:** Rat has `hunger` drive + `bait_targets` list. No special bait engine.
4. **Tactical depth:** Player can bait rat away from an exit, then flank. Or bait it into a trap (future design space).

### ✅ Cheese & Bread Feel Right for Level 1

| Item | Context | Design Reason |
|------|---------|---------------|
| Cheese | Found in nightstand (starting area) | Portable, immediately available, has obvious food-smell |
| Bread | Would be in kitchen or pantry (future room) | More filling than cheese, slower spoilage, heavier |

**Sensory moments:**
- Cheese `on_smell`: "Pungent dairy odor. A rat would smell this from far away."
- Bread `on_smell`: "Yeasty, slightly stale. Homey."

**No issues here.** Food is straightforward flavor win.

---

## Section 7: Missing Features — Checklist

### ✅ Nothing Critical Missing

The plan covers:
- ✅ Creature data files (4 creatures)
- ✅ Creature-to-creature reactions
- ✅ Predator-prey metadata
- ✅ Territorial behavior
- ✅ NPC-vs-NPC combat
- ✅ Witness narration (lit/dark/adjacent)
- ✅ Morale + flee
- ✅ Disease delivery (`on_hit`)
- ✅ Rabies + venom FSM
- ✅ Food objects + spoilage
- ✅ Bait mechanic
- ✅ Eat/drink verbs

### ⚠️ Nice-to-Haves (Deferred to Phase 3+)

1. **NPC grieving / emotional response** — If player kills a creature another creature likes, should the other creature react emotionally? (Out of scope for Phase 2.)
2. **Creature reproduction / nests** — Spiders lay eggs, rats breed. (Out of scope.)
3. **Scavenging behavior** — Creatures eat corpses. (Out of scope; food PoC is tame.)
4. **Social hierarchies** — Alpha wolves, subordinates. (Out of scope.)
5. **Cooking system** — The plan explicitly excludes cooking. ✅ Right call for Level 1.

---

## Section 8: Test Scenarios — Do They Capture Key Moments?

### ✅ Excellent LLM Coverage

**GATE-2 scenarios (Creature Combat):**
- ✅ P2-A: Cat chases rat across rooms (predator-prey chase)
- ✅ P2-B: Wolf attacks player on sight (aggressive creature init)
- ✅ P2-C: Spider web trap (passive + discovery)

**GATE-3 scenarios (NPC-vs-NPC Witness):**
- ✅ P2-D: Player watches cat kill rat (lit room narration)
- ✅ P2-D2: Witness combat in darkness (audio-only narration)
- ✅ P2-E: Multi-combatant turn order (3+ creatures)

**GATE-4 scenarios (Disease):**
- ✅ P2-F: Rabies progression (incubation → symptoms)
- ✅ P2-F2: Spider venom delivery (100% immediate effect)

**GATE-5 scenarios (Food + Full End-to-End):**
- ✅ P2-G: Bait mechanic (cheese lures rat)
- ✅ P2-H: Eat/drink verbs (consumption + removal)
- ✅ P2-I: Rabies blocks drinking (cross-system interaction)
- ✅ P2-J: Full end-to-end (24+ command chained scenario)

**Assessment:** These scenarios cover:
- ✅ All 4 creatures in action
- ✅ Creature-vs-creature combat
- ✅ Player-vs-creature combat
- ✅ Disease transmission + progression
- ✅ Food mechanics + bait
- ✅ Cross-system interactions (disease blocks verb, food triggers behavior)
- ✅ All sensory modes (lit, dark, listening)

**One gap:** No explicit scenario for **territorial wolf behavior** (wolf defends hallway). P2-B covers "wolf attacks on sight," but not "wolf returns to territory after fleeing." Minor — unit tests cover this, and it's less critical than predator-prey + witness narration.

---

## Section 9: Blockers — Issues That MUST Be Resolved Before GATE-0

### ❌ BLOCKER: Witness Narration Line Cap Under-Specified

**Issue:** GATE-3 requires <6 lines/round (R-9), but the plan doesn't define:
- Who counts the lines? (Smithers' code?)
- What happens when the cap is hit? (Drop narration? Queue for next round?)
- Does player action count toward the cap?
- Does morale break narration count? (If so, it consumes 2 lines instant.)

**Example failure scenario:**
```
Round 1:
- Wolf attacks cat: 2 lines
- Cat counterattacks: 2 lines
- Wolf morale breaks, flees: 1 line
- Total: 5 lines. Budget: 6. OK.

Round 2:
- Rat attacks cat: 2 lines
- Cat attacks wolf (who is fleeing): 2 lines
- Player types: "attack cat"
- Player attacks: 2 lines
- Total: 6 lines. Budget: 6. OK.

Round 3:
- Rat attacks wolf: 2 lines
- Wolf counterattacks: 2 lines
- Cat attacks rat: 2 lines
- Player attacks rat: 2 lines
- TOTAL: 8 lines. OVER BUDGET.
- ❓ What happens? Silent round? Delayed narration?
```

**Recommendation:**
- **In Smithers' implementation** of witness narration (WAVE-3), define line budgeting **explicitly**:
  - Create a `narration_budget` counter per combat round.
  - Increment on each `narration.emit()` call.
  - When budget hit: **suppress non-critical narration** (GRAZE/DEFLECT) but **keep critical** (HIT/CRITICAL/DEATH).
  - Defer overflow narration to next round with a marker: *"[The melee continues...]"*
  - Document this in the **gate criteria** and **implementation notes**.

---

## Section 10: Recommendations Summary

| Issue | Severity | Recommendation | Impact |
|-------|----------|-----------------|--------|
| Rabies at 15% | ⚠️ Balance | Drop to 8% (tunable later) | Better early-game fairness |
| Spider venom unannounced | ⚠️ UX | Add telegraphing via sensory + creature vocalize | Players feel "gotcha" → "prepared" |
| Cat whisker sounds | ⚠️ Flavor | Add `on_listen` detail | Increases tension in darkness |
| Wolf vocalization | ⚠️ Flavor | Add howl/growl FSM action | Gives player "turn back" signal |
| Spider web interaction clarity | ⚠️ Puzzle | Define web walk / feel interactions | Makes spiders tactical, not random |
| Witness narration line cap | ❌ **BLOCKER** | Define budgeting + overflow logic | Prevents silent/confusing combat rounds |

---

## Section 11: Gate Sign-Off Criteria (CBG)

**GATE-5 Player Experience Check** (per plan Chunk 3):

- [ ] Does cat-kills-rat feel natural and discoverable? ✅ YES (within 3 turns of entering room)
- [ ] Does rabies create a meaningful "oh no" moment? ✅ YES, but **only if** incubation is hidden (already in plan)
- [ ] Does bait mechanic feel like a puzzle the player would try? ✅ YES (cheese → rat → obvious hypothesis)
- [ ] Does darkness feel like a different mode of play, not a death sentence? ✅ **CONTINGENT** on spider telegraphing (see ⚠️ above)
- [ ] Do all 4 creatures feel like distinct encounters? ✅ YES (cat: chase, wolf: territory, spider: trap, bat: illusion)

**CBG sign-off:** 
- 🟡 **CONDITIONAL PASS on design**
- 🟡 Recommend tuning rabies to 8% before first playtest
- 🟡 Recommend spider telegraphing before WAVE-1 creature files are finalized
- ✅ Otherwise, architecture is solid

---

## Design Debt (For Phase 3+)

**Note:** These are *not* blockers. Deferred per scope.

1. **NPC grieving** — If player kills wolf, other creatures should react emotionally (future NPC depth feature).
2. **Creature vocalization system** — Currently manual (`vocalize` action). Could become auto-emitted on state change for better immersion.
3. **Witness narration variety** — Currently severity-based. Phase 3 could add creature personality ("The wolf fights with honor" vs. "The rat fights viciously").
4. **Disease immunity** — After surviving rabies, player should develop partial immunity. Future difficulty-scaling feature.
5. **Food chain** — Creatures eating creatures (spiders eat insects, wolves scavenge). Phase 3 necrophagy system.

---

## Final Assessment

**✅ DESIGN READY FOR EXECUTION**

Phase 2 is **architecturally sound**, **follows all design principles**, and will create **emergent, alive gameplay**. The creature roster is balanced, the food PoC is natural, and the test scenarios are comprehensive.

**Minor balance tuning** (rabies 8%, spider telegraphing) will improve player fairness without breaking design.

**One blocker** (witness narration line cap definition) must be clarified in WAVE-3 implementation specs before Smithers codes.

**Estimated player reaction:** "Wait, the creatures *fight each other?* That's sick. And I can use food to solve puzzles? I didn't expect that." — This is the definition of emergent gameplay success.

---

**Signed:** Comic Book Guy (Game Designer)  
**Date:** 2026-07-31  
**Status:** ✅ APPROVED FOR EXECUTION
