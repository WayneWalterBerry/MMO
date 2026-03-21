# Self-Infliction — Deliberate Injury Mechanic

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** DESIGN  
**Depends On:** Injury System (injuries/), Health System (health-system.md), Verb Handlers, Parser  
**Audience:** Designers, Bart (engine), Flanders (objects), Nelson (testing)

---

## 1. Overview

The player can deliberately injure themselves using a held weapon. This is the **test harness for the entire injury system** and a legitimate gameplay mechanic for puzzles requiring blood, sacrifice, or desperate acts.

Precedent already exists: `prick self with pin` creates `bleed_ticks` for blood writing. Self-infliction formalizes and generalizes this into the new injury system — any weapon, any body part, producing real injury instances that feed into accumulation, treatment targeting, and derived health.

**This is NOT combat.** There is no opponent, no attack roll, no defense. The player chooses to hurt themselves. The engine reads the weapon's damage profile and applies the appropriate injury to the targeted body area.

---

## 2. Verb Design

### 2.1 Supported Verbs

Three verbs handle self-infliction. Each implies a different weapon motion and maps to the weapon's corresponding damage profile:

| Verb | Motion | Typical Weapons | Weapon Field Read |
|------|--------|----------------|-------------------|
| `stab` | Puncture / thrust | Dagger, knife, pin, needle | `on_stab` |
| `cut` | Slash / draw across | Knife, dagger, glass shard | `on_cut` |
| `slash` | Wide sweeping cut | Dagger, sword (future) | `on_slash` |

**Why three verbs, not one?** Because the same weapon can produce different injuries depending on how it's used. A knife *stabbed* into your arm creates a puncture wound (bleeding). A knife *drawn across* your palm creates a slash (minor-cut or bleeding, depending on pressure). The verb selects the weapon's damage profile — the weapon encodes multiple profiles.

**Not `use X on self`.** "Use" is too generic and conflicts with other object interactions. Self-infliction verbs are intentional, violent words — they make the player type something deliberate. You don't accidentally type "stab self."

### 2.2 Synonyms & Aliases

| Canonical | Aliases |
|-----------|---------|
| `stab` | `jab`, `pierce`, `stick` |
| `cut` | `slice`, `nick` |
| `slash` | `carve` |

The existing `prick` verb (from pin/needle) remains as-is — it's a special case that predates this system. Prick produces only a pinprick (minor-cut on finger), regardless of weapon profiles. It stays small.

### 2.3 Parser Patterns

The parser must recognize these forms:

```
VERB self with WEAPON
VERB my BODY_PART with WEAPON
VERB BODY_PART with WEAPON
VERB self
VERB my BODY_PART
VERB BODY_PART
```

**Concrete examples:**

```
> stab self with knife           → stab + random body area + knife
> cut my arm with dagger         → cut + left/right arm (disambiguate) + dagger
> slash left arm with knife      → slash + left arm + knife
> stab self                      → stab + random body area + held weapon (if only one)
> cut my hand                    → cut + hand + held weapon (if only one)
> stab arm                       → stab + arm (disambiguate left/right) + held weapon
```

**Resolution order:**

1. **Verb** — determines which weapon profile to read (`on_stab`, `on_cut`, `on_slash`)
2. **Instrument** — the `with X` phrase identifies the weapon. If omitted, use held weapon (see §2.4)
3. **Target** — `self`, `my BODY_PART`, or bare `BODY_PART`. If `self` or omitted → random area (see §3)

### 2.4 Instrument Resolution

When no `with X` phrase is present:

1. Check what the player is holding
2. If **one held item** has the relevant damage profile (`on_stab`, `on_cut`, etc.) → use it
3. If **multiple held items** have the profile → disambiguate:
   ```
   > stab self
   "Stab yourself with what? You're holding a knife and a dagger."
   ```
4. If **no held item** has the profile → fail:
   ```
   > stab self
   "You don't have anything to stab with."
   ```
5. If item is named but **not held** → fail:
   ```
   > stab self with knife
   "You're not holding the knife."
   ```

### 2.5 Validation — Weapon Must Support the Verb

Not every sharp object supports every verb. A pin supports `prick` but not `slash`. A glass shard supports `cut` but not `stab` (it would shatter). The weapon's metadata declares which profiles it has:

```
> slash self with pin
"The pin is too small to slash with. You could prick yourself, but not slash."

> stab self with glass shard
"The glass shard would shatter if you tried to drive it in.
 You could cut yourself with it, though."
```

The failure message hints at valid verbs for that weapon. This is discovery — the player learns the weapon's capabilities through interaction.

---

## 3. Body Targeting

### 3.1 Targetable Areas

| Area | Parser Tokens | Notes |
|------|--------------|-------|
| `left arm` | "left arm", "my left arm" | Dominant arm TBD (future) |
| `right arm` | "right arm", "my right arm" | |
| `left hand` | "left hand", "my left hand" | Default for `cut self` with small blades |
| `right hand` | "right hand", "my right hand" | |
| `left leg` | "left leg", "my left leg" | |
| `right leg` | "right leg", "my right leg" | |
| `torso` | "torso", "chest", "side" | Higher damage — risky |
| `stomach` | "stomach", "belly", "gut" | Higher damage — risky |
| `head` | "head", "forehead", "face" | Highest risk — may be restricted (see §3.4) |

### 3.2 Bare "arm" / "hand" / "leg" Disambiguation

If the player types `stab my arm` without specifying left or right:

```
> stab my arm with knife
"Which arm? Your left arm or your right arm?"

> left
"You grit your teeth and drive the knife into your left arm..."
```

**Alternative design (Wayne to decide):** Auto-select the non-dominant arm. If the player is right-handed, `stab my arm` defaults to the left arm (you'd protect your dominant hand). This avoids disambiguation for a common case.

### 3.3 Random Area Selection

When the player types `stab self` without a body target, the engine selects a random area from this weighted table:

| Area | Weight | Rationale |
|------|--------|-----------|
| Left arm | 3 | Arms are the natural self-target |
| Right arm | 3 | |
| Left hand | 2 | Hands are smaller targets |
| Right hand | 2 | |
| Left leg | 2 | Legs are awkward to reach |
| Right leg | 2 | |
| Torso | 1 | Unlikely self-target — dangerous |
| Stomach | 1 | Unlikely self-target — dangerous |
| Head | 0 | **Never random** — must be explicit |

Arms and hands are heavily weighted because that's where people naturally self-inflict. The randomness adds replayability and unpredictability to testing. Head is excluded from random — you have to *mean it*.

### 3.4 Head Targeting — Special Case

Targeting the head is allowed but narratively gated:

```
> stab my head with knife
"That would almost certainly kill you. Are you sure?

(Type 'yes' to proceed, or anything else to reconsider.)"

> yes
"You press the blade against your forehead and cut.
 Blood pours into your eyes immediately..."
(Injury: bleeding, head — severe. Vision impaired.)
```

Head injuries are more severe (higher damage multiplier) and produce vision impairment as a mechanical effect. The confirmation prompt exists because head self-injury is almost always a mistake, not a puzzle solution.

**Exception:** `cut forehead` (a shallow cut) skips the confirmation. A shallow forehead cut is a valid puzzle mechanic (blood offering, marking). Only `stab head` gets the warning.

### 3.5 Location on the Injury Instance

The injury instance carries the location:

```lua
{
  type = "bleeding",
  location = "left arm",
  cause = "self-inflicted (silver-dagger, stab)",
  turn_inflicted = 47,
  -- ...FSM state, timers, etc.
}
```

This `location` field is what appears in:
- The `injuries` verb output: *"A deep stab wound on your **left arm** (bleeding)"*
- Treatment targeting: `apply bandage to left arm`
- Narrative overlays: *"Your **left arm** throbs as you reach for the door"*

---

## 4. Weapon Damage Encoding

### 4.1 Core Principle: The Weapon Knows Its Damage

The engine contains **zero hardcoded damage values**. Every weapon declares its own damage profiles in its metadata. This follows Principle 8: *Engine Executes Metadata; Objects Declare Behavior.*

### 4.2 Damage Profile Structure

Each weapon can declare one or more damage profiles:

```lua
-- Example: silver-dagger.lua (Flanders implements)
on_stab = {
  damage = 8,
  injury_type = "bleeding",
  description = "You drive the silver dagger into your %s. Blood wells up immediately.",
  pain_description = "A sharp, deep pain radiates from the wound.",
},
on_cut = {
  damage = 4,
  injury_type = "minor-cut",
  description = "You draw the dagger's edge across your %s. A thin red line appears.",
  pain_description = "A stinging line of fire across the skin.",
},
on_slash = {
  damage = 6,
  injury_type = "bleeding",
  description = "You slash the dagger across your %s. The wound opens wide and bleeds freely.",
  pain_description = "A burning, tearing sensation.",
},
```

```lua
-- Example: kitchen-knife.lua
on_stab = {
  damage = 5,
  injury_type = "bleeding",
  description = "You stab the knife into your %s. It hurts more than you expected.",
  pain_description = "A blunt, throbbing pain. The blade is not as sharp as a dagger.",
},
on_cut = {
  damage = 3,
  injury_type = "minor-cut",
  description = "You nick your %s with the knife. A shallow cut — it stings.",
  pain_description = "A thin sting, like a paper cut but deeper.",
},
-- no on_slash — kitchen knife is too small for slashing
```

```lua
-- Example: glass-shard.lua
on_cut = {
  damage = 3,
  injury_type = "minor-cut",
  description = "You press the glass edge against your %s. The shard bites into skin.",
  pain_description = "A clean, sharp sting.",
  self_damage = true,  -- the shard may cut the hand holding it too
},
-- no on_stab, no on_slash — glass shatters under thrust/sweep
```

### 4.3 The `%s` Placeholder

The `description` field uses `%s` as a placeholder for the body area. The engine substitutes the targeted area at runtime:

```
"You drive the silver dagger into your %s." 
→ "You drive the silver dagger into your left arm."
```

This keeps weapon descriptions in the weapon, not in the engine. Different weapons produce different narrative voices — the dagger is clinical and precise, the kitchen knife is clumsy and desperate.

### 4.4 Damage → Injury Mapping

The `injury_type` field in the damage profile determines which injury template gets instantiated:

| `injury_type` Value | Injury Template | Behavior |
|---------------------|----------------|----------|
| `"minor-cut"` | `src/meta/injuries/minor-cut.lua` | One-time damage. Self-heals in 5 turns. |
| `"bleeding"` | `src/meta/injuries/bleeding.lua` | Over-time drain. Needs bandage. Fatal if untreated. |
| `"bruise"` | `src/meta/injuries/bruise.lua` | One-time damage. Heals with rest. |
| `"burn"` | `src/meta/injuries/burn.lua` | One-time damage. Needs cold water. |

The `damage` field feeds into the injury's initial severity, which affects the derived health calculation (see health-system.md §1.3).

### 4.5 Body Area Damage Modifiers

Some body areas amplify or reduce damage:

| Area | Modifier | Rationale |
|------|----------|-----------|
| Hand/arm | ×1.0 | Baseline — fleshy, survivable |
| Leg | ×1.0 | Baseline |
| Torso | ×1.5 | Internal organs. More dangerous. |
| Stomach | ×1.5 | Same as torso |
| Head | ×2.0 | Extremely dangerous. Vision effects. |

The modifier is applied to the weapon's `damage` value. A dagger stab (damage 8) to the torso = 12 effective damage. The modifier is engine-side (part of the self-infliction handler), not weapon-side — weapons don't need to know about body area risk.

### 4.6 Glass Shard — `self_damage` Flag

The glass shard has `self_damage = true` on its `on_cut` profile. This means using the shard to cut *also* cuts the hand holding it (unless gloved or wrapped). Two injuries from one action:

```
> cut my arm with glass shard
"You press the glass edge against your left arm and draw it across.
 A thin red line appears on your arm — and the shard bites into
 your palm too."
(Injury 1: minor-cut, left arm — from the intentional cut)
(Injury 2: minor-cut, right hand — from holding the shard)
```

This reinforces the existing lesson: wrap the shard in cloth before using it.

---

## 5. Interaction Flow — Complete Examples

### 5.1 Basic Self-Stab

```
> stab self with knife
"You grit your teeth, turn the knife inward, and drive the point
 into your left arm.

 A sharp, blunt pain. Blood begins to flow.
 
 The wound is deep enough to bleed steadily."

(Injury added: bleeding, left arm. Self-inflicted with kitchen-knife.)

> injuries
"You examine yourself:
 — A stab wound on your left arm (bleeding). Blood flows steadily.
   It won't stop on its own — you need something wrapped tight."
```

### 5.2 Targeted Cut

```
> cut my right hand with dagger
"You draw the dagger's edge across your right hand. A thin red line
 of blood appears across your palm. It stings sharply.
 
 A deliberate wound. You hope it's worth whatever comes next."

(Injury added: minor-cut, right hand. Self-inflicted with silver-dagger.)
```

### 5.3 No Weapon Held

```
> stab self
"You don't have anything to stab with."
```

### 5.4 Weapon Doesn't Support Verb

```
> slash self with pin
"The pin is too small to slash with."
```

### 5.5 Multiple Weapons — Disambiguation

```
> cut self
"Cut yourself with what? You're holding a knife and a glass shard."

> knife
"You grit your teeth and draw the knife across your left hand..."
```

### 5.6 Accumulation — Multiple Self-Injuries

```
> stab my left arm with dagger
(Injury: bleeding, left arm)

> stab my right arm with dagger
(Injury: bleeding, right arm)

> injuries
"You examine yourself:
 — A deep stab wound on your left arm (bleeding). Blood flows
   from the wound.
 — A deep stab wound on your right arm (bleeding). Both arms
   are bleeding now.
 
 Two wounds bleeding. You're losing blood from both — faster
 than either alone. You need bandages. More than one."
```

---

## 6. Gameplay Uses

### 6.1 Blood Offering Puzzle

**Setup:** An ancient altar in the crypt. Runes on the wall read: *"The door opens for those who give of themselves."* An empty stone basin sits atop the altar.

**Solution:**
```
> cut my hand with dagger
"You draw the blade across your palm. Blood wells up."
(Injury: minor-cut, hand)

> drip blood on altar
"Blood falls from your cut hand onto the stone basin.
 The drops sizzle against the cold stone.
 
 A deep rumble. The wall behind the altar shifts.
 A passage opens in the darkness."
```

**Design notes:**
- The altar checks for `player.state.bleeding == true` or an active bleeding/cut injury
- Any fresh wound works — the puzzle doesn't require a specific weapon
- The injury persists after the puzzle is solved — the player carries the wound forward
- This is a **cost-to-progress** puzzle: you trade health for access

### 6.2 Desperate Rope Escape

**Setup:** The player's hands are bound with rope. They have a knife tucked in their belt (accessible but can't use hands freely).

**Solution:**
```
> cut rope with knife
"You twist the knife awkwardly against the rope binding your wrists.
 The rope frays and snaps — but the blade cuts into your wrist too."
(Injury: minor-cut, left wrist. Rope removed. Hands freed.)
```

**Design notes:**
- The injury is a *side effect* of the escape, not the goal
- This teaches: desperate actions have physical costs
- The cut is minor (knife against rope, not a deliberate wound) but real

### 6.3 QA / Testing Harness

Self-infliction is the fastest way to test the injury pipeline:

```
> stab self with dagger          → bleeding injury
> cut self with knife            → minor-cut injury  
> stab self with dagger          → second bleeding (accumulation test)
> injuries                       → verify listing
> apply bandage to left arm      → treatment test
> injuries                       → verify state change
```

By varying weapons and body targets, QA can exercise:
- Every injury type producible by weapons
- Accumulation math (stack 3 bleeds, verify drain rate)
- Treatment targeting disambiguation (multiple wounds, one bandage)
- Body-part-specific narrative overlays
- Death threshold from accumulated self-injury

### 6.4 Ritual / Arcane Puzzles (Future)

- **Blood ward:** Draw a protective circle using your own blood. Requires active bleeding + `draw circle` verb.
- **Life trade:** An NPC demands a blood price. Self-infliction satisfies the demand.
- **Cursed item:** A cursed weapon forces self-injury when drawn (future combat system hook).

---

## 7. Narrative Tone — Safety and Consequence

### 7.1 Guiding Principle

Self-infliction is always described as **painful, costly, and deliberate**. The narrative voice acknowledges this is a desperate or purposeful act — never casual, never glorified.

### 7.2 Narrative Beats

Every self-infliction message follows this three-beat structure:

1. **Resolve** — The player steels themselves. *"You grit your teeth..."* / *"You take a breath and..."* / *"Your hand trembles, but..."*
2. **Action** — The wound happens. Described physically, not clinically. *"The blade bites into your arm..."* / *"Blood wells up immediately..."*
3. **Consequence** — The cost is real. *"The pain is sharp and immediate."* / *"You hope this is worth it."* / *"A deliberate wound. There's no undoing it."*

### 7.3 Escalation for Repeated Self-Injury

The narrative voice changes as the player inflicts more wounds:

**First self-injury:**
> *"You grit your teeth, turn the knife inward, and cut. Blood wells up. A deliberate wound — you hope whatever you're doing is worth the pain."*

**Second self-injury:**
> *"Again. The blade finds fresh skin. The pain is familiar now, which makes it worse. Blood from the first wound has barely stopped."*

**Third or more:**
> *"You're covered in self-inflicted wounds. The knife shakes in your bloody grip. Whatever drove you to this — desperation, madness, necessity — the cost is written across your body."*

This escalation is narrative only — it doesn't gate the action. The player can always choose to self-injure. But the text makes it clear the character isn't having a good time.

### 7.4 What We Never Do

- **Never make it fun or casual.** No "You give yourself a little scratch! :)" — pain is pain.
- **Never describe it graphically for its own sake.** The description serves gameplay (what injury type, where, how severe) — not spectacle.
- **Never moralize at the player.** No "Are you sure you want to hurt yourself?" (except for head targeting, which is a lethality warning, not a moral one). The player has agency. The game acknowledges the cost through the character's experience, not through editorial judgment.

---

## 8. Edge Cases

### 8.1 Self-Infliction While Already Bleeding

Allowed. Injuries stack. The narrative reflects existing wounds:

```
> stab self with dagger
"You look at your already-bleeding arm, choose a spot that isn't
 soaked in blood, and drive the dagger in again. More blood.
 More pain. You're making this worse."
```

### 8.2 Self-Infliction With No Free Hand

If both hands are occupied and the weapon requires a free hand to maneuver:

```
> stab self with knife
"You can't — both hands are full. You'd need to put something down first."
```

The knife counts as "held in one hand." Stabbing yourself requires using that hand's weapon against your own body — which is fine. This edge case only fires if the weapon somehow requires *two* hands (a sword, future).

### 8.3 Self-Infliction With Bare Hands

```
> stab self
"You don't have anything to stab with."

> punch self
"You could, but you don't think that would accomplish much."
```

Bare-hand self-injury isn't supported in V1. Future: `punch self` could produce a bruise.

### 8.4 Self-Infliction On a Bandaged Area

If the player targets a body area that's already bandaged:

```
> stab my left arm with dagger
"Your left arm is bandaged. You'd be cutting through the bandage
 and into a wound that's still healing. 

(Type 'yes' to proceed, or anything else to reconsider.)"

> yes
"You drive the dagger through the bandage and into the half-healed
 wound beneath. The bandage is ruined. The old wound tears open.
 Fresh blood mixes with the stains already on the cloth."

(Bandage destroyed. Previous injury reverts to active/bleeding.
 New injury stacks on the same location.)
```

### 8.5 Dead Body Area (Future)

If an area has sustained enough cumulative damage to be non-functional (nerve damage, future mechanic), self-injury there produces no pain description but still creates the wound. The player may not even feel it — which is itself a narrative signal.

---

## 9. Relationship to Future Combat

Self-infliction is **combat without an opponent**. The same weapon damage profiles (`on_stab`, `on_cut`, `on_slash`) will be used when combat arrives:

| Self-Infliction | Future Combat |
|----------------|---------------|
| Player selects target (body area) | Attacker selects target (opponent's body area) |
| Player selects weapon (held item) | Attacker uses held weapon |
| Weapon profile determines injury | Same weapon profiles |
| Injury instance created with location | Same injury system |
| `injuries` verb shows wounds | Same verb for opponent inspection |

Self-infliction validates the entire pipeline: parser patterns, weapon profiles, body targeting, injury instantiation, accumulation, treatment. When combat arrives, the only new pieces are opponent selection, hit/miss mechanics, and AI targeting. The injury-and-damage pipeline is already proven.

---

## 10. Cross-References

| Document | Relationship |
|----------|-------------|
| [health-system.md](health-system.md) | Derived health from accumulated injuries. §1.3 accumulation math. §6 damage scenarios. |
| [injuries/bleeding.md](../injuries/bleeding.md) | Primary injury produced by `stab` verbs. Treatment with bandage. |
| [injuries/minor-cut.md](../injuries/minor-cut.md) | Primary injury produced by `cut` verbs with lighter weapons. |
| [injuries/treatment-targeting.md](../injuries/treatment-targeting.md) | How the player treats location-specific wounds created by self-infliction. |
| [injuries/puzzle-integration.md](../injuries/puzzle-integration.md) | Blood offering and ritual puzzles that motivate self-infliction. |
| [health-system.md §6.1](health-system.md) | Blood writing scenario — existing precedent for self-injury. |
| [health-system.md §6.2](health-system.md) | Knife-as-hazard scenario — existing precedent for `cut self`. |

---

## 11. Implementation Notes for Bart & Flanders

### For Bart (Engine)

1. **New verb handlers:** `stab`, `cut`, `slash` — with self-targeting detection (`self`, `my BODY_PART`)
2. **Instrument resolution:** Parse `with X`, fall back to held weapon, disambiguate if needed
3. **Body area resolution:** Parse target, disambiguate left/right, random selection from weighted table
4. **Damage profile read:** Read `on_stab`/`on_cut`/`on_slash` from weapon metadata
5. **Body modifier:** Multiply weapon damage by area modifier (§4.5)
6. **Injury instantiation:** Create injury instance from `injury_type` with `location`, `cause`, `turn_inflicted`
7. **Confirmation gate:** Head targeting and bandaged-area targeting require `yes` confirmation

### For Flanders (Objects)

1. **Add damage profiles** to existing weapons: silver-dagger, kitchen-knife, glass-shard, pin
2. **`%s` placeholder** in all description strings for body area substitution
3. **`self_damage` flag** on glass-shard's `on_cut` profile
4. **No `on_slash`** for small items (pin, glass shard) — only larger blades
5. **Future weapons** should include all applicable profiles at creation time

### Architecture Boundary

This design doc describes **how it plays**. Where the code lives, how the parser dispatches, how injury instances are stored — that's Bart's architecture domain. See Bart for `docs/architecture/` specs.

---

## 12. Open Questions for Wayne

1. **Bare "arm" / "hand" / "leg" disambiguation:** Auto-select non-dominant side, or always ask? (§3.2)
2. **Head self-injury:** Confirmation prompt, or just allow it with narrative warning? (§3.4)
3. **`slash` verb:** Include now, or defer to combat? Adds complexity with minimal Level 1 payoff.
4. **Punch/hit self:** Should bare-hand self-injury produce bruises? Low priority but natural player input.
5. **Maximum self-injury count:** Should we cap how many times the player can self-injure per turn, or let accumulation handle the consequence naturally?
