# Injury ↔ Puzzle Integration — Strategic Design Analysis

**Author:** Comic Book Guy (Design Lead)  
**Date:** 2026-07-25  
**Status:** DESIGN ANALYSIS  
**Depends On:** Injury designs (this folder), healing-items.md, puzzle-designer-guide.md, level-01-intro.md  
**Audience:** Wayne (Creative Director), Sideshow Bob (Puzzle Designer), Bart (Engine), Flanders (Objects)

---

## Preamble: Why This Document Exists

Bob's five injury designs are excellent *in isolation*. Each one reads like a self-contained system — cause, symptoms, FSM, treatment, puzzle uses. But injuries don't exist in isolation. They exist inside puzzles, alongside other injuries, against a ticking resource clock, in rooms the player may or may not have explored yet.

This document asks the question: **How do injuries and puzzles make each other better?**

The answer breaks into six interlocking patterns. Each pattern is a design lens — a way to think about every puzzle we build from this point forward.

---

## 1. Injuries AS Puzzles

> The injury *is* the puzzle. Getting hurt creates a problem the player must solve.

### 1.1 The Ticking Clock

Bleeding and nightshade poisoning are over-time damage. Every turn the player spends NOT treating the injury is a turn closer to death. This transforms the entire game into a puzzle the moment the injury fires.

**Design pattern:**
- Injury inflicted → health draining → player must locate treatment → treatment is N rooms away → every movement command costs a turn → the route itself is the puzzle

**Level 1 example — Bleeding in the Cellar:**
> Player falls onto debris in the cellar. Bleeding starts. Bandage material (blanket, curtains) is in the bedroom — UP the stairway, through the trap door, across the room. That's 3-4 movement commands minimum. Each one costs a turn. Each turn costs health. The player must decide: do I retrace my steps for the blanket, or is there cloth closer? (The grain sack in the storage cellar — if they've reached it — could be torn for cloth.)

**The clock teaches:** urgency discrimination. Minor cuts don't tick. Bruises don't tick. Bleeding and poison DO tick. The player learns to read the `injuries` verb and assess: "Is this urgent? Do I have time to explore, or do I need to act NOW?"

### 1.2 Resource Scarcity

Level 1 has limited cloth sources: blanket, curtains, wool-cloak (wardrobe), grain sack. Each can be torn into bandage strips. But cloth is also needed for sewing (skill system), fire bundles, and cleaning. If the player has already used cloth for other purposes, they may face:

> **5 possible wounds. 3 remaining cloth sources. Which wounds get the bandage?**

This is a triage puzzle. The `injuries` verb gives the player enough information to prioritize: bleeding (lethal, must bandage) over minor cut (self-heals, save the cloth). But the player doesn't know this until they've experienced both injury types. The minor cut — the first, gentlest injury — exists specifically to calibrate: "This heals on its own. Don't waste resources on it."

**Design principle:** Scarcity isn't about punishing the player. It's about making choices meaningful. There should always be ENOUGH resources in Level 1 — but the player shouldn't KNOW that. The tension is psychological.

### 1.3 Treatment Matching

Nightshade poisoning is the crown jewel of the treatment-matching puzzle. The injury names the poison ("nightshade"). The antidote labels itself ("Contra Belladonna"). But the player must connect:

1. **Nightshade** (injury description) = **Belladonna** (antidote label) — a knowledge gate
2. Generic antidote ≠ nightshade antidote — a specificity lesson
3. Bandages don't cure poison — a category lesson

This is a three-layer puzzle embedded in a single injury:
- **Layer 1:** Identify the poison (read `injuries`)
- **Layer 2:** Find the matching cure (explore, read labels, connect knowledge)
- **Layer 3:** Apply it correctly (drink the antidote, don't try to bandage it)

**Burns add a variant:** The treatment (cold water) requires the player to connect "burn" → "need cooling" → "water exists in the courtyard" → travel to water source → apply. The dry-cloth "near miss" ("if the cloth were WET and COOL") is a designed teaching moment — a wrong answer that points toward the right one.

### 1.4 The Diagnosis Puzzle

Before the player can treat anything, they must figure out WHAT they're suffering from. The `injuries` verb is their diagnostic tool. But consider:

- **Nightshade stage 2:** Hallucinations corrupt room descriptions. Can the player still trust their `injuries` output? (Yes — injuries are always reliable. But the player doesn't know that yet. The uncertainty IS the puzzle.)
- **Stacked injuries:** Bleeding AND burned AND bruised. The `injuries` verb lists all three. The player must triage: which is urgent (bleeding), which needs specific treatment (burn → water), which just needs time (bruise → rest)?
- **Delayed symptoms:** A minor cut shows up immediately. But what if a future injury has a delayed onset? The player feels fine for 3 turns, then symptoms appear. Diagnosing means noticing something changed.

**Design principle:** The `injuries` verb should always be honest and informative. The puzzle is in the READING and PRIORITIZING, not in hiding information. We are not trying to trick the player — we're teaching them to think like a field medic.

---

## 2. Puzzles CAUSING Injuries

> The puzzle's failure state is an injury. Getting hurt is the consequence of a wrong approach.

### 2.1 Failed Puzzle Attempts

Every puzzle should ask: **what happens when the player gets it wrong?** Injury is the answer for physical puzzles.

| Puzzle Situation | Wrong Approach | Injury Inflicted | Severity |
|-----------------|---------------|-----------------|----------|
| Open locked door | Force it / kick it | Bruised (legs/foot) | Low |
| Take lit candle | Grab flame directly | Burn (hand) | Low-Med |
| Handle glass shard | Pick up barehanded | Minor cut (hand) | Low |
| Drink poison bottle | Consume without investigation | Nightshade poisoned | HIGH |
| Jump from window | Leap without rope/preparation | Bruised (legs) | Low |
| Reach into dark container | Blind groping with dagger inside | Minor cut / Bleeding | Low-Med |

**Key insight:** The severity of the injury should match the recklessness of the approach. Grabbing a flame is careless (minor burn). Drinking an unknown liquid is dangerous (lethal poison). The injury IS the lesson about how badly the player misjudged the situation.

### 2.2 Environmental Hazards

Rooms themselves can be dangerous. The environment inflicts injuries through normal traversal.

| Room / Area | Hazard | Injury | Trigger |
|------------|--------|--------|---------|
| Cellar stairs | Steep, slippery steps in darkness | Bruised (legs) | Descending without light |
| Bedroom floor | Glass shards (after breaking window) | Minor cut (feet) | Walking through without light |
| Storage cellar | Rusty nail / sharp edge on crate | Minor cut (hand) | Blind searching |
| Courtyard | Fall from bedroom window | Bruised (legs) | Window escape route |
| Deep cellar | Ancient debris, uneven floor | Bruised (varies) | Careless movement in dark |

**Design pattern — The Darkness Tax:** Moving through rooms in darkness should occasionally cost the player a minor injury. Not every time (that would be tedious), but often enough that lighting a room before searching it becomes instinctive. The injury teaches: **light is not just about seeing — it's about safety.**

### 2.3 Traps

Traps are premeditated injuries. Someone placed them. They have a purpose in the story.

**Level 1 trap candidates:**

1. **Needle in the pillow** — The pin (`pin` object) in the bedroom pillow. Feeling the pillow in darkness → prick → minor cut. This is the first trap the player encounters, and it's barely a trap at all. It teaches: not everything you touch is safe.

2. **Dagger in the sarcophagus** — The silver dagger in the crypt. Reaching into the stone coffin in darkness → hand meets blade → bleeding. This is a serious trap in a late-game room. The injury severity matches the location's danger.

3. **Poison bottle** — The ultimate trap. It's sitting right there on the nightstand, accessible from the start. Nothing stops the player from drinking it. The "trap" is the player's own curiosity.

**Design principle:** Level 1 traps escalate in severity from trivial (pin prick) to moderate (dagger cut) to lethal (poison). This teaches the player to increase caution as they go deeper. The bedroom is relatively safe. The crypt is not.

### 2.4 Combat-Adjacent Injuries (Future)

Level 1 has no combat system, but injuries lay the groundwork:
- A rat in the storage cellar could bite (minor cut — trivial, but teaches "creatures can hurt you")
- An NPC encounter in Level 2 could inflict bleeding (escalation from Level 1's self-inflicted injuries)
- The injury system already supports `weapon_attack` as a cause — the framework is ready

---

## 3. Injuries BLOCKING Puzzles

> The injury creates a gate. You must heal before you can proceed.

### 3.1 Capability Gates by Injury Type

Each injury type restricts specific player capabilities. These restrictions interact with puzzles that REQUIRE those capabilities.

| Injury | Restricted Capability | Puzzles Blocked |
|--------|----------------------|-----------------|
| **Bruised legs** | Climbing, jumping, running | Courtyard ivy climb, window return, any vertical movement |
| **Bruised head** | Examination clarity, reading | Reading scroll inscriptions, detailed object examination |
| **Bruised torso** | Carrying heavy objects | Moving crates, lifting sarcophagus lids, pushing furniture |
| **Bleeding (active)** | Grip reliability, climbing | Holding objects (drop chance), climbing (slip risk), any precision task |
| **Burn (hand)** | Gripping objects, tool use | Lockpicking, sewing, carrying candle holder, any hand-intensive task |
| **Nightshade poisoned** | Vision (stage 1), all actions (stage 2) | Reading, precise actions, navigation (hallucinations corrupt room descriptions) |

### 3.2 The "Heal to Progress" Gate

This is a explicit design pattern: the player CANNOT solve the next puzzle until they treat their current injury.

**Level 1 example — Bruised Legs + Ivy Climb:**
> Player jumped from the bedroom window → bruised legs → lands in courtyard. The exit from the courtyard requires climbing the ivy on the wall (Puzzle 013). But bruised legs block climbing. The player must REST in the courtyard until the bruise recovers before they can climb. This forced downtime encourages courtyard exploration — the well, the rain barrel, the cobblestones. The injury-gate redirects the player toward content they'd otherwise skip.

**Level 1 example — Burned Hand + Lockpicking:**
> Player grabbed the lit candle (burn) → now needs to use the brass key on the iron door. Severe burn impairs grip → key fumbling, potential drop → must treat burn (find water in courtyard rain barrel) before reliably using keys and tools. The burn-gate forces the player to explore the courtyard for water BEFORE proceeding underground.

### 3.3 Stacking Multiplies Gates

Two injuries at once can create compound blocks:

> **Bleeding arm + bruised legs:** Can't climb (bruise) AND can't grip reliably (blood). The player is effectively stuck until they treat at least one. The triage decision becomes: bandage the arm (stop the ticking clock) or rest the legs (restore mobility)? Bandaging is usually correct because bleeding is lethal and bruising is not — but the player must reason this out.

**Design principle:** Injury stacking should never create unwinnable states. There must always be a treatment path available. The compound block creates URGENCY and DIFFICULT CHOICES, not dead ends.

---

## 4. Treatment AS Puzzles

> Finding and applying the cure is itself a multi-step puzzle.

### 4.1 Crafting the Cure

No healing item in Level 1 is found ready-to-use. Every treatment requires preparation.

| Treatment | Crafting Chain | Steps |
|-----------|---------------|-------|
| **Cloth bandage** | Find cloth source → TEAR cloth → apply to wound | 3 steps (locate → craft → apply) |
| **Cool damp cloth** | Find cloth → find water → WET cloth → apply to burn | 4 steps (locate cloth → locate water → combine → apply) |
| **Cold water (burn)** | Find water source → POUR/SPLASH on burn | 2 steps (locate → apply) |
| **Rest (bruise)** | Find safe location → REST/SLEEP | 2 steps (locate → action) |
| **Nightshade antidote** | Find vial → identify it → DRINK | 3 steps (locate → diagnose → apply) |

**The crafting chain IS the puzzle.** The player doesn't just "use healing item." They discover raw materials, transform them, and apply them. Each step requires knowledge the game has been teaching:

- TEAR is a verb learned from fabric objects (blanket examination hints at tearability)
- WET is a verb learned from water sources (rain barrel, well)
- DRINK is a verb learned (dangerously) from the poison bottle experience
- REST is a verb that the game explicitly names in bruise descriptions

### 4.2 Ingredient Scattering

Treatment components are deliberately placed in different rooms, creating fetch-puzzle pressure.

**Burn treatment example:**
- **Burn happens in:** Bedroom (candle) or cellar (torch bracket)
- **Water is in:** Courtyard (rain barrel, well) — a completely different area
- **Cloth for wet compress is in:** Bedroom (blanket, curtains) — back where you started

The player must mentally map: "I'm burned. I need water. Water is in the courtyard. How do I get to the courtyard?" This spatial reasoning — connecting NEED to LOCATION to ROUTE — is puzzle thinking.

### 4.3 Knowledge Gates

Some treatments require knowledge the player may or may not have acquired:

| Knowledge | Source | What It Unlocks |
|-----------|--------|----------------|
| "Cloth can be torn into bandages" | Examining blanket: *"threadbare — you could tear strips"* | Bandage crafting |
| "Burns need cold water" | Burn symptom text: *"Cool water would soothe this"* | Burn treatment |
| "Nightshade = Belladonna" | Tattered scroll in deep cellar OR herbal medicine text | Antidote identification |
| "Rest heals bruises" | Bruise symptom text: *"Time and staying off your feet"* | Bruise recovery |
| "Dry cloth doesn't help burns" | Failed treatment: *"if the cloth were WET and COOL"* | Wet-cloth treatment path |

**The prepared player vs. the reactive player:** Someone who reads every object description, examines every scroll, and smells every vial will have pre-loaded knowledge when injuries strike. Someone who rushes through will have to learn under pressure. Both paths work — the game rewards curiosity but doesn't punish urgency.

### 4.4 The Medical Text Pattern

A tattered scroll or book somewhere in Level 1 (deep cellar altar, or a shelf in storage) that describes injuries and their treatments in clinical terms. This is the "prepared adventurer" resource — finding it before getting hurt gives the player a reference guide. Finding it WHILE hurt gives them urgent actionable information.

**Proposed content for the tattered scroll (medical section):**
> *"On wounds that bleed: bind with clean cloth, firmly wrapped. The bleeding stops, but the wound needs rest to close."*  
> *"On burns of the skin: cool water, applied quickly. Delay invites blistering."*  
> *"On the poisoner's art: each venom has its counter. Nightshade answers to Belladonna's cure — mark the label well."*  
> *"On bruises of the bone: only patience mends what force has broken. Rest, and let time do its work."*

This scroll is a Level 1 cheat sheet. It doesn't solve puzzles directly — it gives the player the vocabulary to solve them. The player still needs to FIND the cloth, FIND the water, FIND the antidote. But they know what to look for.

---

## 5. Injury + Engine Hooks

> How injuries wire into the event-handler system that already exists.

### 5.1 Existing Hook: `on_traverse`

The `wind_effect` handler already fires on exit traversal. Injury-causing traverse effects follow the same pattern.

**Proposed: `injury_effect` handler on `on_traverse`**

```lua
exits = {
  down = {
    target = "cellar",
    on_traverse = {
      type = "injury_effect",
      condition = "no_light",  -- only fires in darkness
      injury = "bruised",
      body_part = "legs",
      description = "You stumble on the uneven stairs in the dark. Your knee cracks against stone.",
      prevention = { "has_light" }  -- carrying a light source prevents this
    }
  }
}
```

**Level 1 applications:**
- **Bedroom → Cellar (trap door stairway, dark):** Bruised legs if descending without light
- **Cellar → Storage Cellar:** No injury (flat passage, iron door)
- **Storage Cellar → Deep Cellar:** Minor cut from brushing rough-hewn wall in darkness
- **Bedroom → Courtyard (window):** Bruised legs from fall (always, light doesn't help)

**Prevention as puzzle:** The `prevention` field means injuries from traversal are AVOIDABLE. The player who lights a candle before descending the stairs doesn't get bruised. The injury teaches: **prepare before you move.**

### 5.2 Future Hook: `on_pickup`

Objects can cause injuries when picked up.

**Proposed: `injury_effect` on `on_pickup`**

```lua
-- Glass shard object metadata
on_pickup = {
  type = "injury_effect",
  injury = "minor_cut",
  body_part = "hand",
  description = "The glass edge catches your palm. A thin line of blood wells up.",
  prevention = { "wrapped_in_cloth", "wearing_gloves" }  -- wrapping prevents injury
}
```

**Level 1 applications:**
- **Glass shard:** Minor cut on pickup (already designed, `on_feel_effect: "cut"`)
- **Lit candle (bare):** Burn on pickup (already designed, `on_take_effect: "burn"`)
- **Silver dagger (blade-first):** Minor cut when reaching blindly into sarcophagus
- **Hot torch:** Burn on pickup if grabbed from bracket barehanded

**Prevention as puzzle:** Wrapping the glass in cloth before pickup (skill: preparation). Using the candle-holder instead of grabbing flame. These preventions ARE puzzles.

### 5.3 Future Hook: `on_timer`

Untreated injuries worsen over time. The engine needs a timer system that fires injury-state transitions.

**Proposed: `injury_timer` system**

```lua
-- Bleeding injury template
timers = {
  infection_cascade = {
    trigger_state = "active",     -- fires while bleeding is active
    turns = 15,                   -- after 15 turns untreated
    effect = "apply_injury",
    injury = "infection",         -- cascades to infection (Level 2)
    message = "The untreated wound has become infected."
  },
  natural_bandaged_heal = {
    trigger_state = "bandaged",   -- fires while bandaged
    turns = 10,                   -- 10 turns after bandaging
    effect = "transition",
    to_state = "healed",
    message = "The wound beneath the bandage has finally closed."
  }
}
```

**Level 1 applications:**
- **Bleeding → Infection (15 turns):** Teaches that ignoring injuries has escalating consequences
- **Nightshade → Worsened (4 turns):** The poison accelerates — time is literally running out
- **Burn → Blistered (8 turns):** Treatment window closing — urgency without lethality
- **Minor cut → Self-healed (5 turns):** The gentle counterpoint — not everything is urgent

### 5.4 Future Hook: `on_combat`

Not in Level 1, but the injury system is designed for it. When combat arrives:
- Slashing attacks → Bleeding
- Blunt attacks → Bruised
- Fire attacks → Burn
- Poison weapons → Specific poisoning
- Animal bites → Minor cut / Bleeding + infection risk

### 5.5 Future Hook: `on_trap_trigger`

Discrete trap events that fire on specific player actions.

```lua
-- Trap: needle in pillow
on_feel = {
  type = "trap_trigger",
  injury = "minor_cut",
  body_part = "finger",
  description = "Something sharp stabs your fingertip. A pin, hidden in the pillow.",
  one_shot = true  -- fires once, then disarmed
}
```

The `one_shot` flag is important: traps that fire every time become tedious. One-shot traps teach a lesson exactly once.

---

## 6. Level 1 Specific Integration Map

> Where each injury meets each room, object, and puzzle moment.

### 6.1 Bedroom — The Introduction

The bedroom is the safest room. Injuries here are low-severity and educational.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| FEEL pillow in darkness | Pin hidden inside | Minor cut (finger) | Not everything is safe to touch |
| TAKE glass shard (barehanded) | Sharp edge on broken mirror glass | Minor cut (hand) | Prepare before handling sharp objects |
| TAKE lit candle (no holder) | Direct flame contact | Burn (hand, minor) | Use the tool (holder), not the source (flame) |
| DRINK poison bottle | Consuming nightshade extract | Nightshade poisoned | Don't consume unknowns; investigate first |
| BREAK window + traverse | Jumping down to courtyard | Bruised (legs) | Shortcuts have costs |

**Injury density:** 5 possible injuries in the bedroom. All are avoidable. All teach different lessons. The player who is cautious may never get hurt here. The player who is reckless will learn quickly.

**First injury timing:** The minor cut (glass shard or pin) is almost certainly the player's first injury. It's gentle — it self-heals, it doesn't impair, it introduces the `injuries` verb. This is calibration: "So THAT's what getting hurt feels like. It wasn't so bad." This sets the player up to be appropriately (not excessively) cautious going forward.

### 6.2 Cellar — The Pressure Cooker

The cellar is dark, cold, and sparse. Injuries here are more dangerous.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| Descend stairs in darkness | Stumble on uneven steps | Bruised (legs) | Light your path before descending |
| Fall onto debris | Environmental hazard | Bleeding (arm/leg) | The underground is more dangerous than above |

**Design tension:** The cellar is the first room where injuries carry real consequences. Bruised legs block climbing back up the stairs easily. Bleeding starts the ticking clock. The player's light source may be running low (candle burns limited turns). The combination of INJURY + DARKNESS + RESOURCE DEPLETION creates compound pressure.

**Treatment access:** Bandage material is in the bedroom (UP). The player must climb back up the stairs while hurt. If legs are bruised, climbing is impaired — they must rest first (losing turns) or push through (narrative resistance). This creates a micro-puzzle: "I'm hurt underground and my treatment is above. How do I get there?"

### 6.3 Storage Cellar — The Resource Discovery

This room provides both injury sources and treatment resources.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| Search crates blindly in dark | Rusty nail or sharp edge | Minor cut (hand) | Darkness makes everything riskier |
| Crate falls on player | Heavy object tips when prying open | Bruised (torso) | Respect heavy objects |
| Grain sack as bandage source | TEAR sack → cloth | *Treatment available* | Environment is a pharmacy |

**The resourceful player:** This room rewards the observant player. The grain sack can be torn into cloth strips for bandages. The wine bottles contain liquid (cleaning wounds?). The rope could be used to stabilize an injured limb (future mechanic). The storage cellar is simultaneously a place where you can GET hurt and a place where you can GET BETTER.

### 6.4 Deep Cellar — The Knowledge Chamber

The atmosphere shifts from utilitarian to ceremonial. Injuries here tie to lore.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| Tattered scroll (medical text) | READING provides treatment knowledge | *No injury — prevention* | Knowledge gathered before crisis saves lives |
| Stairway to hallway (wind draft) | Existing `wind_effect` hook | *Extinguishes candle* (not injury, but creates darkness risk) | Environmental hazards aren't just about direct harm |

**The scroll as injury counter:** The tattered scroll on the altar can contain the medical reference text (§4.4). A player who reads it before getting seriously injured has pre-loaded treatment knowledge. A player who reads it WHILE bleeding has urgent actionable intel. The scroll is the deep cellar's contribution to the injury system — not as a source of harm, but as a source of prevention.

### 6.5 Courtyard — The Treatment Hub

The courtyard exists at the intersection of injury sources and treatment resources.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| Window fall (landing) | Impact with ground | Bruised (legs) | Already inflicted on arrival |
| Rain barrel | Water source | *Burn treatment available* | Water is medicine, not scenery |
| Well + bucket | Water source | *Burn/wound cleaning* | Environmental resources have medical value |
| Ivy climb (with bruised legs) | Attempting to climb while injured | *Blocked — capability gate* | Heal before attempting physical challenges |

**The courtyard's dual role:** It's the MOST DANGEROUS room to reach (window jump = bruised legs) and the MOST USEFUL room for treatment (water for burns, rest space for bruises, open air). This creates an ironic loop: the player who needs the courtyard's healing resources most is the player who was hurt getting there.

**Design moment — The Rain Barrel Revelation:** Before getting burned, the rain barrel is just scenery. The player might not even examine it. After a burn, re-reading the courtyard with injured eyes, the rain barrel becomes a beacon: "Water. I need water. THAT's water." The injury changes how the player perceives the entire environment. This is the moment where scenery becomes resource.

### 6.6 Crypt — The Danger Room

The deepest, most rewarding, most dangerous optional room.

| Moment | Trigger | Injury | Teaching |
|--------|---------|--------|----------|
| Reaching into sarcophagus blindly | Silver dagger blade inside | Bleeding (hand) | The crypt punishes recklessness severely |
| Lifting heavy sarcophagus lid | Physical strain | Bruised (torso/arms) | Heavy objects fight back |
| Silver dagger (trap variant) | Needle-trap on sarcophagus lock | Minor cut → Poisoned? | Traps guard valuable things |

**Escalation complete:** The crypt is where the injury system hits full complexity. A reckless player here could stack bleeding + bruised + possibly poisoned. Treatment requires backtracking through rooms with limited resources. The crypt DEMANDS that the player arrive prepared — bandages in inventory, light source secured, health in good standing. It's the final exam for every lesson the bedroom taught.

---

## 7. The Teachable Moments Framework

> How to use injuries to create memorable gameplay instead of arbitrary punishment.

### 7.1 The Three-Part Pattern

Every injury-puzzle interaction should follow this structure:

1. **WARN:** The environment hints at danger BEFORE the injury happens
2. **HURT:** The injury fires with clear, physical feedback
3. **TEACH:** The treatment process teaches something the player will use later

| Injury | WARN | HURT | TEACH |
|--------|------|------|-------|
| Minor cut (glass) | *"Jagged glass catches the light"* | *"The glass edge catches your palm"* | Wrapping sharp objects in cloth prevents cuts |
| Burn (candle) | *"The candle flame dances, hot"* | *"Your fingers touch flame — searing heat"* | Use the holder; tools exist for reasons |
| Bruised (fall) | *"It's a long way down"* | *"Your knees crack against stone"* | Prepare before physical actions; rest heals |
| Bleeding (dagger) | *"Something glints in the darkness"* | *"A blade bites into your hand"* | Over-time damage needs immediate treatment |
| Nightshade | SMELL: *"Bitter and sweet — not appetizing"* | *"Your heart hammers. Vision blurs."* | Don't consume unknowns; read your symptoms |

### 7.2 The "Fair Warning" Principle

No injury should feel unfair. The player should always be able to trace back: "I should have known."

- **Glass shard:** The description says "jagged." Jagged things cut.
- **Candle flame:** The flame is described as hot. Hot things burn.
- **Poison bottle:** It SMELLS wrong. TASTE is the "learn by dying" sense — but SMELL warned first.
- **Window jump:** The height is described. Height means falling. Falling means impact.
- **Dark stairs:** Descending in darkness is obviously risky. The game doesn't trick the player — it trusts them to be smart.

The only "unfair" injury would be one with no warning at all. We should never inflict that. Even trap injuries (pin in pillow) are fair — the pillow is in a strange room, nothing about this situation is normal, and the injury is trivially minor.

### 7.3 Injury as World-Building

Every injury tells a story about the world:

- **Pin in the pillow:** Someone booby-trapped the bed. This bedroom was prepared for an unwilling guest.
- **Poison bottle on the nightstand:** Someone left poison within arm's reach. Deliberate? Careless? Both are disturbing.
- **Dagger in the sarcophagus:** The dead were buried armed. This family expected something.
- **Glass on the floor:** The window was breakable. The room was meant to LOOK like a bedroom but FUNCTION as a cell.

Injuries aren't just game mechanics — they're narrative evidence. The player who gets hurt is also the player who learns something about why they're here.

---

## 8. Anti-Patterns — What NOT to Do

### 8.1 Don't Punish Exploration

If the player gets injured just for LOOKING at things, they'll stop looking. Injuries should come from ACTIONS, not observation. `EXAMINE`, `SMELL`, `LISTEN` should NEVER cause injury. `TASTE` is the one exception — and it's specifically designed as the "danger sense" (see Multi-Sensory Convention, Decision D-28).

### 8.2 Don't Create Unwinnable States

Injury stacking must never create a situation where the player cannot treat themselves AND cannot progress. For every possible injury combination, there must be a treatment path that doesn't require the injured capability.

**Example check:** Burned hand + bruised legs. Can the player still REST (bruise treatment)? Yes — resting doesn't require hands or legs. Can they still POUR water (burn treatment)? Only if they can get to water — bruised legs don't block walking, only climbing/running. Path verified: the player can limp to the courtyard rain barrel and pour water on their burn, then rest.

### 8.3 Don't Make Injuries Tedious

The "darkness tax" (occasional minor injuries from moving in darkness) must be rare enough to be meaningful and mild enough to not be annoying. If every dark traversal causes a bruise, the player will feel nagged, not warned. One or two darkness-related injuries per playthrough is the right frequency.

### 8.4 Don't Gate the Critical Path Behind Injury Knowledge

The player should be able to complete Level 1's critical path without ever getting injured. Injuries are consequences of mistakes or risky choices — not prerequisites for progress. The critical path is: light room → find trap door → descend → unlock doors → ascend to hallway. None of these steps require being hurt first.

---

## 9. Summary: The Five Roles of Injury

| Role | Pattern | Example | Player Experience |
|------|---------|---------|-------------------|
| **Injury AS Puzzle** | The injury creates a problem to solve | Bleeding = find bandage under time pressure | "I'm hurt — what do I DO?" |
| **Puzzle CAUSES Injury** | Wrong approach = consequence | Grab candle flame = burn | "I should have used the holder" |
| **Injury BLOCKS Puzzle** | Heal-to-progress gate | Bruised legs = can't climb ivy | "I need to rest before I can escape" |
| **Treatment AS Puzzle** | Finding/crafting the cure | Tear blanket → cloth strip → bandage | "The blanket! I can use that!" |
| **Injury hooks into Engine** | Systematic, data-driven causation | `on_traverse` + darkness = bruised | "I should have brought a light" |

These five roles create a web of interactions where injuries are never just punishment — they're gameplay. Every injury changes the player's perception of the environment, priorities, and capabilities. The player who gets hurt sees the world differently than the player who doesn't. That perceptual shift — from "scenery" to "resource," from "decoration" to "tool" — is what makes the injury system a game design feature, not a game design tax.

---

## 10. Required Engine Work

For full injury-puzzle integration, the following engine features are needed beyond what currently exists:

| Feature | Priority | Description |
|---------|----------|-------------|
| **`injury_effect` handler** | P1 | Generic handler that applies an injury instance to the player. Configurable via metadata on exits, objects, and rooms. |
| **`on_pickup` event hook** | P1 | Fires when player takes an object. Enables burn-on-grab, cut-on-grab. |
| **`on_timer` injury ticking** | P1 | Per-turn timer that advances injury FSM states and applies health drain. |
| **Prevention system** | P2 | `prevention` field on injury effects: conditions that block the injury (has_light, wearing_gloves, wrapped_in_cloth). |
| **Capability gate system** | P2 | Injuries declare `blocked_actions`. Engine checks before allowing verbs. |
| **`on_trap_trigger` hook** | P3 | One-shot trap events on FEEL/TAKE/OPEN for specific objects. |
| **Hallucination overlay** | P3 | Nightshade stage 2 injects false details into room descriptions. |

---

## See Also

- [bleeding.md](./bleeding.md) — Ticking clock injury design
- [bruised.md](./bruised.md) — Capability gate injury design
- [burn.md](./burn.md) — Treatment-matching injury design
- [minor-cut.md](./minor-cut.md) — Introductory injury design
- [poisoned-nightshade.md](./poisoned-nightshade.md) — Lethal treatment-matching design
- [treatment-targeting.md](./treatment-targeting.md) — How players apply cures to specific injuries
- [healing-items.md](../player/healing-items.md) — Treatment item catalog
- [puzzle-designer-guide.md](../../architecture/engine/event-handlers/puzzle-designer-guide.md) — Engine hook reference
- [level-01-intro.md](../../levels/01/level-01-intro.md) — Level 1 room and puzzle overview
