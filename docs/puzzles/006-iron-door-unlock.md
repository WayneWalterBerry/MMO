# Puzzle 006: Iron Door Unlock

**Status:** 🟢 In Game (Implicit)  
**Difficulty:** ⭐⭐ Level 2 (Introductory / Direct Lock-Key)  
**Zarfian Cruelty:** Polite (straightforward key requirement, no gotchas)  
**Classification:** 🟢 In Game  
**Pattern Type:** Lock-and-Key (Direct)  
**Author:** Sideshow Bob  
**Last Updated:** 2026-03-21

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Cellar (north exit) |
| **Objects Required** | Brass key, Iron-bound oak door, Padlock |
| **Objects Created** | None (door becomes open state) |
| **Prerequisite Puzzles** | 005 (Bedroom Escape / Trap Door Discovery) |
| **Unlocks** | Deep Cellar (north passage) |
| **GOAP Compatible?** | Yes (full auto-resolution: find brass key, unlock door) |
| **Multiple Solutions?** | 1 (key required; no alternate paths) |
| **Estimated Time** | < 1 min (after key is found) |

---

## Overview

After the player escapes the bedroom via the trap door, they descend into the cellar. A heavy iron-bound oak door stands at the north wall, secured by a massive padlock. The brass key obtained from beneath the bedroom rug is the only solution—this teaches the player that keys persist across rooms and that acquiring one puzzle's reward enables the next puzzle's progression.

---

## Solution Path

### Primary Solution: Unlock with Brass Key

1. **Possess the brass key** — The key must have been acquired during Puzzle 005 (found beneath the rug in the bedroom).
2. **LOOK at door** — Player examines the iron-bound door. Description reveals: "A heavy door of black iron-bound oak stands against the north wall. A massive padlock secures it shut."
3. **FEEL door** — Player touches the door. Feedback: "Your hands find cold iron bands wrapped around heavy oak planks. A massive padlock hangs from a thick hasp—the keyhole is small, meant for a brass key. The door does not budge."
4. **UNLOCK door WITH brass-key** — Player uses the brass key. Compound action: brass-key + padlock → door becomes unlocked.
   - Message: "You turn the brass key. The lock clicks into place with grim finality."
   - Door state mutation: locked = false, description updates to reflect open padlock.
5. **OPEN door** — Player pushes the heavy door open.
   - Message: "You push the heavy door. It swings open with a long, low groan of iron hinges, revealing darkness beyond."
   - Exit becomes accessible. Player can now proceed north to deep cellar.

### Alternative Solutions

**None.** The brass key is the only solution. No alternate tools, tricks, or bypasses exist.

---

## What the Player Learns

1. **Keys persist across rooms** — The brass key obtained in the bedroom works in the cellar. Inventory carries forward.
2. **Locks are matchable constraints** — The padlock requires a brass key specifically (not just "any key"). Capability matching extends to locks.
3. **FEEL provides safety info** — Without trying to force the door, FEEL reveals the padlock and keyhole, guiding the player toward the solution.
4. **Door progression gates content** — Locked doors section off areas. The locked cellar door prevents premature access to deep cellar.
5. **Sensory feedback scales with light** — In darkness (before the player lights the candle they brought, or discovers torches in the cellar), FEEL is more valuable than LOOK.

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Attempt to PUSH/FORCE door without key | Engine returns: "The heavy padlock refuses to budge. You need a way to unlock it first." | Find the brass key from bedroom |
| Lose the brass key somehow | Padlock remains locked indefinitely | Puzzle becomes soft-locked; reload or find alternate path (if any exist in future designs) |
| Try wrong key (if multiple keys exist in future) | Engine returns: "That key doesn't fit this lock." | Find the correct brass key |

---

## Failure Reversibility

**Soft failure.** If the player loses the brass key or doesn't acquire it before reaching the cellar, they must backtrack to the bedroom to retrieve it. No permanent lock-out, but forces planning.

---

## Prerequisite Chain

**Objects:**
- Brass key (found beneath bedroom rug during Puzzle 005)
- Iron-bound oak door (already exists in cellar)
- Padlock (already exists on door)

**Verbs:**
- LOOK (sensory investigation)
- FEEL (sensory investigation)
- UNLOCK (with tool support)
- OPEN (standard movement)

**Mechanics:**
- Container/spatial discovery (to find key under rug)
- Capability matching (key fits lock)
- Room persistence (inventory survives room transitions)

**Puzzles:**
- Puzzle 005 (Bedroom Escape): Must find brass key beneath rug first

---

## Design Rationale

**Why this difficulty?** 
Level 2 introductory puzzle. After the player solves Puzzle 005 (a spatial discovery), they now face a direct lock-and-key puzzle. No lateral thinking required—the solution is obvious once the player has the key. This reinforces that keys are "equipment to keep and use," not consumable resources.

**Why this location?**
The cellar is the immediate next room after escaping the bedroom. Placing a lock-and-key puzzle at the threshold teaches the player that room progression may be gated. This is a tutorial for how dungeons/game spaces work: explore this room, then unlock the next.

**Why this object?**
An iron-bound door is narratively intimidating—it signals "something important beyond." The brass key is not abstract; it's a physical object the player found and now uses. This connection (find object → use object later) creates narrative satisfaction.

---

## GOAP Analysis

**Is this puzzle GOAP-compatible?** 
Yes, fully. GOAP can auto-resolve the entire puzzle:
- Player types: "open the north door" or "go north"
- GOAP plans: find brass key location → LOOK for brass key → TAKE brass key → UNLOCK door WITH brass key → OPEN door → MOVE north
- Or the player can manually execute each step

The puzzle's core insight (brass key unlocks padlock) is taught via sensory feedback (FEEL reveals padlock + keyhole), not obscured. GOAP scaffolding is transparent here.

---

## Notes & Edge Cases

- **Keyhole description:** The description mentions "keyhole shaped like a grinning face" — a tiny flavor detail that makes the lock feel less generic.
- **Door weight:** The heavy door is immobile without first unlocking the padlock. Attempting to PUSH/FORCE fails with appropriate feedback.
- **Multiple keys (future):** If additional keys are introduced, this door's lock spec should clarify that only `brass-key` matches its keyhole.
- **Breakability:** The current door definition shows `breakable = false`, meaning the door cannot be destroyed as an alternative. This forces the lock-and-key solution and teaches the player that keys are non-negotiable in this world.

---

## Status

🟢 In Game — Implicit puzzle discovered in cellar room data. Fully functional via lock/unlock mechanic.

**Owner:** Sideshow Bob  
**Builder:** Implicit (room definition already exists)  
**Tester:** Nelson  
**Last Tested:** 2026-03-21

---

## Related Systems

- **Puzzle 005:** Bedroom Escape (provides brass key prerequisite)
- **Lock/Key Mechanic:** Defined in `tool-objects.md` (compound lock requirements)
- **Room Persistence:** Inventory carries across exits (engine feature)
- **Capability Matching:** Tool convention matching keys to locks
