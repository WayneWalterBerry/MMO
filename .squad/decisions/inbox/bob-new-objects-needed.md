# New Objects Needed for Real-World Puzzles (020–031)

**Author:** Sideshow Bob (Puzzle Master)  
**Date:** 2026-07-28  
**For:** Flanders (Object Designer)  
**Context:** 12 new puzzle concepts designed in `docs/puzzles/020-031`. Several require objects that don't yet exist in `src/meta/objects/`.

---

## Priority 1: Objects Using Existing Patterns

These can be built using established patterns (FSM states, containment, tool properties):

### 1. `wax-written-scroll`
- **Needed by:** [Puzzle 028 — Wax Seal Secret](../../docs/puzzles/028-wax-seal-secret.md)
- **Description:** Parchment with hidden message written in candle wax (invisible until heated or soot-rubbed)
- **States:** blank → partial-reveal → revealed → burned (terminal)
- **Properties:** `has_hidden_writing: true`, `reveal_method: { "heat", "soot" }`, `hidden_message: "..."` 
- **Pattern:** Similar to tattered-scroll but with hidden-state mechanic
- **Sensory:** FEEL detects waxy texture, SMELL detects beeswax

### 2. `charcoal`
- **Needed by:** [Puzzle 028 — Wax Seal Secret](../../docs/puzzles/028-wax-seal-secret.md)
- **Description:** Piece of burnt wood/carbon for marking surfaces (soot-rubbing technique)
- **States:** normal
- **Properties:** `provides: marking_tool`, `color: black`
- **Pattern:** Simple tool like pencil

### 3. `bread-loaf`
- **Needed by:** [Puzzle 026 — Poisoned Offering](../../docs/puzzles/026-poisoned-offering.md)
- **Description:** Food item, can be poisoned when combined with poison-bottle contents
- **States:** whole → torn → poisoned (when poison applied)
- **Properties:** `is_food: true`, `absorbs_liquid: true`, `is_consumable: true`
- **Pattern:** Similar to wine-bottle but for solid food

### 4. `bait-meat`
- **Needed by:** [Puzzle 025 — Defensive Bear Trap](../../docs/puzzles/025-defensive-bear-trap.md)
- **Description:** Raw meat that attracts creatures/NPCs via scent
- **States:** raw → placed → consumed
- **Properties:** `is_food: true`, `scent_radius: 2`, `attracts: hostile_npcs`
- **Pattern:** Consumable with scent property (new property type)

### 5. `hand-mirror`
- **Needed by:** [Puzzle 024 — Mirror Light Redirect](../../docs/puzzles/024-mirror-light-redirect.md)
- **Description:** Portable mirror for reflecting light; also functions as `is_mirror` for appearance system
- **States:** normal, cracked, broken
- **Properties:** `is_reflective: true`, `is_mirror: true`, `reflection_quality: high`
- **Pattern:** Use mirror design from `docs/design/objects/mirror.md` — portable variant

---

## Priority 2: Room Elements / Furniture

These are fixed room elements requiring level design integration:

### 6. `wooden-barricade`
- **Needed by:** [Puzzle 030 — Rag and Oil Molotov](../../docs/puzzles/030-rag-and-oil-molotov.md)
- **Description:** Flammable obstacle blocking a passage; can be burned
- **States:** intact → burning → destroyed
- **Properties:** `is_flammable: true`, `blocks_exit: true`, `health: 20`
- **Pattern:** Destructible obstacle (new pattern — like vase breakability but for fire)

### 7. `pressure-platform`
- **Needed by:** [Puzzle 023 — Counterweight Gate](../../docs/puzzles/023-counterweight-gate.md)
- **Description:** Stone platform with weight threshold connected to gate via chain/pulley
- **States:** empty → partial → triggered
- **Properties:** `weight_threshold: 50`, `connected_to: portcullis`, `accepts_objects: true`
- **Pattern:** New pattern — weight-accumulating container

### 8. `portcullis`
- **Needed by:** [Puzzle 023 — Counterweight Gate](../../docs/puzzles/023-counterweight-gate.md)
- **Description:** Heavy iron gate controlled by counterweight system
- **States:** closed → partial → open
- **Properties:** `blocks_exit: true` (when closed), `counterweight_chain: pressure-platform`
- **On gate fall effect (pipeline):** `inflict_injury: crushing-wound, damage: 12`
- **Pattern:** Similar to locked-door but mechanically driven

### 9. `sealed-wall-section`
- **Needed by:** [Puzzle 022 — Smoke Draft Reveal](../../docs/puzzles/022-smoke-draft-reveal.md)
- **Description:** Wall section with hidden draft; conceals passage
- **States:** sealed → cracked → open
- **Properties:** `has_draft: true`, `blocks_exit: true`, `is_discoverable: true`
- **Pattern:** Similar to trap-door hidden state mechanic

### 10. `light-beam`
- **Needed by:** [Puzzle 024 — Mirror Light Redirect](../../docs/puzzles/024-mirror-light-redirect.md)
- **Description:** Environmental light source (sunlight through crack, moonbeam, etc.)
- **States:** present, redirected
- **Properties:** `direction: down`, `intensity: strong`, `can_reflect: true`
- **Pattern:** New environmental element (non-portable, non-interactable except via reflection)

---

## No New Objects Needed (Existing Objects Suffice)

These puzzles use ONLY existing objects — they need new transitions/states on existing objects:

| Puzzle | Existing Objects Used | New Transitions Needed |
|--------|-----------------------|------------------------|
| 020 Wine Wound Wash | wine-bottle, bandage, cloth | POUR ON WOUND on wine-bottle |
| 021 Improvised Torch | rag, oil-flask, crowbar | WRAP AROUND, POUR ON compound actions |
| 027 Glass Edge Escape | vase, glass-shard, rope-coil | Spawn-on-break for vase → shards |
| 029 Bandage Before Climb | bandage, rope-coil, ivy | Capability-gating check on climb |
| 031 Triage Under Pressure | bandage, cloth, wine-bottle, water | None — pure systemic puzzle |

---

## Engine Work Needed (For Bart)

Several puzzles require engine-level features:
- **Capability gating:** Injury → restricted verbs (Puzzle 029)
- **Weight threshold system:** Object weight accumulation on platforms (Puzzle 023)
- **Fire-spread mechanics:** Fire propagation to adjacent flammable objects (Puzzle 030)
- **Smoke visibility:** Smoke-follows-air-current system (Puzzle 022)
- **Light-beam reflection:** Directional light bouncing off reflective surfaces (Puzzle 024)
- **NPC behavior patterns:** Creature patrol/eat/approach for pursuit and offering puzzles (025, 026)
- **Thrown-object mechanics:** Ranged targeting with impact effects (Puzzle 030)

---

**Action:** Flanders, please review and prioritize. Priority 1 objects are straightforward. Priority 2 objects need engine features from Bart first. Let me know if you need more detail on any object spec.
