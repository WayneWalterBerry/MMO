# Nelson's Puzzle Feedback — Pass 013

**Date:** 2026-03-21  
**From:** Nelson (QA)  
**To:** Bart (Builder), Wayne (Owner)  
**Re:** Level 1 puzzle flow, critical path, and room design feedback

---

## The Good News First

The writing in Level 1 is **the best atmospheric text I have ever tested.** Every room has its own personality through feel, smell, and listen. The progression from dark cellars to warm hallway is an emotional journey. The deep cellar's "silence that feels intentional" and the crypt's "endings — not violent ones, but the quiet, patient ending of all things" are genuinely moving.

The GOAP crate-crowbar interaction is exactly the kind of magic this engine excels at. Player says `open crate`, engine finds crowbar in hand, auto-applies it. Beautiful.

---

## Critical Puzzle Blockers

### 1. The Crate Puzzle Is 90% There — But the Key Is Trapped

The large crate in storage-cellar has the iron key in `large-crate.inside`. The `open crate` action plays a fantastic animation ("nails shriek as they pull free") but never actually exposes the `.inside` surface. The iron key is permanently inaccessible.

**Suggestion:** The open/pry mutation needs to mark `.inside` as accessible, AND the text should mention seeing the key: *"Inside, nestled in straw: an iron key, dark and heavy."*

### 2. The "With" Problem

Players will 100% try `pry crate with crowbar` or `open crate with crowbar` before bare `open crate`. Both fail. This is the natural phrasing when you have a tool and a target.

**Suggestion:** Either add "pry" as a verb alias for open-with-tool, or teach the parser the "VERB NOUN with NOUN" pattern. This matters for future puzzles too (unlock door with key, light candle with match, etc).

---

## Duplicate Instance Display

The hallway and crypt both have multiple instances of the same object type. The engine prints the ambient description once per instance, creating repetitive walls of identical text.

**Worst case:** Crypt listen → "Stone holds silence like a prayer." × 5

**Suggestion:** The display system needs a dedup pass. Options:
- Group by type_id: "Five stone sarcophagi line the walls."
- Show ambient text once per unique type, with count: "(×5)"
- Give each instance unique ambient text (expensive but most immersive)

The most pragmatic fix: deduplicate by `type_id` during room rendering. Show the ambient text once, prefix with count if > 1.

---

## Moonlight Design Decision

The courtyard has `light_level = 1` (moonlight) but the engine ignores room-level light. Only `casts_light` on objects counts.

**Question for Wayne:** Is moonlight supposed to let you see? If yes, the engine needs to check `room.light_level`. If no, the courtyard description needs rewriting to remove "silver light" and "moonlit" references, because right now it says moonlit but plays dark.

---

## Sarcophagus Puzzle UX

The crypt has 5 sarcophagi, each with different hidden items:
- sarcophagus-2: bronze ring
- sarcophagus-3: silver dagger  
- sarcophagus-4: burial necklace
- sarcophagus-5: tome

But they're all named "a stone sarcophagus" with the same type_id. The player has no way to target a specific one.

**Suggestion options:**
1. Give each a unique name: "the nobleman's sarcophagus", "the warrior's sarcophagus" (tied to carved effigy)
2. Add positional keywords: "first", "second", "third" or "south", "north"
3. Add distinguishing features visible on examine: different carved figures, different inscriptions

Option 1 is best for immersion. The effigies are carved with robed figures — give them distinguishing features players can reference.

---

## Flow Notes

### Candle Resource Management
The candle burns out during the storage-cellar exploration. This is excellent tension — but it means the player needs a second light source for the deep cellar and beyond. The storage-cellar has:
- Oil lantern (needs oil to light)
- Oil flask (oil source!)
- Candle stubs inside small crate (needs small crate opened first)

This is a great multi-step resource puzzle. **But:** if the crate `.inside` bug blocks the candle stubs too, the player may be stuck in the dark permanently.

### Hand Management
With 2 hand slots, the player must constantly juggle: candle (light) + brass key (unlock) → drop key → pick up crowbar → open crate → drop crowbar → pick up iron key. This is interesting resource management but could frustrate players who don't realize they need to drop things.

**Suggestion:** Consider a "put X down" synonym for "drop" — players often resist "dropping" valuable items but accept "setting them down."

### The Hallway Reward
Walking into the lit hallway after 20+ turns in cold dark cellars is **the best moment in the game so far.** The warmth, the light, the beeswax smell — it feels like coming home. Protect this moment. Don't add obstacles between deep-cellar-up and hallway-look.

---

## Priority Summary

| Priority | Issue | Impact |
|----------|-------|--------|
| 🔴 P0 | Crate .inside surface not exposed | Blocks ALL of Level 1 |
| 🟡 P1 | Duplicate instance descriptions | Makes 2 rooms look broken |
| 🟡 P1 | "pry/open with" parser | Major natural language gap |
| 🟠 P2 | Moonlight design decision | Courtyard feels wrong |
| 🟠 P2 | Sarcophagus disambiguation | Crypt puzzle inaccessible |
