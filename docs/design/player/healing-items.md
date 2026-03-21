# Healing Items — Gameplay Design

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-23  
**Revised:** 2026-07-25 (Wayne directive 2026-03-21T20:05Z — targeted treatment, consumable/reusable lifecycles, bandage persistence)  
**Status:** DESIGN  
**Depends On:** Health System (health-system.md), Injury Catalog (injury-catalog.md)  
**Audience:** Designers, Flanders (objects), Bart (engine)

---

## 1. Healing Philosophy

Healing in this game is **specific, physical, and interactive**. Every healing item cures a SPECIFIC injury — not "health points." There is no generic "heal" command, no universal cure, no "restore X HP" items. The player must *understand* their injuries (via the `injuries` verb), *find* the correct treatment, and *apply* it.

**This matching — injury to cure — is the core healing puzzle.**

### Core Rules

1. **Every healing item treats SPECIFIC injuries.** A bandage stops bleeding. An antidote cures a specific poison. A salve treats burns. None of them "restore HP."
2. **Wrong treatment wastes the item.** Drinking a generic antidote for viper venom? The venom doesn't respond. The antidote is gone. The clock is still ticking.
3. **Treatments are targeted to specific injury instances.** The player applies a cure to a SPECIFIC wound — "apply bandage to left arm stab wound." Not "heal me." If only one injury exists, the bare verb works ("apply bandage"), but with multiple injuries the player must specify which one gets treatment. See `docs/design/injuries/treatment-targeting.md` for full targeting rules.
4. **Treatment items have lifecycles — some are consumed, some are reusable.** Salves and antidotes are consumable (one use, destroyed). Bandages are reusable (persistent objects that attach to an injury, can be removed when healed, and reapplied elsewhere). This distinction creates strategic resource management.
5. **Treatment is the puzzle, not a menu.** The player must read their `injuries`, interpret the clues, and match the right item. This is gameplay.
6. **Items declare what they cure.** Each healing item's metadata lists exactly which injury types it treats. No engine special-casing.
7. **No universal cures exist.** Nothing cures everything. The closest is rest (heals bruises, accelerates recovery from treated wounds) — but rest doesn't stop bleeding, doesn't cure poison, doesn't treat burns.

---

## 2. Healing Item Categories

| Category | What It Does | Injuries Treated | Example |
|----------|-------------|-----------------|---------|
| **Wound Dressing** | Stops bleeding, protects wound | Bleeding (from cuts, slashes) | Bandage, cloth strip, cobweb |
| **Specific Antidote** | Neutralizes a SPECIFIC poison | One particular poison type | Viper antivenom, nightshade antidote |
| **Generic Antidote** | Neutralizes mild/food poisoning | Generic mild poisoning only | Antidote vial |
| **Burn Treatment** | Soothes and heals burns | Burns (minor and severe) | Cold water, salve |
| **Infection Treatment** | Cleans or treats infected wounds | Infection (by stage) | Clean water + cloth, herb poultice |
| **Rest** | Passive healing over time | Bruises, treated wounds, exhaustion | Sleep, sit by fire |

**Note:** There is NO "restorative" category that "restores HP." Items don't restore a number — they treat specific conditions. A player who needs healing must identify WHICH injuries they have and find the MATCHING treatment for each one.

---

## 3. Wound Dressings

### 3.1 BANDAGE (Cloth Strip)

| Field | Value |
|-------|-------|
| **ID** | `bandage` |
| **Crafted From** | Tear cloth from blanket, curtains, cloak, or sack |
| **Verb** | `bandage [body part]`, `apply bandage to [injury]`, `wrap wound` |
| **Treats** | **Bleeding** (any cause) — stops blood flow. Also progresses deep cuts to bandaged state. **Accelerates healing** — cuts heal faster WITH bandage than without. |
| **Does NOT Treat** | Poison, burns, bruises, infection. A bandage only addresses bleeding and open wounds. |
| **Uses** | ♻️ Reusable — bandage is a persistent object instance. Attaches to one injury at a time. Can be removed when the wound heals and reapplied to another wound. |
| **Status** | 🟡 Object exists in design, not yet implemented as healing item |

**How It Plays:**

```
> injuries
"You examine yourself:
 — A deep gash on your forearm (bleeding). Blood flows freely.
   It won't stop on its own — you need something wrapped tight."

> tear cloth from blanket
"You rip a long strip of wool from the blanket. It's rough but serviceable."

> apply bandage to forearm wound
"You wrap the cloth strip tightly around your wounded forearm.
 The bleeding slows... and stops. The bandage holds."
 
[Injury: BLEEDING → STOPPED]
[Deep cut: ACTIVE → BANDAGED — healing accelerated]
[Bandage: CLEAN → APPLIED (attached to forearm wound)]

> [Later, after the wound heals...]
> injuries
"You examine yourself:
 — The wound on your forearm has closed. The bandage is no longer needed."

> remove bandage from forearm
"You carefully unwrap the bandage. The cloth is stained but still usable."
[Bandage: APPLIED → REMOVED (reusable)]
```

**Design Details:**
- **Reusable, not consumable.** A bandage is a persistent object instance. Applying it to a wound doesn't destroy it — it attaches the bandage to that injury. When the wound heals, the player can remove the bandage and apply it to another wound.
- **One wound at a time.** A single bandage instance can only be attached to ONE injury. To use it on a different wound, the player must first remove it from the current one.
- **Accelerates healing.** A bandaged wound heals faster than an unbandaged one. A minor cut heals in 5 turns without a bandage, 2 turns with one. A bleeding wound stops draining immediately and heals in 10 turns (without bandage, it never stops draining).
- **Removal timing is strategic.** Removing a bandage from a wound that hasn't fully healed re-exposes it. The wound might start bleeding again. The player must weigh: "Is this wound healed enough to remove the bandage for that new wound?"
- Bandages work on **any bleeding wound** regardless of cause — they're the universal wound dressing.
- Multiple wounds need multiple bandages (or strategic reuse). The cloth strip is the same object used for sewing, cleaning, and crafting. Using it as a bandage occupies it — resource tension.

**What Happens If Used on Wrong Injury:**
```
> [Player is poisoned, tries to bandage]
> bandage arm
"You wrap the cloth around your arm, but you don't have a wound that
 needs binding. The cloth is wasted."
```

**Puzzle Opportunities:**
- Player is bleeding → must discover blanket can be torn → cloth works as bandage. Discovery + crafting under time pressure.
- Only one cloth strip available → two bleeding wounds → which gets the bandage first? The player must triage via `injuries` and apply bandage to the more dangerous wound by name.
- Bandage is on a healed wound → new wound opens → player must `remove bandage from [healed location]` then `apply bandage to [new wound]`. The reuse loop is itself a puzzle under time pressure.

### 3.2 COBWEB (Natural Dressing)

| Field | Value |
|-------|-------|
| **ID** | `cobweb` |
| **Found In** | Cellar corners, crypt passages, abandoned rooms |
| **Verb** | `apply cobweb to wound`, `press cobweb on cut` |
| **Treats** | **Minor bleeding only.** Ineffective on major wounds. |
| **Does NOT Treat** | Heavy bleeding, poison, burns, bruises, infection. |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2) |

**Design Details:**
- Historically accurate (cobwebs have been used as wound dressing).
- Less effective than cloth bandage — minor wounds only.
- Teaches: "The environment has resources if you think creatively."

---

## 4. Antidotes — Poison-Specific Cures

**Critical design principle:** Antidotes are SPECIFIC to poison types. Different poisons need different antidotes. This is the core matching puzzle.

### 4.1 GENERIC ANTIDOTE

| Field | Value |
|-------|-------|
| **ID** | `antidote-generic` |
| **Found In** | Healer's kit, alchemy lab, apothecary |
| **Verb** | `drink antidote` |
| **Treats** | **Mild/food poisoning ONLY.** Generic toxins from spoiled food, tainted water, weak venom. |
| **Does NOT Treat** | Viper venom, nightshade poisoning, or any specific poison. Bleeding, burns, bruises. |
| **Uses** | 1 (consumed) |
| **Status** | 🔴 Planned (Level 2+) |

**How It Plays:**

```
> [Player has food poisoning]
> injuries
"You examine yourself:
 — Your stomach churns violently. Something you consumed is
   poisoning you. You need to neutralize it."

> drink antidote
"The bitter liquid burns going down — but differently from the poison.
 Your stomach settles. The nausea recedes. The burning fades."
[Injury: MILD POISONING → NEUTRALIZED]
[Antidote consumed]
```

**What Happens When Used on WRONG Poison:**
```
> [Player has viper venom]
> drink antidote
"You drink the antidote. It's bitter and medicinal — but the burning
 numbness in your leg doesn't change. This antidote wasn't made for
 viper venom. You've wasted it."
[Generic antidote consumed. Injury: UNCHANGED.]
```

**THIS is the puzzle.** The generic antidote works for generic poisoning. But viper venom needs viper antivenom. Nightshade needs the nightshade antidote. The player must match correctly.

### 4.2 VIPER ANTIVENOM

| Field | Value |
|-------|-------|
| **ID** | `antivenom-viper` |
| **Found In** | Locked medical kit, healer's quarters, apothecary shelf |
| **Verb** | `drink antivenom`, `take antivenom` |
| **Treats** | **Viper venom ONLY.** Specifically neutralizes viper snake venom. |
| **Does NOT Treat** | Food poisoning, nightshade, bleeding, burns, any non-viper condition. |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2+) |

**How It Plays:**

```
> drink viper antivenom
"You drink the dark liquid. It tastes of iron and bitter herbs.
 Within moments, the burning numbness in your leg begins to recede.
 The venom is neutralizing. Feeling returns to your toes. You'll live."
[Injury: VIPER VENOM → NEUTRALIZED]
[Antivenom consumed]
```

**Discovery:** Player reads `injuries` which says "a specific kind... a cure made for THIS bite." Player finds viper antivenom label/description that matches.

### 4.3 NIGHTSHADE ANTIDOTE

| Field | Value |
|-------|-------|
| **ID** | `antidote-nightshade` |
| **Found In** | Herb garden (crafted), apothecary, healer's library |
| **Verb** | `drink nightshade antidote` |
| **Treats** | **Nightshade poisoning ONLY.** |
| **Does NOT Treat** | Viper venom, food poisoning, bleeding, burns, any non-nightshade condition. |
| **Uses** | 1 |
| **Crafting** | May be craftable: nightshade counter-herb + water + preparation (if player found recipe in herbalism book) |
| **Status** | 🔴 Planned (Level 2+) |

**Discovery Clues:**
- `injuries` verb names the poison: "nightshade" — so the player knows WHAT to look for
- Herbalism book (if found): describes the nightshade antidote preparation
- Sensory: SMELL the antidote → "A sharp, green herbal scent. Unmistakably medicinal."

---

## 5. Burn Treatments

### 5.1 COLD WATER (Burn First Aid)

| Field | Value |
|-------|-------|
| **ID** | `water` (applied to burn, not drunk) |
| **Found In** | Well, rain barrel, stream, flask |
| **Verb** | `pour water on burn`, `apply water to [body part]` |
| **Treats** | **Burns (minor).** Immediate soothing, transitions minor burn → treated. |
| **Does NOT Treat** | Severe burns (need salve), bleeding, poison, bruises, infection. |
| **Uses** | Depends on container (flask = 3 uses, barrel = many) |
| **Status** | 🔴 Planned |

**How It Plays:**
```
> injuries
"You examine yourself:
 — Your fingertips are red and tender where you touched the flame.
   Cool water would soothe this."

> pour water on hand
"You splash cold water from the flask over your burned fingers.
 The relief is immediate — the angry red fades to pink."
[Injury: MINOR BURN → TREATED]
```

**Also useful for:** Cleaning wounds (Stage 1 infection treatment when combined with cloth).

### 5.2 SALVE (Burn Medicine)

| Field | Value |
|-------|-------|
| **ID** | `salve` |
| **Found In** | Healer's kit, alchemy crafting |
| **Verb** | `apply salve to burn`, `rub salve on [body part]` |
| **Treats** | **Burns (minor AND severe).** Including blistered burns that water alone can't handle. |
| **Does NOT Treat** | Bleeding, poison, bruises, infection, broken bones. |
| **Uses** | 🔥 Consumable — 3 applications total. Each application consumes one use and the salve instance is destroyed when all uses are spent. |
| **Status** | 🔴 Planned (Level 2+) |

---

## 6. Infection Treatments

### 6.1 CLEAN WATER + CLOTH (Wound Cleaning)

| Field | Value |
|-------|-------|
| **Verb** | `clean wound with water`, `wash wound` |
| **Treats** | **Infection Stage 1 ONLY.** Cleans the wound before infection progresses. |
| **Does NOT Treat** | Stage 2+ infection (needs medicine). Bleeding (needs bandage). Poison. Burns. |

### 6.2 HERB POULTICE

| Field | Value |
|-------|-------|
| **ID** | `herb-poultice` |
| **Crafted From** | Medicinal herbs + cloth + water |
| **Verb** | `apply poultice to wound` |
| **Treats** | **Infection Stage 1–2.** Draws out the infection and promotes healing. |
| **Does NOT Treat** | Stage 3 infection (needs NPC healer). Bleeding. Poison. Burns. |
| **Uses** | 1 |
| **Status** | 🔴 Planned (Level 2+) |

**Puzzle Opportunities:**
- The poultice is a **crafting puzzle**: find herbs + cloth + water → combine → apply. A multi-step healing chain.
- Knowledge gate: recipe found in herbalism book, or NPC teaches it.

---

## 7. Rest as Healing

### 7.1 SLEEP

| What It Treats | Effect |
|---------------|--------|
| **Bruises** | Heals bruises faster during sleep. |
| **Bandaged wounds** | Bandaged cuts/slashes heal during sleep. |
| **Exhaustion** | Full rest cures exhaustion. |
| **Untreated bleeding** | **DANGEROUS.** Bleeding continues during sleep. Player may die. |
| **Untreated poison** | **DANGEROUS.** Poison ticks during sleep. |
| **Burns** | Slow natural healing during sleep (minor burns only). |

**Design Details:**
- Sleep is the free-but-slow healing path for injuries that respond to rest.
- Sleeping while untreated for over-time injuries is dangerous — a strategic trap.
- The bed (Level 1) is the first rest location.

### 7.2 REST (Sitting/Leaning)

| What It Treats | Effect |
|---------------|--------|
| **Bruises** | Accelerates bruise recovery. Primary bruise treatment. |
| **General recovery** | Treated wounds recover slightly faster while resting. |

**Design Details:**
- Resting is lighter than sleep. Sit against a wall, lean on a barrel, pause.
- Costs turns (time-pressure tradeoff) but no special requirements.

---

## 8. The Treatment Matching Table

This is the **master reference** — the puzzle design surface. For each injury, exactly ONE category of item works. Everything else fails.

| Injury | ✅ Correct Treatment | ❌ Wrong Treatments (consumed & wasted) |
|--------|---------------------|----------------------------------------|
| **Minor cut** | Bandage (or heals naturally) | Antidote, salve, water |
| **Deep cut / bleeding** | Bandage (stops bleeding) + rest (heals wound) | Antidote, salve |
| **Bruise** | Rest (time) | Bandage, antidote, salve |
| **Mild food poisoning** | Generic antidote or purge | Bandage, salve, viper antivenom, nightshade antidote |
| **Viper venom** | Viper antivenom ONLY | Generic antidote ❌, bandage, salve, nightshade antidote |
| **Nightshade poisoning** | Nightshade antidote ONLY | Generic antidote ❌, viper antivenom, bandage, salve |
| **Minor burn** | Cold water or salve | Bandage, antidote |
| **Severe burn** | Salve (water alone insufficient) | Bandage, antidote |
| **Infection Stage 1** | Clean water + cloth | Bandage alone ❌, antidote |
| **Infection Stage 2** | Herb poultice | Water alone ❌, bandage, antidote |
| **Infection Stage 3** | NPC healer ONLY | Everything else ❌ |
| **Broken bone** | Splint (wood + cloth) | Bandage alone ❌, antidote, salve |
| **Hypothermia** | Warmth (fire, cloak, shelter) | Bandage, antidote, salve |
| **Exhaustion** | Sleep + food/drink | Bandage, antidote, salve |

**This table IS the puzzle.** The player must discover these relationships through gameplay — examining injuries, reading clues, experimenting with items, and learning from failures.

---

## 9. Design Guidelines for Future Healing Items

### 9.1 The Treatment Specificity Scale

| Specificity | Example | Design Use |
|-------------|---------|------------|
| **Broad** | Bandage (stops any bleeding) | Common treatment for common injuries |
| **Targeted** | Generic antidote (cures mild poison only) | Requires correct category diagnosis |
| **Precise** | Viper antivenom (cures ONE specific venom) | Full diagnosis puzzle — must identify exact poison |
| **Rest** | Sleep / sit down (heals bruises, accelerates recovery) | Always available fallback for time-healable injuries |

**Design rule:** Increase specificity as the game progresses. Level 1: bandages and rest. Level 2: targeted antidotes. Level 3: precise, poison-specific antidotes where identification is the puzzle.

### 9.2 Narrative Rules for Healing

1. **Healing text should be sensory.** The player feels the bandage tighten, smells the herbs, feels the salve's cool relief. Not just "Injury treated."
2. **Pain reduction is noticeable.** When treated, the next few commands reference the *absence* of pain: "For the first time in a while, your arm doesn't ache."
3. **Failed healing gets a message.** Wrong treatment: "You drink the antidote, but the burning in your leg doesn't change. This wasn't made for viper venom." The failure text gives a clue about WHY it failed.
4. **The `injuries` verb updates after treatment.** The player can check their progress: before treatment → symptoms. After treatment → recovery narrative.

### 9.3 Anti-Patterns (Don't Do This)

| Anti-Pattern | Why It's Bad | Do This Instead |
|-------------|-------------|-----------------|
| Healing potion that "restores 30 HP" | Bypasses the injury-matching puzzle entirely | Items treat specific injuries, not numbers |
| Universal cure that heals everything | No diagnosis puzzle | Each medicine cures one condition |
| Infinite-use medical kit | Makes injuries meaningless | Kit has 3 bandages (reusable), 1 salve (consumable), 1 antidote (consumable) |
| Auto-healing when entering safe room | Player never engages with the system | Player must explicitly treat each injury |
| Generic "heal" command | Removes the matching puzzle | Player must `bandage`, `drink antidote`, `apply salve` — specific verbs for specific treatments |
| Antidote that cures "all poisons" | Eliminates the poison-identification puzzle | Different antidotes for different poisons |

---

## 10. Level 1 Healing Inventory

What healing resources exist (or should exist) in Level 1?

| Resource | Location | How Obtained | Treats |
|----------|----------|-------------|--------|
| **Blanket** (tear for cloth) | Bedroom, on bed | `tear blanket` → cloth strip | Cloth → bandage (stops bleeding) |
| **Wool cloak** (tear for cloth) | Wardrobe | `tear cloak` → cloth strip | Cloth → bandage (but destroys cloak for warmth) |
| **Curtains** (tear for cloth) | Bedroom window | `tear curtains` → cloth strip | Cloth → bandage (but loses daylight control) |
| **Water** (rain barrel) | Courtyard | `pour water on burn`, `clean wound` | Soothes minor burns, cleans wounds (Stage 1 infection) |
| **Rest** (bed) | Bedroom | `sleep`, `rest on bed` | Heals bruises, accelerates treated wound recovery |
| **Rest** (any surface) | Anywhere | `rest`, `sit down` | Heals bruises (slower than sleep) |

**Design Note:** Level 1 has **no antidotes, no salve, no potions**. Healing in Level 1 is primitive — cloth bandages, water, rest. This teaches the fundamentals (identify injury → find specific treatment → apply) before introducing complex matching puzzles in Level 2.

**Resource tension:** The blanket, cloak, and curtains all have other uses (warmth, rope-making, daylight control). Tearing them for bandages is a trade-off. Every resource decision matters.

**Nested inventory note:** As players progress to Level 2+, healing items will be found INSIDE containers — a medical kit inside a satchel, an antidote vial inside a locked box. This adds a container-navigation layer to the healing puzzle: the right cure exists, but accessing it under injury time-pressure IS the challenge.

---

## 11. Healing × Puzzle Integration

### Integration 1: The Bleeding Clock
**Injury:** Deep cut → bleeding  
**Correct cure:** Bandage (cloth strip)  
**Puzzle:** Must discover blanket can be torn → cloth works as bandage. Under time pressure from bleeding.

### Integration 2: The Poison Matching Puzzle
**Injury:** Viper venom poisoning  
**Correct cure:** Viper antivenom (NOT generic antidote)  
**Puzzle:** Generic antidote fails (wasted). Player must find the specific antivenom. The `injuries` verb hinted: "a cure made for THIS bite."

### Integration 3: The Diagnosis Challenge
**Injury:** Unknown — could be food poisoning or nightshade  
**Correct cure:** Depends on diagnosis  
**Puzzle:** Examine symptoms via `injuries`. SMELL the contaminated food. Identify the poison type → choose correct antidote.

### Integration 4: The Nested Container Emergency
**Injury:** Viper venom (ticking)  
**Correct cure:** Viper antivenom (inside locked medical kit, inside satchel)  
**Puzzle:** Navigate container hierarchy under time pressure. Open satchel → find locked kit → find key → open kit → drink antivenom.

### Integration 5: The NPC Treatment
**Injury:** NPC has a specific injury  
**Correct cure:** Player identifies NPC's injury → applies correct treatment  
**Puzzle:** Extends healing from self-care to world interaction. Healing items become social tools.

### Integration 6: The Resource Sacrifice
**Injury:** Bleeding heavily  
**Correct cure:** Bandage from blanket  
**Puzzle:** Tearing the blanket makes it useless for warmth (needed later for hypothermia). The player must choose: survive now, or save the resource for later?

### Integration 7: The Triage Decision
**Injury:** Two bleeding wounds (left arm + right leg), one bandage  
**Correct cure:** Bandage applied to the more severe wound  
**Puzzle:** Player uses `injuries` to compare severity. Applies bandage to the worse wound by name: `apply bandage to left arm wound`. The other wound continues draining. Once the first wound heals, the player removes the bandage and applies it to the second: `remove bandage from left arm`, `apply bandage to right leg`. Timing and triage under pressure.

### Integration 8: The Bandage Recovery Loop
**Injury:** Wound heals under bandage → new wound opens  
**Correct cure:** Remove healed bandage → apply to fresh wound  
**Puzzle:** The player must notice (via `injuries`) that the old wound has healed, remember they have a bandage on it, remove it, and apply it to the new wound — all while the new wound is draining health. The reuse mechanic itself is the puzzle.

---

## 12. Treatment Item Lifecycles

Treatment items are object instances with FSM state, just like every other object in the game. Their lifecycle determines whether they're consumed on use or persist as reusable resources.

### 12.1 Consumable Items (Destroyed on Use)

**Pattern:** The item instance is destroyed when applied. One use, gone forever.

**Examples:** Salve, antidote, antivenom, herb poultice.

**Salve Lifecycle:**

```
 ┌──────────┐     apply to      ┌──────────┐
 │  SEALED   │ ──────────────── │  APPLIED   │ → instance destroyed
 │           │    burn/wound     │ (consumed) │   (if last use)
 └──────────┘                   └──────────┘
```

| State | Description | What the Player Sees |
|-------|-------------|---------------------|
| **Sealed** | Jar is stoppered. Contents available. | *"A clay jar sealed with wax. Something medicinal sloshes inside."* |
| **Applied** | Salve rubbed onto wound. Use consumed. | *"You rub the cool salve over the burn. Immediate relief."* |
| **Empty** | All uses spent. Instance destroyed. | *"The jar is empty. The last of the salve is on your skin."* |

**Design Rule:** Consumable items follow the same terminal-state pattern as spent matches. The `applied` state triggers instance destruction (or the jar persists as an empty container — designer's choice).

### 12.2 Reusable Items (Persistent, Attachable)

**Pattern:** The item instance persists. It attaches to an injury, can be removed when the wound heals, and reapplied to a different injury.

**Example:** Bandage (cloth strip).

**Bandage Lifecycle:**

```
 ┌──────────┐   apply to     ┌──────────┐   wound    ┌──────────┐
 │   CLEAN   │ ─────────── │  APPLIED   │ ──────── │ REMOVABLE  │
 │           │   injury     │ (attached  │  heals   │ (can be    │
 └──────────┘              │  to wound) │          │  removed)  │
      ▲                     └──────────┘          └─────┬──────┘
      │                                                  │
      └──────────────── remove from wound ◄──────────────┘
         (bandage returns to inventory, 
          stained but reusable)
```

| State | Description | What the Player Sees |
|-------|-------------|---------------------|
| **Clean** | Fresh cloth strip, ready to apply. | *"A strip of rough wool cloth. Clean and ready for use."* |
| **Applied** | Wrapped around a specific injury. Accelerating healing. | *"Wrapped tightly around your left arm wound."* |
| **Removable** | Wound has healed. Bandage can be safely removed. | *"The bandage on your arm is loose — the wound beneath has closed."* |
| **Removed/Reusable** | Back in inventory after removal. Stained but functional. | *"A stained cloth strip. Used, but still serviceable as a bandage."* |

**Key Constraint:** A bandage can only be APPLIED to ONE injury at a time. The player cannot stretch one bandage across two wounds. To treat a second wound, they need a second bandage — or they must wait for the first wound to heal, remove the bandage, and reapply it.

**Bandage Accelerates Healing:**

| Wound Type | Without Bandage | With Bandage |
|-----------|----------------|-------------|
| Minor cut | 5 turns (natural healing) | 2 turns (accelerated) |
| Bleeding (deep wound) | Never stops — fatal | Drain stops immediately; wound heals in 10 turns |

The bandage doesn't just stop bleeding — it creates a better healing environment. This is the mechanical incentive to use bandages even on minor wounds when time is scarce.

### 12.3 Lifecycle Comparison

| Property | Consumable (Salve) | Reusable (Bandage) |
|----------|-------------------|-------------------|
| **On use** | Use count decremented; destroyed when empty | Attaches to injury; item persists |
| **After treatment** | Gone forever | Remains on wound, accelerating healing |
| **Recovery** | None — find a new one | Remove when healed → reuse |
| **Strategic tension** | "Should I use this now or save it?" | "Which wound gets the bandage?" |
| **Example FSM** | sealed → applied → empty (destroyed) | clean → applied → removable → clean |

### 12.4 Wrong-Treatment Behavior by Lifecycle Type

**Consumable on wrong target:** Item is consumed AND wasted. The antidote is gone. The wrong injury is unchanged. Maximum punishment for mismatching.

**Reusable on wrong target:** Item is NOT consumed. The bandage doesn't attach to a bruise — the player gets it back immediately. "The cloth doesn't help here." Reusable items are more forgiving of experimentation.

---

## See Also

- [health-system.md](./health-system.md) — Derived health model, injury accumulation, `injuries` verb, death design
- [injury-catalog.md](./injury-catalog.md) — Each injury type and its specific cure
- [treatment-targeting.md](../injuries/treatment-targeting.md) — How players target specific injuries for treatment
- [README.md](./README.md) — System overview
- `docs/design/composite-objects.md` — Object FSM patterns (healing items follow same lifecycle)
- `docs/design/tool-objects.md` — Tool resolution system (healing items use same dispatch)
