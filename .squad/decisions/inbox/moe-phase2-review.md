# Phase 2 Room Placement & World Design Review
**Author:** Moe (World Builder)  
**Date:** 2026-03-27  
**Re:** `plans/npc-combat-implementation-phase2.md` — WAVE-1 creature placement  
**Requested By:** Wayne "Effe" Berry

---

## Executive Summary

Phase 2 creature placement is **SOUND with THREE ACTIONABLE DESIGN NOTES**. Courtyard + hallway + deep-cellar + crypt assignments make ecological sense. Room capacities are adequate. Portal traversal needs clarification. Room descriptions will benefit from creature presence updates post-WAVE-1.

**File Ownership Confirmed:** Moe modifies all 4 room files in WAVE-1 (courtyard, hallway, deep-cellar, crypt).

---

## Review Findings

### 1. **Creature Placement (Room Ecology)**

#### ✅ Cat in Courtyard
- **Rationale (Plan):** Open area, hunts rats
- **Moe Assessment:** 
  - ✅ **STRONG FIT** — Courtyard is sky-visible, well-lit (light_level=1), spacious. Moonlight + cat hunting sensibility aligns perfectly.
  - ✅ Ivy coverage (east wall) provides ambush / hide micro-structure for stalking behavior
  - ✅ Well + cobblestones = natural "rodent territory" signal for prey hunting
  - **Design Note:** Consider adding `on_enter` flavor if cat is alive/present — "You hear a faint hiss from the ivy." (optional, post-combat detection)

#### ✅ Wolf in Hallway  
- **Rationale (Plan):** Territorial — guards passage
- **Moe Assessment:**
  - ✅ **STRONG FIT** — Hallway is territorial chokepoint (single entry/exit model per room topology). Wolf's territorial behavior (territory="hallway") gains mechanical meaning here.
  - ✅ Warm (18°C), well-lit (light_level=3) — wolf comfort zone for active patrol
  - ✅ Portraits + doors create perimeter "markers" for territorial patrolling
  - ⚠️ **Gameplay Tension:** Wolf blocks hallway access. Likely forces alternative route (courtyard → crypt path?). **NOT A PROBLEM** — this is intentional gating.
  - **Design Note:** Room description already suggests emptiness. Consider: "In a corner, something stirs. Eyes catch the torchlight — orange, feral, watching."  (optional)

#### ✅ Spider in Deep-Cellar
- **Rationale (Plan):** Dark, damp habitat
- **Moe Assessment:**
  - ✅ **PERFECT FIT** — Deep-cellar is cold (9°C), unlit (light_level=0), dry (moisture=0.3), isolated. Spider's passive behavior + web-builder FSM aligns with still, dark architecture.
  - ✅ Limestone blocks + altar = natural web-anchor points
  - ✅ Silent environment matches spider's low aggression (10) + quiet predation
  - **Design Note:** No room description update needed — spider presence can emerge via `on_feel` ("sticky threads cross your path") at interaction time.

#### ✅ Bat in Crypt
- **Rationale (Plan):** Dark, ceiling for roosting
- **Moe Assessment:**
  - ✅ **PERFECT FIT** — Crypt is cold (8°C), silent, unlit (light_level=0), vaulted ceiling with natural roosting position. Bat's `roosting_position="ceiling"` + light_reactive behavior creates dynamic sensory gameplay.
  - ✅ Inscriptions + stone niches = ecologically plausible roost anchor points
  - ⚠️ **Light Reactive Trigger:** Bat has `light_reactive=true` with fear reaction (+60 fear) → flee on player light entry. **Confirmed Mechanic** — matches Phase 2 creature specifications (L278 of plan).
  - **Design Note:** When lit, player hears/startles bat. Room description ("Dust motes hang motionless") should NOT mention bat directly until `on_listen` reveals movement post-startle.

---

### 2. **Portal Interactions & Creature Traversal**

#### ⚠️ **CRITICAL DESIGN QUESTION: Can Creatures Use Portals?**

**Plan Context:**
- Phase 2 spec (L258, L269) notes wolf is territorial (`territory="hallway"`) and rat has `can_open_doors=false` (confined to cellar by mechanic).
- No explicit statement: **Can cat/wolf/spider/bat traverse portals (stairs, archways, doors)?**

**Moe Finding:**
- Rat's `can_open_doors=false` suggests creatures have door/portal traversal rules
- Plan specifies no creature "follow player" behavior in Phase 1 (NPCs are autonomous, not linked to player)
- BUT: Wolf hunts cat hunts rat — multi-room hunting chains require traversal

**My Recommendation:**
1. **Portals are passable by creatures by default** (stairways, archways, open/unlocked doors)
2. **`can_open_doors=false` restricts ONLY locked/closed doors** (rat trapped in cellar by closed/locked door, not architectural walls)
3. **Territorial creatures stay home:** Wolf won't leave hallway unless fleeing extreme threat. Bat won't leave crypt. Cat/wolf hunt-patrol confined to "home + adjacent prey rooms"

**Action for Bart/Flanders:** Confirm `can_open_doors=false` semantics in Phase 2 creature specs. If rat is immobile in cellar (L287, rationale "trapped"), clarify:
- Does cellar→hallway door stay locked?
- Or does rat's `can_open_doors=false` block the action?

**Moe Impact:** No room file changes needed IF portals are passable. But if doors MUST be explicitly unlocked/open for creatures, I need to declare door states in room instances.

---

### 3. **Room Capacity & Multi-Creature Cluttering**

#### ✅ Room Capacity Adequate for Phase 2

| Room | Creature | Room Size | Player + Creature | Assessment |
|------|----------|-----------|------------------|------------|
| courtyard | cat | Large (5 objects) | Yes, spacious | ✅ Not cluttered |
| hallway | wolf | Medium (7 objects + 3 doors) | Tight but viable | ✅ Intentional tension |
| deep-cellar | spider | Large (4 objects) | Yes, spacious | ✅ Not cluttered |
| crypt | bat (ceiling) | Medium (5 coffins) | Yes, bat=overhead | ✅ Vertical separation |

**Finding:** Rooms can comfortably hold 1 creature + player + objects. If Phase 3+ adds multi-creature encounters (wolf+cat+rat in hallway), room descriptions will need revision, but Phase 2 is clear.

#### ⚠️ **Narrative Density Note**
- Hallway is already heavily described (7 embedded_presences). Adding wolf presence might feel crowded in narration. **Recommendation:** Wolf presence emerges dynamically ("You hear growling") rather than in static room description. Keep description wolf-free.

---

### 4. **Ecosystem & Predator-Prey Dynamics**

#### ✅ Cat Hunts Rat — Creates Interesting Gameplay

**Spatial Chain:**
```
Bedroom (start) → Courtyard (cat hunts) 
               → Hallway (wolf territorial)
               → Deep-Cellar (rat = PREY REFUGE)
               → Crypt (bat roosts)
```

**Ecosystem Tension:**
1. **Rat in cellar is SAFE** — Cat's prey list includes rat, but cat won't leave courtyard (will we add territorial boundary in Phase 2? *See decisions.md D-COMBAT-NPC-PHASE-SEQUENCING*)
2. **Cat hunts in courtyard** — If player drops bait (cheese/bread) in courtyard, cat eats before hunting
3. **Wolf in hallway blocks cat pursuit** — If cat approaches wolf (e.g., both move toward hallway), wolf's aggression (70) vs cat's (40) → wolf attacks cat. **Multi-creature combat opportunity** (Phase 3+)

**Design Assessment:** ✅ **CREATES EMERGENT GAMEPLAY**. Rat confined to deep-cellar is non-trivial boss puzzle (must navigate past wolf). Cat in courtyard is mid-game encounter. Ecosystem is sound.

---

### 5. **Room Description Updates — Do They Mention Creatures?**

#### ✅ **Current State: Descriptions are Creature-Free (Correct)**

All 4 room descriptions follow **Principle 0.5** (deep nesting) — they describe PERMANENT FEATURES ONLY. No creature presences in text.

**Courtyard (L9):** "cobblestones, well, ivy, sky, walls" — ✅ No cat mention
**Hallway (L10):** "torches, portraits, doors, oak, wainscoting" — ✅ No wolf mention  
**Deep-Cellar (L10):** "limestone vault, altar, symbols, incense-memory" — ✅ No spider mention
**Crypt (L10):** "coffins, inscriptions, candles, silence" — ✅ No bat mention

**Post-WAVE-1 Update Strategy:**
After Flanders creates creature files + Nelson tests pass, Moe will update room `on_listen` (audio sense) to hint at creature presence in darkness:
- **Courtyard:** "...and from the ivy, a faint padding of paws." (optional)
- **Hallway:** "In the torchlight, you catch a shadow moving—too large for a rat." (optional)
- **Deep-Cellar:** "Your light catches something metallic across the stone—a spider's web." (optional)
- **Crypt:** "Above, in the darkness, something shifts. Bat wings? You're not sure." (optional)

These are **OPTIONAL ENHANCEMENTS post-gate**. Not required for WAVE-1 gate passage.

---

### 6. **File Ownership — Moe's Wave-1 Scope**

#### ✅ **Clear Ownership Per Plan (L232-235)**

| Room File | Wave | Action | Rationale |
|-----------|------|--------|-----------|
| `src/meta/rooms/courtyard.lua` | WAVE-1 | MODIFY | Add cat instance |
| `src/meta/rooms/hallway.lua` | WAVE-1 | MODIFY | Add wolf instance |
| `src/meta/rooms/deep-cellar.lua` | WAVE-1 | MODIFY | Add spider instance |
| `src/meta/rooms/crypt.lua` | WAVE-1 | MODIFY | Add bat instance |

**What Moe Does in WAVE-1:**
1. Each room's `instances` array gets ONE new creature entry:
   ```lua
   { id = "cat", type_id = "{flanders-guid-from-cat.lua}" }
   ```
2. NO CHANGES to descriptions, exits, or embedded_presences
3. NO ENGINE MODIFICATIONS (pure data wave)
4. All creature GUIDs come from Flanders' `cat.lua`, `wolf.lua`, etc.

**Coordination Point:**
- Flanders provides creature GUIDs (wait for creature `.lua` files)
- Nelson tests room parsing (post-creature files created)
- Gate-1 verifies creatures load in room context

---

## Summary Assessment

| Aspect | Status | Rationale |
|--------|--------|-----------|
| **Creature Placement** | ✅ | Courtyard/hallway/deep-cellar/crypt assignments ecologically sound |
| **Portal Traversal** | ⚠️ | Needs semantics clarification (Bart/Flanders) — affects future phases |
| **Room Capacity** | ✅ | No cluttering; hallway intentionally tight (good design tension) |
| **Ecosystem** | ✅ | Predator-prey chains create emergent gameplay |
| **Descriptions** | ✅ | Correctly omit creature presences; audio hints optional post-gate |
| **File Ownership** | ✅ | Moe owns all 4 room mods in WAVE-1; no conflicts |

---

## Decisions to File

### D-CREATURE-PORTAL-TRAVERSAL (Pending Clarification)

**Author:** Moe (World Builder)  
**Status:** 🟡 Awaiting Clarification from Bart/Flanders

**Issue:**
- Plan specifies `can_open_doors=false` for rat (cellar-confined)
- But doesn't specify default creature portal traversal behavior
- Wolf hunts cat hunts rat → implies multi-room movement chains
- Need to clarify: Do creatures auto-traverse unlocked portals, or do they require special flags?

**Moe's Assumption for WAVE-1:**
- Creatures can traverse stairways, archways, and OPEN/UNLOCKED doors by default
- `can_open_doors=false` restricts LOCKED/CLOSED door traversal only
- Territorial creatures have behavior rules (e.g., wolf won't leave hallway) — engine-enforced in Phase 2

**Action:** Bart + Flanders confirm in chat before WAVE-1 implementation.

---

## Checkpoints

- [x] Phase 2 plan reviewed (chunk 1-2b, all waves)
- [x] Room files examined (courtyard, hallway, deep-cellar, crypt)
- [x] Creature specifications cross-referenced (L245-280)
- [x] Existing room descriptions verified (creature-free, per Principle 0.5)
- [x] Moe file ownership confirmed (no conflicts, 4 files in WAVE-1)
- [ ] Portal traversal semantics clarified (awaiting Bart/Flanders)
- [ ] Optional room description enhancements designed (post-gate)

---

## Next Steps

1. **Pre-WAVE-1:** Confirm portal traversal semantics with Bart
2. **WAVE-1 (Flanders):** Create `cat.lua`, `wolf.lua`, `spider.lua`, `bat.lua` + `chitin.lua`
3. **WAVE-1 (Moe):** Add creature instances to room files (1 line per room, 4 lines total)
4. **GATE-1:** Verify creatures load in room context
5. **Post-GATE-1 (Optional):** Update room `on_listen` with creature audio hints

---

**Moe's Verdict:** ✅ Phase 2 room placement is **APPROVED FOR IMPLEMENTATION**. Courtyard + hallway + deep-cellar + crypt is a coherent, ecologically sound creature deployment that creates emergent gameplay and spatial drama. No design blockers.

