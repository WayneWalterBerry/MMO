# Puzzle 024: Mirror Light Redirect

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐ Level 4  
**Cruelty Rating:** Polite (no unwinnable states)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ❌ No (uses light system, not injury pipeline)  
**New Objects Needed:** ✅ hand-mirror (portable mirror), light-beam (environmental element)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Long dark passage with one light source at the entrance |
| **Objects Required** | glass-shard (existing) or hand-mirror (new), light source at fixed position |
| **Objects Created** | Light beam redirected — illuminates dark area, reveals hidden content |
| **Prerequisite Puzzles** | None (standalone) |
| **GOAP Compatible?** | No — GOAP has no concept of light redirection |
| **Multiple Solutions?** | 2 (mirror redirect, or carry portable light source the long way) |
| **Estimated Time** | 10–20 min (first-time), 3–5 min (repeat) |

---

## Real-World Logic

**Premise:** Ancient Egyptians are said to have used polished bronze mirrors to reflect sunlight deep into tomb interiors during construction. Lighthouses use mirrors to direct beams. In survival situations, a mirror signal can be seen for miles. Light travels in straight lines and bounces off reflective surfaces — basic optics that any person understands intuitively.

**Why it's satisfying:** The player enters a long passage. At the far end, something glints — but it's too dark to see what. Near the entrance, a beam of light falls through a crack in the ceiling. They have a glass shard (from the broken mirror earlier, still holding "a ghost of a reflection"). They position it in the light beam. The light bounces off the shard and shoots down the passage, illuminating the far end. The player sees what was hidden: an inscription, a keyhole, a passage.

**What makes it real:** Every kid has bounced sunlight off a mirror. This is play-as-physics.

---

## Overview

A long corridor or passage has a single natural light source — a beam of sunlight, moonlight, or firelight entering from a crack, window, or opening at one end. The far end of the passage is pitch black. Something important is at the dark end (inscription, locked door with keyhole, valuable object), but the player can't see it without light.

The puzzle: **redirect the light beam using a reflective surface to illuminate the far end.**

The glass-shard object (existing) is described as having "a ghost of a reflection" — it's a fragment of broken mirror. When positioned in the light beam, it reflects light down the passage.

---

## Solution Path

### Primary Solution (Glass Shard / Mirror Redirect)
1. Player enters long passage — one end has light beam, other end is dark
2. `LOOK` — "A thin beam of light cuts through a crack in the ceiling, falling on the floor near you. The passage stretches east into impenetrable darkness."
3. Player has glass-shard (from earlier — mirror fragment)
4. `HOLD glass-shard IN light` — or `PUT glass-shard IN beam`
5. **Engine response:** "You angle the glass shard into the beam. Light catches the reflective surface and shoots eastward down the passage. For a moment, the darkness at the far end is split by a bright stripe of reflected light."
6. `LOOK east` — "In the reflected light, you can now see: an ancient door set into the wall, its surface carved with symbols. A keyhole glints in the center."
7. **Result:** Far end of passage is now visible; player can see and interact with what's there

### Alternative Solution A (Carry Light Source)
1. If player has a candle, torch, or lantern — simply walk down the passage holding it
2. **Works perfectly** — but consumes fire resources and takes time
3. If player is running low on fire sources, the mirror method conserves them

### Alternative Solution B (Hand Mirror — if found)
1. A hand-mirror object (new) provides cleaner reflection than glass shard
2. `HOLD mirror IN light` — sharper, brighter reflected beam
3. **Result:** Same outcome, but mirror can be repositioned more precisely

### Alternative Solution C (Multiple Reflections — Expert)
1. If the passage turns a corner, one mirror isn't enough
2. Player places shard at first angle, then a second reflective surface at the corner
3. Light bounces twice — around the corner and into the final chamber
4. **Result:** Hardest variant; Level 5 if implemented

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| No reflective surface | Can't redirect light; must carry portable light source | Always have a carry-light alternative |
| Angle the shard wrong | Light bounces into the wall/ceiling, not down the passage | Re-angle — trial and error, no penalty |
| Drop shard in darkness | Hard to find in the dark end of the passage | FEEL to locate it; or bring light to find it |
| Try to carry the light beam | "You can't carry light in your hands" — teaches light is environmental | Use reflective surface instead |
| Break the glass shard further | Smaller fragments are less effective (dim reflection) | Still works, just dimmer |

---

## What the Player Learns

1. **Light is an environmental system** — it can be redirected, not just carried
2. **Objects have secondary properties** — glass shard is a cutting tool AND a mirror
3. **Physics-based problem solving** — angle of incidence, reflection, optics
4. **Environmental interaction** — using room features (light beam) as puzzle components
5. **Conservation of resources** — mirror method saves fire sources for later
6. **Observation rewards** — noticing the "ghost of reflection" property of glass shard pays off

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LOOK** | "A beam of light cuts through a crack in the ceiling. Dust motes dance in it" | Room entry — the light is obvious |
| **LOOK east** | "The passage disappears into darkness. Something might be down there — you can't tell" | Motivates the player to find a way to see |
| **LOOK at glass-shard** | "One side still holds a ghost of a reflection — a fragment of a face, perhaps yours" | Existing description — hints at reflective property |
| **FEEL light beam** | "Warm on your skin. The light is strong enough to read by" | Confirms the beam has real intensity |
| **HOLD shard in light** | "Light catches the surface. For a second, a bright spot dances on the far wall" | Immediate feedback that reflection works |
| **LISTEN east** | "Distant echoes. The passage goes deeper than you expected" | Spatial awareness hint |

---

## Prerequisite Chain

**Objects:** glass-shard (✅ exists — has reflective property in description), hand-mirror (❌ new — optional upgrade)  
**Verbs:** HOLD IN (needs compound target — "hold X in Y"), ANGLE (new verb — or alias for HOLD/TURN)  
**Mechanics:** Light beam as environmental object (❌ new — needs directional light system), reflection calculation (❌ new)  
**Puzzles:** None required, but having the glass-shard from a previous area connects progression

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| glass-shard | tool/mirror | normal | `is_reflective: true`, `provides: cutting_edge` | ✅ (needs reflective property) |
| hand-mirror | tool | normal, cracked, broken | `is_reflective: true`, `is_mirror: true`, `reflection_quality: high` | ❌ New |
| light-beam | environmental | present, blocked, redirected | `direction: down`, `intensity: strong`, `can_reflect: true` | ❌ New room element |
| carved-door | furniture | hidden (dark), visible (lit), open | `requires_light: true` to interact | ❌ New room element |

---

## Design Rationale

**Why glass shard?** It already exists in the game and is described as reflective ("ghost of a reflection"). This is Chekhov's gun — an object property planted earlier that pays off here. Players who noticed the reflective description will feel clever when they use it.

**Why Level 4?** Using a reflective surface to redirect light is non-obvious in a text game context. Most players will try carrying a light source first (which works). The mirror solution requires lateral thinking: "I can redirect EXISTING light instead of consuming my own." The conceptual leap from "mirror reflects my face" to "mirror redirects a light beam" is the puzzle.

**Why is this important for the game?** It introduces light as a manipulable system, not just an on/off binary. Future puzzles can build on this: light-sensitive mechanisms, shadow puzzles, mirror mazes.

---

## GOAP Analysis

GOAP cannot resolve this puzzle. The planner understands "I need to see the far end" → "I need light" → "find light source." But GOAP will route to the carry-light solution (find candle, light it, walk). The mirror-redirect solution requires physics reasoning that GOAP doesn't model.

**Manual puzzle part:** Recognizing light can be redirected; using glass shard as mirror.

**GOAP-resolved part:** Finding and preparing a portable light source (alternative solution).

---

## Notes & Edge Cases

- **Time of day:** If the light beam is sunlight, it's only available during daylight. At night, the mirror method doesn't work and the player must use portable light.
- **Glass shard placement:** Player might `PUT shard ON floor IN beam` as a fixed reflector, freeing their hands. This should work.
- **Mirror vs. shard quality:** Hand-mirror produces clean beam; glass shard produces diffused, dimmer reflection. Both work.
- **Existing mirror property:** The glass-shard description already describes it as reflective — no new lore needed.
- **Multiple bounces (future):** If Bart implements directional light tracking, multi-bounce puzzles become possible (Level 5).
- **No softlock:** Portable light source ALWAYS works as alternative.

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs light-beam system → Flanders builds hand-mirror + light-beam room elements
