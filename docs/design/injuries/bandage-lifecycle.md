# Bandage Lifecycle — A Reusable Treatment Object

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-26  
**Status:** DESIGN  
**Depends On:** [treatment-targeting.md](./treatment-targeting.md), [healing-items.md](../player/healing-items.md) §3.1 & §12.2, [bleeding.md](./bleeding.md), [minor-cut.md](./minor-cut.md)  
**Audience:** Designers, Flanders (object implementation), Bart (engine), Nelson (testing)

---

## 1. Core Concept

A bandage is **not consumable**. It is a persistent object instance with its own finite state machine that tracks its condition and what it's attached to. The same cloth strip can stop bleeding on your left arm, be removed once that wound heals, and then be wrapped around a fresh gash on your right leg. It wears out, gets dirty, and can be washed — a small object with a full life.

This makes bandages **strategic resources**, not disposable tokens. The player doesn't "use" a bandage — they *manage* it across multiple injuries over time.

**Contrast with salve:** Salve is consumable. Apply it, it's gone. A bandage is the opposite — it persists, it attaches, it returns. Salve asks "should I use this now?" Bandage asks "which wound gets this?"

---

## 2. FSM States

```
                    ┌──────────────────────────────────────────────────┐
                    │                                                  │
                    ▼                                                  │
              ┌──────────┐     apply to       ┌───────────┐           │
              │   CLEAN   │ ───────────────── │  APPLIED   │           │
              │           │     injury         │ (attached  │           │
              │ ready to  │                    │  to one    │           │
              │ use       │                    │  wound)    │           │
              └──────────┘                    └─────┬─────┘           │
                    ▲                                │                  │
                    │                          wound heals             │
                    │                                │                  │
                    │                                ▼                  │
                    │                          ┌───────────┐           │
                    │                          │ REMOVABLE  │           │
               wash with                       │ (wound     │           │
               water                           │  healed,   │           │
                    │                          │  still on)  │           │
                    │                          └─────┬─────┘           │
                    │                                │                  │
                    │                          player removes          │
                    │                                │                  │
                    │                                ▼                  │
                    │                          ┌───────────┐           │
                    └───────────────────────── │  SOILED    │ ──────────┘
                                               │ (used,     │  apply without
                                               │  stained,  │  washing
                                               │  reusable) │  (infection risk)
                                               └───────────┘
```

### 2.1 State Definitions

| State | Description | Player Sees | Mechanical Effect |
|-------|-------------|-------------|-------------------|
| **Clean** | Fresh or washed cloth strip. Optimal condition. | *"A strip of rough wool cloth. Clean and ready for use."* | Can apply to any treatable injury. No infection risk. |
| **Applied** | Wrapped around a specific injury instance. Accelerating healing. | *"Wrapped tightly around your left arm wound. The cloth is holding."* | Attached to one injury. Stops bleeding. Accelerates healing timer. Not in inventory — "on" the player's body at injury site. |
| **Removable** | The underlying wound has healed. Bandage is loose and no longer needed. | *"The bandage on your arm is loose — the wound beneath has closed."* | Still attached but serves no purpose. `injuries` verb hints removal is safe. Player must explicitly remove. |
| **Soiled** | Removed from a healed wound. Blood-stained but structurally intact. | *"A stained cloth strip. Rusty with dried blood, but the weave still holds."* | Can be reapplied (functional), but carries **infection risk** if used on an open wound without washing. Can be washed to return to Clean. |

### 2.2 State Transitions

| From | To | Trigger | Guard Condition | Message |
|------|----|---------|-----------------|---------|
| **Clean** | **Applied** | `apply bandage to [injury]` | Injury must be treatable by bandage (bleeding, open wound). Bandage must be in player's hands or inventory. | *"You wrap the cloth strip tightly around your [body part]. The bleeding slows... and stops."* |
| **Applied** | **Removable** | Injury FSM reaches `healed` state | Automatic — injury heals while bandage is on it. | *"The wound beneath your bandage has closed. The cloth feels loose."* |
| **Removable** | **Soiled** | `remove bandage from [body part]` | Player explicitly removes. | *"You carefully unwrap the bandage. The cloth is stained with dried blood but still serviceable."* |
| **Soiled** | **Clean** | `wash bandage` / `clean bandage with water` | Player has access to water source (rain barrel, stream, flask). | *"You rinse the cloth in the water. The worst of the stain washes out. It's clean enough to use again."* |
| **Soiled** | **Applied** | `apply bandage to [injury]` | Allowed, but adds infection risk to the wound (see §6). | *"You wrap the stained cloth around the wound. It'll hold — but it's not clean. You hope that won't matter."* |
| **Clean** | **Applied** | (same as first row — listed for cycle clarity) | — | — |

### 2.3 Forced Removal (Premature)

A player can remove a bandage from a wound that **hasn't finished healing**:

| From | To | Trigger | Consequence |
|------|----|---------|-------------|
| **Applied** | **Soiled** | `remove bandage from [body part]` while injury is still `active`/`bandaged` | Wound **re-opens**. Bleeding resumes if it was a bleeding wound. Injury FSM reverts: `bandaged` → `active`. Player warned: *"You pull the bandage away. Blood wells up immediately — the wound hasn't closed yet."* |

This is an intentional risk/reward: the player can strip a bandage from one wound to save another, but the first wound starts draining again.

---

## 3. Gameplay Flow

### 3.1 Full Lifecycle — Annotated Walkthrough

```
> tear blanket
"You rip a long strip of wool from the blanket. It's rough but serviceable."
[Inventory: cloth-strip (bandage) — state: CLEAN]

> injuries
"You examine yourself:
  A deep gash on your left arm (bleeding). Blood flows freely."

> apply bandage to left arm wound
"You wrap the cloth strip tightly around your left arm.
 The bleeding slows... and stops. The bandage holds."
[Bandage: CLEAN → APPLIED, attached_to: left-arm-gash]
[Injury left-arm-gash: ACTIVE → BANDAGED, drain stops, healing begins]

> [Several turns pass. Player explores, solves puzzles.]

> injuries
"You examine yourself:
  The wound on your left arm has closed. The bandage is loose."

> remove bandage from left arm
"You carefully unwrap the bandage. The cloth is stained
 with dried blood but still serviceable."
[Bandage: REMOVABLE → SOILED, attached_to: nil]
[Returns to inventory]

> wash bandage in rain barrel
"You rinse the cloth in the cold water. The worst of the stain
 washes out. It's clean enough to use again."
[Bandage: SOILED → CLEAN]

> [Later, a new injury occurs.]

> injuries
"You examine yourself:
  A gash on your right leg (bleeding)."

> apply bandage to right leg
"You wrap the cloth tightly around the gash on your leg.
 The bleeding slows... and stops."
[Bandage: CLEAN → APPLIED, attached_to: right-leg-gash]
```

### 3.2 Quick Reuse (Skip Washing)

```
> remove bandage from left arm
"You carefully unwrap the bandage. The cloth is stained..."

> apply bandage to right leg
"You wrap the stained cloth around the wound. It'll hold —
 but it's not clean. You hope that won't matter."
[Bandage: SOILED → APPLIED, attached_to: right-leg-gash]
[Injury right-leg-gash: infection_risk flag set — see §6]
```

The player can skip washing to save turns — but risks infection. A genuine tactical decision.

---

## 4. Parser Patterns

### 4.1 Apply

| Player Input | Resolution |
|-------------|------------|
| `apply bandage to left arm wound` | Exact target — body part + injury type |
| `apply bandage to left arm` | Body part match — resolves if only one injury on that part |
| `bandage left arm` | Verb shorthand — same resolution |
| `wrap bandage around left arm` | Synonym — same resolution |
| `apply bandage` | Bare verb — auto-resolves if only one treatable injury exists |

**Ambiguity:** If multiple treatable injuries exist and no target specified:
```
> apply bandage
"Which wound? You have:
  A deep gash on your left arm (bleeding)
  A cut on your right hand (bleeding)"
```

**Already applied:**
```
> apply bandage to right hand
"That bandage is already wrapped around your left arm wound.
 You'd need to remove it first — but the arm is still bleeding."
```

### 4.2 Remove

| Player Input | Resolution |
|-------------|------------|
| `remove bandage from left arm` | Explicit target — body part |
| `remove bandage` | Auto-resolves if bandage is only applied to one location |
| `unwrap bandage` | Synonym |
| `take off bandage` | Synonym |

**Not yet healed (warning):**
```
> remove bandage from left arm
"Are you sure? The wound underneath is still open.
 Removing the bandage will re-expose the wound."
> yes
"You pull the bandage away. Blood wells up immediately."
```

### 4.3 Wash

| Player Input | Resolution |
|-------------|------------|
| `wash bandage` | Requires water source in reach (room or inventory) |
| `clean bandage with water` | Explicit water source |
| `wash bandage in rain barrel` | Explicit water source |
| `rinse bandage` | Synonym |

**No water available:**
```
> wash bandage
"You don't have any water to wash with. The cloth stays dirty."
```

### 4.4 Inspect

| Player Input | Resolution |
|-------------|------------|
| `look at bandage` / `examine bandage` | Shows current state, what it's attached to |

**Examples by state:**
- **Clean:** *"A strip of rough wool cloth. Clean and ready for use as a bandage."*
- **Applied:** *"The cloth strip is wrapped tightly around your left arm, covering the wound. Blood has seeped through in places, but it's holding."*
- **Removable:** *"The bandage on your left arm is loose. The skin beneath looks healthy — the wound has closed."*
- **Soiled:** *"A stained cloth strip, rusty with dried blood. The weave still holds. It could be washed and reused."*

---

## 5. Interaction with Injury FSM

The bandage and injury are **two objects with linked state machines**. Each tracks its own state, but transitions in one trigger transitions in the other.

### 5.1 Binding: Bandage ↔ Injury

When a bandage is applied, two links are established:

| Object | Field | Value |
|--------|-------|-------|
| **Bandage instance** | `attached_to` | Injury instance GUID |
| **Injury instance** | `treated_by` | Bandage instance GUID |

These cross-references allow:
- The injury FSM to check "am I bandaged?" when calculating healing rate
- The bandage FSM to check "has my injury healed?" to trigger the `removable` transition
- The `injuries` verb to display bandage status alongside wound status
- The parser to reject "apply this bandage" when it's already attached

### 5.2 Effect on Injury Healing

| Wound Type | Without Bandage | With Bandage | Difference |
|-----------|----------------|-------------|------------|
| **Minor cut** | 5 turns (natural) | 2 turns | Bandage cuts healing time by 60% |
| **Deep wound (bleeding)** | Never stops — fatal | Drain stops immediately; heals in 10 turns | Bandage is the **only** way to survive |
| **Slash wound** | Slow drain, eventually fatal | Drain stops; heals in 8 turns | Mandatory treatment |

### 5.3 Linked FSM Transitions

```
BANDAGE FSM                          INJURY FSM
───────────                          ──────────
                                     [inflicted]
                                         │
                                         ▼
                                     ┌────────┐
                                     │ ACTIVE  │  ← draining health
                                     └───┬────┘
                                         │
   ┌────────┐   "apply bandage"          │
   │ CLEAN  │ ──────────────────────────►│
   └────────┘                            │
       │                                 ▼
       ▼                             ┌────────┐
   ┌────────┐                        │BANDAGED│  ← drain stops,
   │APPLIED │◄──── linked ──────────►│/TREATED│    healing accelerated
   └───┬────┘                        └───┬────┘
       │                                 │
       │    injury timer expires         │
       │         (healed)                │
       ▼                                 ▼
   ┌──────────┐                      ┌────────┐
   │REMOVABLE │◄──── linked ────────►│ HEALED │  ← injury cleared
   └─────┬────┘                      └────────┘
         │
   "remove bandage"
         │
         ▼
   ┌────────┐
   │ SOILED │  ← back in inventory
   └────────┘
```

### 5.4 What the `injuries` Verb Shows at Each Stage

| Injury State | `injuries` Output |
|-------------|-------------------|
| **Active** (no bandage) | *"A deep gash on your left arm (bleeding). Blood flows freely. It won't stop on its own."* |
| **Bandaged/Treated** | *"A deep gash on your left arm (bandaged). The bleeding has stopped. The wound is healing."* |
| **Healed** (bandage still on) | *"The wound on your left arm has closed. The bandage is loose — you could remove it."* |
| **Healed** (bandage removed) | Injury is removed from the list entirely. |

---

## 6. Infection Risk: Clean vs. Soiled

A soiled bandage still *works* — it stops bleeding, it holds the wound together. But it carries biological risk. This creates a meaningful clean/skip-washing decision.

### 6.1 Infection Chance

| Bandage State | Infection Risk on Application |
|---------------|------------------------------|
| **Clean** | None — sterile enough for this world |
| **Soiled** (used once) | Low — small chance of wound infection after 8+ turns |
| **Soiled** (used multiple times without washing) | Moderate — cumulative grime increases risk |

### 6.2 How Infection Manifests

If a soiled bandage triggers infection, the injury gains a secondary complication:

```
> injuries
"You examine yourself:
  The gash on your right leg (bandaged). The wound throbs
  and the skin around the bandage looks red and angry.
  Something isn't right."
```

The wound transitions from `bandaged` to `infected` — requiring a different treatment entirely (clean water + fresh cloth, or herb poultice at Stage 2). The bandage must be removed, the wound cleaned, and a clean bandage reapplied.

**Design note:** Infection from dirty bandages is a **Level 2+ mechanic**. In Level 1, soiled bandages work fine — the player learns the reuse loop without the infection penalty. Infection risk is introduced when the player has access to water sources and the herbal medicine system.

### 6.3 Washing Removes Risk

Washing resets the bandage to `clean`. Any water source works:
- Rain barrel (courtyard, Level 1)
- Stream (wilderness, Level 2)
- Flask of water (portable)
- Well (village, Level 2)

Washing costs one turn — the tradeoff is time vs. infection risk.

---

## 7. The Triage Puzzle

This is the **signature resource-management puzzle** that bandage reusability enables.

### 7.1 Setup

The player has:
- **2 bandages** (cloth strips torn from the blanket)
- **4 wounds:**
  - Left arm — deep gash (bleeding, drain 2/turn) ⚠️ URGENT
  - Right leg — slash wound (bleeding, drain 1/turn) ⚠️ URGENT
  - Right hand — minor cut (no drain, heals in 5 turns)
  - Left shoulder — minor cut (no drain, heals in 5 turns)

### 7.2 The Decision

Two bandages, four wounds, two bleeding. The minor cuts heal on their own. The bleeding wounds are fatal if untreated. But even between the two bleeding wounds, there's a priority:

- **Left arm** drains 2 health/turn — more dangerous
- **Right leg** drains 1 health/turn — slower but still fatal

The optimal play: bandage both bleeding wounds immediately. The minor cuts heal naturally. But what if the player only has **one** bandage?

### 7.3 One Bandage, Two Bleeds

Now it's a real puzzle:

1. **Bandage the left arm first** (higher drain rate)
2. **Wait for left arm to heal** (10 turns, while right leg drains 1/turn)
3. **Remove bandage from healed left arm**
4. **Apply bandage to right leg** (which has been draining for 10 turns)
5. Total health lost: 10 turns × 1 drain = 10 health from the leg

Or:

1. **Bandage the right leg first** (lower drain rate)
2. **Wait for right leg to heal** (8 turns, while left arm drains 2/turn)
3. **Remove bandage from healed right leg**
4. **Apply bandage to left arm** (which has been draining for 8 turns)
5. Total health lost: 8 turns × 2 drain = 16 health from the arm

**Optimal strategy:** Always bandage the higher-drain wound first. The `injuries` verb gives the player enough information to make this calculation — the severity descriptions map to drain rates.

### 7.4 Narrative Tension

```
> injuries
"You examine yourself:
  A deep gash on your left arm (bleeding). Blood flows freely.
  A slash wound on your right leg (bleeding). Blood runs down your calf.
  A minor cut on your right hand (healing).
  A minor cut on your left shoulder (healing)."

> inventory
"You're carrying:
  A cloth strip (clean bandage)"

[Player realizes: one bandage, two bleeding wounds. Which one?]

> apply bandage to left arm
"You wrap the cloth tightly around your left arm.
 The bleeding slows... and stops. The bandage holds.
 But your leg is still bleeding."

> [10 turns of exploration, leg draining 1/turn]

> injuries
"You examine yourself:
  The wound on your left arm has closed. The bandage is loose.
  The slash on your right leg (bleeding). Your boot squelches.
  Your right hand cut has healed.
  Your left shoulder cut has healed."

> remove bandage from left arm
"You unwrap the stained cloth. The arm looks good."

> apply bandage to right leg
"You wrap the cloth around the gash on your leg.
 Finally — the bleeding stops."
```

---

## 8. Bandage vs. Salve — Design Contrast

These two treatment items are deliberately opposite in lifecycle, creating asymmetric gameplay.

| Property | Bandage (Reusable) | Salve (Consumable) |
|----------|-------------------|-------------------|
| **Lifecycle** | clean → applied → removable → soiled → clean | sealed → applied → empty (destroyed) |
| **Uses** | Unlimited (degrades over time, needs washing) | 3 applications, then instance destroyed |
| **Treats** | Bleeding, open wounds (physical binding) | Burns — minor and severe (medicinal) |
| **On wrong target** | Fails gracefully — bandage returned, not consumed | Consumed and wasted — punishing |
| **Strategic question** | "Which wound gets the bandage?" | "Should I use this now or save it?" |
| **Player manages** | Attachment, removal, washing, reapplication | Remaining uses, optimal timing |
| **Scarcity model** | Scarce by *attention* — must track and manage | Scarce by *count* — finite uses |
| **Risk/reward** | Skip washing → infection risk (Level 2+) | Wrong target → permanent loss |
| **Puzzle type** | Triage (which wound?) + timing (when to move it?) | Diagnosis (is this the right treatment?) |

**Why both patterns exist:** Consumables create urgency ("I can't waste this"). Reusables create management gameplay ("I have to track this"). Together, they produce a healing system where every treatment decision has different stakes depending on the item type.

---

## 9. Object Metadata Sketch

This section outlines what Flanders needs to build. Not final Lua — just the shape of the data.

### 9.1 Bandage Base Object

```lua
-- Template for Flanders. Actual GUID assigned at implementation.
{
  id = "bandage",
  name = "cloth strip",
  aliases = { "bandage", "cloth", "strip", "cloth strip", "rag" },
  portable = true,
  hands_required = 0,  -- goes in inventory, not hands
  size = 1,
  weight = 0.1,

  _state = "clean",

  states = {
    clean = {
      description = "A strip of rough wool cloth. Clean and ready for use as a bandage.",
      on_feel = "Rough woven cloth. Dry and clean.",
      on_smell = "Faint wool scent.",
      attached_to = nil,
      treats = { "bleeding", "open_wound", "minor_cut" },
    },
    applied = {
      description = "Wrapped tightly around your %BODY_PART%, covering the wound.",
      on_feel = "The cloth is taut against your skin, damp with blood.",
      on_smell = "Copper and wool.",
      attached_to = "%INJURY_GUID%",  -- set dynamically on transition
      portable = false,  -- can't put an applied bandage in a bag
    },
    removable = {
      description = "The bandage on your %BODY_PART% is loose. The wound has closed.",
      on_feel = "Loose cloth over smooth skin. The wound has healed.",
      on_smell = "Stale blood, fading.",
      attached_to = "%INJURY_GUID%",  -- still linked until removed
      portable = false,
    },
    soiled = {
      description = "A stained cloth strip. Rusty with dried blood, but the weave still holds.",
      on_feel = "Rough cloth, stiff with dried blood.",
      on_smell = "Old blood. Not pleasant.",
      attached_to = nil,
      treats = { "bleeding", "open_wound", "minor_cut" },
      infection_risk = true,  -- flag for Level 2+ infection system
    },
  },

  transitions = {
    { from = "clean",     to = "applied",   verb = "apply",  target = "injury",
      message = "You wrap the cloth strip tightly around your %BODY_PART%. The bleeding slows... and stops." },
    { from = "applied",   to = "removable", trigger = "injury_healed",
      message = "The wound beneath your bandage has closed. The cloth feels loose." },
    { from = "removable", to = "soiled",    verb = "remove",
      message = "You carefully unwrap the bandage. The cloth is stained but still serviceable." },
    { from = "soiled",    to = "clean",     verb = "wash",   requires_tool = "water_source",
      message = "You rinse the cloth in the water. The worst of the stain washes out." },
    { from = "soiled",    to = "applied",   verb = "apply",  target = "injury",
      message = "You wrap the stained cloth around the wound. It'll hold — but it's not clean." },
    -- Premature removal (from applied, wound NOT healed)
    { from = "applied",   to = "soiled",    verb = "remove", guard = "injury_not_healed",
      message = "You pull the bandage away. Blood wells up — the wound hasn't closed." },
  },
}
```

### 9.2 Key Implementation Notes for Bart/Flanders

1. **`attached_to` is a runtime field** — set dynamically when the bandage transitions to `applied`. Contains the injury instance GUID. Cleared on removal.
2. **`injury_healed` trigger** — the injury FSM fires this event when it reaches `healed` state. The bandage FSM listens for it and auto-transitions from `applied` → `removable`. This is an **event-driven transition**, not a verb-driven one.
3. **`portable = false` in applied/removable** — an applied bandage cannot be put in a container or given away. It's "worn" on the player at the injury site.
4. **`%BODY_PART%` and `%INJURY_GUID%`** are template tokens resolved at runtime from the linked injury's metadata.
5. **Multiple bandage instances** are independent. Two cloth strips can be in different states — one `applied` to the left arm, one `clean` in inventory.

---

## 10. Crafting: How Bandages Enter the World

Bandages are not found pre-made. They're **crafted from cloth sources** — the player tears fabric into strips.

### 10.1 Cloth Sources (Level 1)

| Source | Verb | Result | Trade-Off |
|--------|------|--------|-----------|
| **Blanket** (bed) | `tear blanket` | 2 cloth strips | Blanket destroyed — no warmth source for hypothermia |
| **Wool cloak** (wardrobe) | `tear cloak` | 2 cloth strips | Cloak destroyed — no cold protection |
| **Curtains** (window) | `tear curtains` | 3 cloth strips | Curtains destroyed — lose daylight control (room goes bright in daytime, can't dim) |

### 10.2 Crafting Flow

```
> tear blanket
"You grip the wool blanket and pull hard. It tears into rough strips.
 You now have two serviceable pieces of cloth."
[Blanket: intact → torn (destroyed as blanket)]
[Inventory: +2 cloth-strip (bandage), state: clean]
```

No tool required for tearing — bare hands work on fabric. The knife makes it cleaner (more strips? future design decision), but isn't necessary.

### 10.3 Resource Tension

Every cloth source has an alternate use:
- **Blanket** → warmth (hypothermia prevention in cold areas)
- **Cloak** → cold protection (equippable, blocks weather)
- **Curtains** → light control (dim room vs. bright room, visibility management)
- **Cloth strip** → sewing material (repair torn clothing, other crafting)

Tearing fabric for bandages is a **permanent sacrifice**. The player must decide: "Do I need bandages more than warmth?" This is resource puzzle design — every healing resource costs something else.

---

## 11. Edge Cases

### 11.1 No Bandage Available

```
> apply bandage
"You don't have anything to bandage with. You need cloth —
 something you can tear into strips and wrap tight."
```

### 11.2 No Treatable Injury

```
> apply bandage
"You don't have any wounds that need bandaging."
```

### 11.3 Bandage Already Applied Elsewhere

```
> apply bandage to right leg
"That bandage is already wrapped around your left arm wound.
 You'd need to remove it first — but the arm is still bleeding."
```

The message tells the player WHERE the bandage is and implies they'd need to remove it. If the wound is healed, the hint changes:

```
> apply bandage to right leg
"That bandage is still on your left arm — but the wound there
 has healed. You could remove it first."
```

### 11.4 Wrong Injury Type

```
> apply bandage to bruised ribs
"You press the bandage against your bruised ribs. It doesn't help —
 there's nothing to bind, no bleeding to stop. Bruises need rest,
 not wrapping."
```

Bandage is returned to inventory (or stays in hand). Not consumed, not attached. Reusable items are forgiving of experimentation.

### 11.5 Multiple Bandages — Which One?

If the player has two bandages (one clean, one soiled) and says `apply bandage`:

```
> apply bandage to left arm
"Which bandage? You have:
  A clean cloth strip
  A blood-stained cloth strip"
```

Resolution follows standard object disambiguation. If only one bandage is available (the other is applied), auto-resolves.

### 11.6 Remove When No Bandage Applied

```
> remove bandage
"You don't have a bandage applied to any wound."
```

---

## 12. Degradation (Future — Level 3+)

Bandages don't last forever. After enough use cycles, the cloth weakens.

| Uses Without Replacement | Condition | Effect |
|--------------------------|-----------|--------|
| 1–3 cycles | Good | Full effectiveness |
| 4–5 cycles | Worn | Slightly slower healing acceleration |
| 6+ cycles | Fraying | May tear during application (fails, cloth destroyed) |

**Not implemented in Level 1 or 2.** This is a long-term durability mechanic for when players have access to fresh cloth sources and the game needs to create replacement pressure.

---

## 13. Summary: Why Reusable Matters

The bandage lifecycle creates gameplay that consumable items cannot:

1. **Triage decisions** — "Which wound gets the bandage?" is a recurring puzzle, not a one-time choice.
2. **Timing puzzles** — "Has this wound healed enough to move the bandage?" requires checking `injuries` and making risk assessments.
3. **Resource loops** — The apply → heal → remove → wash → reapply cycle is a management minigame layered onto exploration.
4. **Escalating pressure** — Multiple wounds with limited bandages forces prioritization. Each new injury reshuffles the triage order.
5. **Clean vs. dirty tradeoff** — Washing takes time. Skipping risks infection. Both are valid choices with different consequences.
6. **Attachment tracking** — The player must remember (or check) where their bandages are. "Where did I put that bandage?" becomes part of the mental model.

A bandage is a tiny object, but its lifecycle makes it one of the most interactive items in the game.

---

## See Also

- [treatment-targeting.md](./treatment-targeting.md) — Parser patterns for targeting injuries
- [healing-items.md](../player/healing-items.md) — All treatment items, consumable vs. reusable (§12)
- [bleeding.md](./bleeding.md) — Bleeding injury FSM, bandage as primary treatment
- [minor-cut.md](./minor-cut.md) — Minor cut FSM, optional bandage acceleration
- [health-system.md](../player/health-system.md) — Derived health model, injury accumulation
