# Sewing Manual — Object Design

## Description

A dog-eared booklet bound in faded cloth, its pages stained with use. The cover reads: *"A Practical Guide to Needlework for the Desperate and Untalented."* Inside are careful diagrams showing basic stitches, thread tension, and helpful notes on avoiding self-inflicted needle wounds. This is the player's gateway to learning the sewing skill—but only if they read it before it burns.

## FSM States

```
readable → burning → burned
```

- **readable** (default) — Paper in good condition. Can be picked up, examined, read to grant the sewing skill. Timer INACTIVE.
- **burning** — On fire. Emits light. Timer ACTIVE (10 ticks). Cannot be read while burning. Each tick decrements toward destruction.
- **burned** — Consumed. Ceases to exist. Skill knowledge is permanent IF already read; otherwise, lost forever.

## Timer Behavior

**Pattern:** Object-owned timer, managed by engine timed events system.

- Timer **starts** on FSM transition to `burning`
- Timer **counts down** 10 ticks
- Timer **expires** → auto-transition to `burned` (object destroyed)
- While `burning`, the object emits light (`casts_light = true`) and cannot be read
- Burning before reading makes the sewing skill **permanently unavailable** for that playthrough

## READ Verb (New Engine Capability)

The sewing manual introduces a new READ verb to the engine. This is the **only way** to grant the skill.

- **Transitions:** `readable` → reads skill, grants "sewing" ability
- **Tracks state:** Sets internal `skill_granted = true` flag
- **Message on success:** "You study the instructions carefully. You now understand basic sewing."
- **Message if already read:** "You flip through the manual again, but you already know this. The diagrams of running stitches and blanket stitches are familiar now."
- **Cannot read while burning:** If attempted during `burning` state, message: "The manual is ablaze! You can't read it now!"

## Sensory Descriptions by State

| State | Look | Feel | Smell |
|-------|------|------|-------|
| readable (new) | A thin cloth-bound booklet with dog-eared pages and careful diagrams | Soft pages, rounded corners, thin cloth spine | Old paper and faded ink. A faint whiff of lavender pressed between pages. |
| readable (used) | Same booklet, now with marginalia and creases from repeated reading | Supple paper, well-worn spine, slight moisture stains | Paper, ink, and lavender fading. Hints of must. |
| burning | Pages curl and blacken. Orange flames consume the edge. Ash drifts. | Too hot to touch. Wax paper chars and crumbles. | Acrid smoke, burning paper and ink, lavender incinerated. |
| burned | A pile of gray ash and charred cloth scraps. Illegible. | Crumbly ash, fine particles | Smoke and cinders. All scent burned away. |

## Interaction Verbs

| Verb | States | Effect | Notes |
|------|--------|--------|-------|
| **READ** | readable | Grants "sewing" skill (if `skill_granted` false); sets flag true. | New verb. Core mechanic. Cannot read if burning. |
| **TAKE/PICK UP** | readable, burning | Adds to inventory. | Can grab while burning—hurts hands but doesn't prevent it. |
| **DROP** | readable, burning | Removes from inventory, places in room. | Dropped while burning continues to burn. |
| **EXAMINE/LOOK** | all | Shows description + state flavor. | While burning, description warns "ablaze." |
| **BURN/LIGHT/SET ON FIRE** | readable | Transitions readable → burning. Starts timer. | Consumable action. Sets in motion the skill-loss consequence. |

## Skill Granting Mechanics

### Success Path
1. Player finds sewing manual in `readable` state
2. Player uses **READ** verb
3. `skill_granted` flag set to `true`
4. Sewing skill added to player character
5. Manual remains in inventory (or room) but reading it again gives "already learned" message
6. If later burned, skill remains (already learned)

### Failure Path (Burning Before Reading)
1. Player finds sewing manual in `readable` state
2. Player uses **BURN/LIGHT** verb without reading first
3. Manual transitions to `burning` state
4. Timer begins (10 ticks)
5. Player cannot read during `burning` (message: "The manual is ablaze!")
6. Timer expires → manual transitions to `burned`
7. Manual destroyed (ceases to exist)
8. Sewing skill **permanently unavailable** for this playthrough
9. Consequence: Player loses access to sewing-dependent quests/outcomes

## Consequences

**PERMANENT SKILL LOSS:** Burning the manual before reading it is a one-way, irreversible consequence. Once burned:
- The sewing skill is gone for the entire playthrough
- Any object/quest that requires sewing cannot be completed
- This teaches players that documents are fragile and choices matter
- No respec/undo—the burned knowledge is truly lost

This mechanic enforces **meaningful resource scarcity** and makes the player value information.

## Meta Properties

| Property | Value | Notes |
|----------|-------|-------|
| `guid` | `3f8a1c9d-7e52-4b6f-a831-9d4e6f2c8b71` | Unique identifier |
| `template` | `small-item` | Base object type |
| `id` | `sewing-manual` | Internal name |
| `name` | "a dog-eared sewing manual" | Player-visible name |
| `keywords` | manual, book, sewing manual, instructions, pamphlet, booklet, guide | Aliases for parsing |
| `categories` | small, readable, paper | Categorization |
| `size` | 1 | Inventory units |
| `weight` | 0.1 | Negligible |
| `portable` | true | Can be carried |
| `grants_skill` | "sewing" | Skill granted on READ |
| `skill_granted` | false (default) | Tracks if read (boolean) |

## Reusable Pattern: Skill-Granting Documents

This sewing manual is the **template for all skill-granting documents** in the game. The pattern includes:

1. **Document object** with `grants_skill` and `skill_granted` properties
2. **READ verb** required to activate skill grant (not pickup, not examine—must intentionally read)
3. **Paper category** makes it burnable/fragile
4. **FSM with burnability:** readable → burning → burned
5. **Consequence on burn:** If burned before read, skill is permanently unavailable
6. **Tracking:** `skill_granted` flag prevents double-granting

### Implementation Reuse
Any skill-granting document follows this structure:
- `on_read` verb callback checks `skill_granted` flag
- If false, grant skill + set flag to true
- If true, show "already learned" message
- Burning transition: readable → burning → burned
- Burning timer: 10 ticks standard (adjustable per document)
- Destroyed manual = destroyed knowledge

### Examples of This Pattern
- Sewing manual (sewing skill)
- Herbal formulary (herbalism skill)
- Combat treatise (combat skill)
- Merchant's ledger (trading skill)

Each inherits the same FSM, READ verb, and consequence design.

## Implementation Notes

The sewing manual is defined in `src/meta/objects/sewing-manual.lua`:
- Metadata includes `grants_skill = "sewing"` and `skill_granted` flag
- `on_look` function adds flavor text: "It looks like it could be read."
- `on_feel` and `on_smell` provide sensory input (lavender, old paper)
- The object's categories include "paper" (marking it as burnable) and "readable" (marking it as readable)
- FSM states managed by engine: `readable`, `burning`, `burned`
- Timer configuration: 10 ticks in burning state
- `casts_light = true` while burning

The READ verb is a new engine verb that must be implemented to:
- Check object's `grants_skill` property
- Check `skill_granted` boolean flag
- If false, grant skill and set flag to true
- If true, show already-learned message
- Refuse to read if object is in `burning` state

No changes to the object definition are needed for this design; all FSM and timer behavior is engine-managed.

## Design Directives (from Wayne)

1. **READ verb required for skill granting.** Picking up the manual does NOT grant sewing skill. The player must explicitly use READ.
2. **Manual is burnable (paper category).** It has a FSM with readable → burning → burned states.
3. **Burning before reading = permanent skill loss.** This is a meaningful consequence. Once the manual burns, the sewing skill is gone forever for that playthrough.
4. **Skill tracking via boolean.** The manual tracks `skill_granted` state. Once read, burning it doesn't matter—the skill is already learned.
5. **Pattern applies to all skill-granting documents.** This design is the template for herbalism, combat, trading, and any other learnable skill document.
