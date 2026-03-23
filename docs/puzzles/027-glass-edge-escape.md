# Puzzle 027: Glass Edge Escape

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty Rating:** Polite (always recoverable, with minor injury consequence)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — minor-cut injury from handling glass without protection  
**New Objects Needed:** ❌ None (all objects exist)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Any room with breakable object + rope/binding restraint |
| **Objects Required** | vase (existing, breakable), rope-coil (existing), cloth (existing — hand protection) |
| **Objects Created** | glass-shard (from broken vase), rope becomes "cut-rope" |
| **Prerequisite Puzzles** | None |
| **GOAP Compatible?** | Partial — GOAP can plan "cut rope" but won't suggest breaking vase for a blade |
| **Multiple Solutions?** | 3 (break vase for shard, find knife, untie knot by hand — slow) |
| **Estimated Time** | 5–10 min (first-time), 2–3 min (repeat) |

---

## Real-World Logic

**Premise:** People trapped and tied up have escaped by breaking nearby objects to get sharp edges. Prisoners have used broken ceramic, glass, or bone to cut through bindings. It's desperate, it's dangerous (you'll cut your hands), and it works. Movies show it because it's real.

**Why it's satisfying:** The player is restrained — hands bound with rope. They can't use their inventory. But there's a vase on a shelf nearby. They knock it off (with their bound hands, or by bumping the shelf). It shatters. They pick up a shard — carefully, but it cuts their fingers. They saw through the rope. Free. Bleeding, but free.

**What makes it real:** The sequence — desperation, breakage, pain, escape — is a universal survival scenario. The minor-cut injury from handling the glass is the price of freedom. It's satisfying because it costs something.

---

## Overview

The player's hands are bound (restrained state). They're in a room without a knife or cutting tool. A ceramic vase sits on a shelf or table — decorative, seemingly useless. The puzzle: **break the vase to create a sharp edge, then use the shard to cut the rope binding your hands.**

The catch: handling a glass/ceramic shard with bound, unprotected hands causes a minor-cut injury. The player can mitigate this by wrapping cloth around the shard first (if they can reach cloth with bound hands), or they accept the cut as the cost of freedom.

---

## Solution Path

### Primary Solution (Break Vase → Cut Rope)
1. Player's hands are bound — most verbs restricted
2. `LOOK` — room description includes "A ceramic vase sits on the shelf, holding dead flowers"
3. `KNOCK vase` or `PUSH shelf` or `BUMP table` — bound-hands action
4. **Vase falls and shatters:** "The vase hits the floor and explodes into fragments. Sharp ceramic shards scatter across the stone."
5. `TAKE shard` — "You carefully pick up a shard. Its edge bites into your fingers — sharp enough."
6. **Minor-cut injury fires** (Effects Pipeline) — "A thin line of blood wells up on your palm"
7. `CUT rope WITH shard` — sawing motion; rope frays and snaps
8. **Result:** Hands free. Minor-cut injury (treatable). Shard retained as tool.

### Alternative Solution A (Protected Hands)
1. After breaking vase, player spots cloth nearby (on floor, draped on furniture)
2. `TAKE cloth` (awkward with bound hands but possible for floor-level cloth)
3. `WRAP cloth AROUND shard` — improvised handle
4. `CUT rope WITH wrapped-shard` — no injury
5. **Result:** Hands free, no injury. Rewards careful observation.

### Alternative Solution B (Find Knife)
1. Room also contains a knife (hidden in drawer, on high shelf)
2. With bound hands: `OPEN drawer WITH bound-hands` (clumsy, slow)
3. `TAKE knife` → `CUT rope WITH knife`
4. **Result:** Clean cut, no injury, but knife was harder to access

### Alternative Solution C (Untie by Hand)
1. `UNTIE rope` — slow, difficult with bound hands
2. Multiple attempts needed: "Your fingers fumble with the knot. It's tight."
3. After 3–5 attempts: "Finally, the knot loosens. You pull your hands free."
4. **Result:** No injury, no tool needed, but costs many turns (time pressure if applicable)

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Handle shard without protection | Minor-cut to hand (Effects Pipeline injury, 2 damage) | Treatable later; not debilitating |
| Break vase but shards land out of reach | "The shards scatter across the floor. You'll have to shuffle over to them" | Move to shards (awkward but possible) |
| Try to break something unbreakable | "You slam into the stone wall. It doesn't break — but your shoulder hurts" | Try breakable object instead |
| Cut too aggressively with shard | Shard breaks mid-cut — need another piece | Pick up another shard from the scattered fragments |
| Bleeding from minor-cut while trying to work | Blood makes shard slippery — takes longer | Persist through it; minor-cut is manageable |

---

## What the Player Learns

1. **Breakable objects create new objects** — destruction is constructive
2. **Improvised tools have costs** — glass cuts, but it's better than staying bound
3. **Protection mitigates injury** — wrapping cloth around the shard prevents the cut
4. **Multiple approaches exist** — break vase, find knife, or untie by hand
5. **Bound-hands restrict but don't eliminate actions** — limited verb set, not zero
6. **Injury-as-cost is a valid game mechanic** — freedom costs blood

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LOOK at vase** | "A ceramic vase on the shelf. Dry flowers protrude from it. It looks fragile" | Fragility hint |
| **FEEL rope** | "Coarse hemp rope, tied tightly. The knot is complex" | Confirms bound state, hints at difficulty of untying |
| **FEEL shard** | "Wickedly sharp edges. You could cut something with this — including yourself" | Tool potential + danger warning |
| **LISTEN** (breaking vase) | "A satisfying crash. Ceramic fragments tinkle across the stone floor" | Confirms destruction |
| **LOOK at shards** | "Sharp fragments of ceramic, some large enough to grip. They glint in the light" | Tool identification |
| **FEEL shelf** | "Wooden shelf, chest height. The vase wobbles when you bump it" | Hint for breaking method |

---

## Prerequisite Chain

**Objects:** vase (✅ — breakable, states: intact, broken), glass-shard (✅ — spawns from breakage), rope-coil (✅), cloth (✅)  
**Verbs:** KNOCK/BUMP (needs bound-hands variant), CUT WITH (✅), WRAP AROUND (needs compound action)  
**Mechanics:** Restrained player state (❌ new — limits available verbs), object spawning on destruction (vase → shards)  
**Puzzles:** None required

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| vase | breakable | intact, broken | `breakable: true`, `on_break_spawns: ["glass-shard", "glass-shard"]` | ✅ (needs spawn-on-break) |
| glass-shard | tool/weapon | normal | `provides: cutting_edge`, `on_feel_effect: minor-cut`, `is_sharp: true` | ✅ |
| rope-coil | binding/restraint | coiled, binding, cut | `can_bind: true`, `can_be_cut: true` | ✅ (needs bound state) |
| cloth | material/protection | normal, wrapped | `absorbs_liquid: true`, `protects_hand: true` | ✅ |

---

## Design Rationale

**Why breakable vase?** The vase already exists in the game as a breakable decorative object. Its destruction currently yields nothing useful — this puzzle gives the breakage mechanical purpose. The glass-shard also already exists. We're connecting two existing objects through a destruction-spawning chain.

**Why Level 3?** The core insight (break something fragile to get a cutting tool) is intuitive but not the first thing most players think of. The bound-hands restriction adds planning complexity. Multiple solutions exist but the "aha" moment — fragile object + sharp edge = escape tool — is the satisfying middle ground between obvious (knife) and obscure.

**Why the injury tax?** Handling broken glass with bare hands cuts you. This is physics. The game respects it. But it also provides the mitigation path (cloth wrapping) for players who think ahead. The injury is minor — a teaching moment, not a punishment.

---

## GOAP Analysis

GOAP can resolve `cut rope` → find cutting tool → use cutting tool on rope. If a knife is available, GOAP handles everything. But if no knife exists, GOAP cannot infer "break vase to create cutting edge." The destruction-as-creation step is the manual puzzle part.

**Manual:** Recognizing breakable object → sharp edge potential.  
**GOAP-resolved:** Once shard exists, using it to cut rope.

---

## Effects Pipeline Integration

**Minor-cut from handling glass shard:**
```lua
-- glass-shard, on_take when player has no hand protection
on_take_effect = {
    type = "inflict_injury",
    injury_type = "minor-cut",
    source = "glass-shard",
    location = "hand",
    damage = 2,
    message = "The shard's edge slices into your palm as you grip it. A thin line of blood wells up.",
}
```

**Mitigated by cloth wrapping:**
```lua
-- glass-shard wrapped in cloth → no on_take_effect fires
-- Cloth property "protects_hand: true" cancels the cut
```

All injury logic in object metadata — Principle 8 compliant.

---

## Notes & Edge Cases

- **Multiple shards:** Vase break creates 2–3 shards. Player has extras if one breaks during cutting.
- **Shard as weapon:** After escaping, the shard remains a cutting tool. Connect to Puzzle 024 (mirror redirect — shard is reflective) and general utility.
- **Bound-hands verb restrictions:** Only allow LOOK, FEEL, LISTEN, SMELL, KNOCK, BUMP, SHUFFLE, and limited TAKE (floor-level only). No OPEN drawers, no complex manipulation.
- **Time pressure variant:** If something dangerous is approaching, the escape becomes urgent. Minor-cut is accepted cost; cloth wrapping is a luxury you might not have time for.
- **No softlock:** Untie-by-hand always works. It's slow but never impossible.

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs restrained-player state → Flanders adds spawn-on-break to vase
