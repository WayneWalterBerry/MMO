# Phase 3 Plan Review — Game Design Perspective

**Author:** Comic Book Guy (Creative Director)
**Date:** 2026-08-16
**Reviewing:** `plans/npc-combat/npc-combat-implementation-phase3.md` v1.0
**Requested by:** Wayne "Effe" Berry

---

## Verdict: CONDITIONAL APPROVE

Phase 3 is a well-structured plan that delivers the **kill→loot→cook→eat** gameplay arc — the single most important loop for making this game feel like a *survival* game and not just a puzzle box. The wave ordering is correct. The dependency chain is airtight. The deferrals to Phase 4 are smart. Bart has clearly learned from Phase 2.

However, there are two blockers and several design concerns that, if left unaddressed, will result in a technically functional but experientially hollow Phase 3.

---

## BLOCKERS (Must Fix Before Execution)

### B1: survival.lua Is Already 43% Over LOC Limit — Must Split in WAVE-0

`src/engine/verbs/survival.lua` sits at **715 LOC** — worse than the 695 LOC combat/init.lua that triggered WAVE-0 in the first place. WAVE-3 adds ~30 LOC of eat handler extensions, pushing it to **~745 LOC**. The plan's WAVE-0 LOC audit *identifies* this but proposes no action. Meanwhile, crafting.lua at 629 LOC will hit ~679 after the cook verb.

**Fix:** WAVE-0 must split survival.lua alongside combat/init.lua. Extract the eat/drink handlers into `verbs/consumption.lua` (~200 LOC) and the sleep/rest handlers into `verbs/rest.lua` (~150 LOC). Same pattern as the combat split. If we don't do this now, we're building WAVE-3 on a module that's already in violation — and the violation gets WORSE.

The plan correctly identifies the combat module as a critical issue at 695 LOC but *ignores* the module that's 20 LOC worse. That's inconsistent. Fix both or explain why survival.lua gets a pass.

### B2: Food Economy Must Be Positive-Sum or the Loop Isn't Worth Doing

The plan specifies cooked rat meat = 15 nutrition, heal 3. But it never contextualizes this against damage taken. If a rat deals 5+ damage per exchange and the cooked meat only heals 3, the kill→cook→eat loop is **net-negative**. The player loses more health killing the rat than they recover eating it.

**Fix:** Before WAVE-3 implementation, Bart and I need to verify: `healing_from_cooked_rat > average_damage_from_killing_rat`. If the numbers don't work, either buff food healing or adjust creature damage downward. The *entire point* of Phase 3 is making this loop rewarding. If it's a losing proposition, players will never cook.

This doesn't need a design doc — it needs a 10-minute spreadsheet comparing rat combat damage output vs. food healing output at various skill levels.

---

## CONCERNS (Should Fix, Not Blocking)

### C1: Dead Wolf Kill Is Anticlimactic — The "Big Kill" Problem

Wolf is the hardest creature to kill in Level 1. Its reward: a gnawed bone (decoration?) and a corpse you can't move, can't cook, and can't butcher until Phase 4. Meanwhile, killing a *rat* gives you portable meat you can cook and eat.

The wolf kill should feel like the biggest victory in Phase 3 — instead it's the least rewarding. **Suggestion:** Give the wolf more interesting inventory. A leather collar with a key? A partially-digested pouch? Something that makes the player say "THAT'S why I fought a wolf." The gnawed bone is flavor but not gameplay.

### C2: Spider "Carrying" Silk Is Physically Absurd

The plan models spider loot as `carried = { "silk-bundle-01" }` — a spider walking around with a silk bundle in its... hands? Spiders *produce* silk from spinnerets. The flavor is completely wrong.

**Suggestion:** Either (a) the silk-bundle should be a `mutations.die` byproduct ("The spider's abdomen splits, spilling a tangle of silk"), not carried inventory, or (b) model it as a harvestable body part with a future `harvest` or `butcher` verb. Option (a) is simpler and works within WAVE-1's death mutation system — no WAVE-2 inventory needed.

### C3: Spoilage Needs Sensory Feedback Per State

The spoilage FSM (fresh → bloated → rotten → bones) is correct, but the plan doesn't explicitly require *sensory text changes per spoilage state*. A bloated rat and a fresh rat should smell VERY different. The on_feel should change (firm → squishy → brittle). This is critical because in darkness, smell and feel are how the player KNOWS the meat has gone bad.

**Requirement:** Each spoilage state MUST have distinct `on_feel`, `on_smell`, and `description` text. This is implied by the FSM but needs to be explicit in Flanders' assignments.

### C4: Cellar Brazier Must Start UNLIT

Q3 recommends a cellar brazier (agreed), but the plan doesn't specify its initial state. If the brazier starts lit, it's a free fire source — no player effort. If it starts unlit (correct), the player must: find match → light brazier → now cook. This creates a satisfying multi-step chain and ties the cooking system to the existing light/fire economy.

**Requirement:** Brazier initial_state = "unlit". Player lights it with fire_source tool. Once lit, it persists (unlike a match). This is the payoff for the candle→match economy.

### C5: Raw Meat Should Be Edible (With Severe Consequences)

The plan says raw cookable food "can't be eaten" with a rejection message. This is too gamey. NetHack, Dwarf Fortress, and every survival game lets you eat raw meat — you just *really shouldn't*.

**Suggestion:** Allow `eat dead rat` but with guaranteed food-poisoning injury. Message: "You gnaw at the raw flesh. It tastes like regret." This teaches cooking through consequence rather than arbitrary rejection. The "Fair Warning" principle (from my injury-puzzle analysis, D-CBG-INJURY-PUZZLES) says: warn, don't wall. The on_smell and on_taste of raw meat should scream "don't eat this" — and then *let them*.

### C6: Bat Meat Should Carry Disease Risk

Dead bat is marked edible/cookable, but bats are the disease vector for rabies in this world. Eating bat meat — even cooked — should have a small food-poisoning risk, or raw bat should carry rabies transmission risk. This creates a risk/reward calculation: bat meat is easy to get (bats are small, plentiful) but dangerous to eat. Rat meat is the "safe" food.

### C7: Gnawed Bone Needs a Gameplay Purpose

The gnawed bone is wolf loot but has no stated use. A bone with no purpose is clutter. **Options:** (a) throwable distraction item (throw bone → creatures investigate sound), (b) improvised weapon (blunt, force 2 — worse than candlestick but better than fists), (c) crafting component for Phase 4. Pick at least one. Don't ship purposeless loot — it teaches players that loot is meaningless.

### C8: Anti-Farming Guard on Respawn Is Too Weak

Q2's timer-based respawn with "player not in room" guard is trivially farmable: leave room, wait 60 ticks, return, kill, repeat. This loop destroys the survival tension.

**Suggestion:** Change guard to "player hasn't visited room in N ticks" (not just "isn't currently there"). If the player was in the cellar 10 ticks ago, the rat shouldn't respawn yet. This requires tracking last-visit-time per room — trivial data, big gameplay difference.

---

## OPEN QUESTION OPINIONS

### Q1: Corpse as Container vs. Scatter — AGREE with Option B

Corpse-as-container is the right call. `search dead wolf` is more immersive than items magically appearing. It enables grave-robbing and corpse-looting as a verb pattern. **One addition:** The death narration MUST hint at lootability. "The wolf collapses. Something glints in its matted fur." Players won't know to search corpses unless the game tells them.

### Q2: Timer-Based Respawn — AGREE with Option A (with C8 caveat)

Timer-based is fine for Phase 3. But strengthen the anti-farming guard per C8 above. The simplicity of timer-based is its virtue — don't add event-based complexity until playtesting proves it's needed.

### Q3: Cellar Brazier — AGREE with Option B (with C4 caveat)

Brazier in the cellar is correct. It creates "cook where you kill" gameplay, which is satisfying. But it MUST start unlit (C4). And a lit candle cooking a rat is NOT physically absurd — people have cooked over candles for centuries. It's just slow and inefficient. Consider: candle cooks at 2× time, brazier cooks at 1× time. This gives both fire sources utility without breaking plausibility.

### Q4: Dead Wolf Not Portable — AGREE with Option B

Wolf stays where it died. Correct. Dead spider should be reviewed — is a giant fantasy spider really "small-item" portable? Check the spider's size definition. If it's wolf-sized, it should also be furniture. If it's cat-sized, small-item is fine.

### Q5: Stress 2-Tier — AGREE with Option A

Ship the foundation. Two tiers is enough for Phase 3. **But:** the first-kill stress trigger MUST have memorable narration. "Your hands shake. The rat lies still. You've never killed anything before." This is a *character moment*, not just a debuff. The narration is what makes stress feel like a game mechanic rather than an arbitrary penalty. Put this in Smithers' assignment, not just Flanders'.

### Q6: Fixed Loot Only — AGREE with Option A

Five creatures don't need randomization. Deterministic loot is better for teaching: players learn "wolves drop things" through consistency. Loot tables are Phase 4 territory when creature variety justifies the complexity.

---

## SCOPE ASSESSMENT

Phase 3 scope is **well-calibrated**. Not too ambitious, not too conservative. The 6-wave structure with gates is proven from Phase 2. The ~190 new tests are appropriate. The deferrals (loot tables, butcher, pack tactics, wrestling) are all correct calls.

**One missing deferral that should be added to Section 11:** Multi-ingredient cooking (e.g., bread requires grain + water + fire) is listed, but **food preservation** (salting, smoking, drying) is not. Players who discover spoilage will immediately ask "how do I preserve food?" Phase 3 should explicitly defer this to Phase 4 so the team doesn't scope-creep into it.

**The biggest scope risk** is the crafting.lua / survival.lua LOC situation. If WAVE-0 doesn't split both modules, WAVE-3 becomes a dangerous build-on-top-of-violation situation. Fix the foundation before building the house.

---

## SUMMARY

| Category | Count |
|----------|-------|
| **Blockers** | 2 |
| **Concerns** | 8 |
| **Open Question Agreements** | 6/6 (with caveats on Q2, Q3, Q5) |

The kill→loot→cook→eat arc is the right thing to build. The wave structure is solid. The plan just needs: (1) survival.lua split in WAVE-0, (2) food economy validation before WAVE-3, and (3) attention to the design details that turn a *functional* system into a *fun* one — sensory feedback on spoilage, raw meat as punishment not rejection, loot that matters, and stress that has narrative weight.

Worst. Plan gap. Ever? No. But fixable? Absolutely. Fix the blockers, address the concerns, and this plan ships a Phase 3 that makes the game feel *alive*.

— Comic Book Guy, Creative Director
