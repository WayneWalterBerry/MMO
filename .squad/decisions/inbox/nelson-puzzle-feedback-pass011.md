# Nelson → Bob: Puzzle Feedback — Pass 011

**Date:** 2026-03-21
**Pass:** 011 (Edge Cases / Stress Testing)
**From:** Nelson (Tester)
**To:** Bob (Puzzle/Content Designer)

---

## Engine Resilience Report

Bob, I beat on this thing hard and it barely flinched. 49 tests targeting every crack I could think of: nonsense verb combos, self-containment, cross-room references, full hands, GOAP with missing prereqs, material interactions in both rooms. **Only 1 real bug found.** The engine is mature.

---

## BUG-036: Self-Containment (for Bart)

`put matchbox in matchbox` succeeds and the matchbox vanishes from the game world. This needs a guard in the containment system: `if item_id == container_id then reject`. Any container is vulnerable — matchbox, drawer (if portable), etc.

---

## Design Feedback for Bob

### 1. Torch Bracket Affordance 🔥

The cellar torch bracket is described as "empty — the torch it once held is long gone." This **screams** "put your candle here" to a player. But both `put candle in torch bracket` and `put candle on torch bracket` return "not a container."

**Suggestion:** Give the torch bracket a "holder" surface that accepts candle/torch objects. This would:
- Provide a free-hands solution (player needs hands free to unlock the door)
- Create a natural gameplay moment (place candle → unlock door → proceed)
- Reward observant players

This feels like it should be THE puzzle of the cellar: you arrive with candle + key, both hands full, door is locked. You spot the bracket, place candle, free a hand, unlock the door. Right now there's no friction — player just drops key, unlocks, done. The bracket could make it elegant.

### 2. Compound "then" Separator

"get candle and light it" works great. "open drawer then get matchbox" does not — "then" isn't recognized as a compound separator. Players will try both natural connectors. Low-priority but easy win.

### 3. Cellar Sensory Atmosphere — EXCELLENT ✅

The sensory responses in the cellar are fantastic:
- `feel barrel`: "Rough wooden staves, damp and slightly soft with age. Iron hoops circle the barrel, rough with rust beneath your fingers."
- `smell`: "Damp earth, cold stone, and something faintly metallic — iron, perhaps, or old blood."
- `listen`: "Silence — save for your own heartbeat."

This is exactly the right tone. The cellar *feels* different from the bedroom. The metallic smell hint and the silence create genuine unease. Keep this quality for deeper rooms.

### 4. Item Persistence Works Perfectly ✅

I dropped a candle in the cellar, went upstairs, came back — candle was still there and still burning. It then burned out naturally while I was in the room. Timed events fire correctly across room transitions. This is solid.

### 5. Deep-Cellar Tease — Good

`north` through the open iron door gives: "That way leads somewhere you cannot yet reach." This is the right message — it tells the player there IS something beyond without breaking immersion. When Room 3 content is ready, this will feel like a natural progression.

### 6. Future Room Warnings

Starting with `--room cellar` produces 47 warnings about missing base classes for rooms 3-7 (deep-cellar, crypt, courtyard, gallery, catacombs). These are expected — world files reference objects that don't have definition files yet. Not a bug, but worth knowing the scope: those rooms reference ~47 unique objects that still need authoring.

---

## Bottom Line

The engine is ready for more content. Both rooms are polished and fun to explore. The self-containment bug (BUG-036) is the only real code issue. The torch bracket affordance is the best design opportunity — it could turn the cellar from a "walk through" into a real puzzle moment.

— Nelson
