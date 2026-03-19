# Puzzle 003: Write in Blood

## Overview

The player has a sheet of paper but needs a writing instrument. Two paths exist: find a pen or pencil (simple), or draw blood from themselves using a knife or pin and use that blood to write (dark and consequential). This puzzle teaches that multiple tools can solve the same problem and that sometimes players must pay a price (injury) to get what they want.

## Room

Bedroom (paper is on a surface; knife/pin location TBD; pen/pencil location TBD)

## Required Objects

- Paper (writable surface)
- Writing instrument (pen, pencil, OR blood from self)
- For blood path: Knife or pin (injury_source tool), and self

## Solution

### Path A: Pen or Pencil (Safe, Simple)

1. **Find pen or pencil** — Player explores and finds a writing tool somewhere in the bedroom (e.g., in a desk drawer, on a shelf).
2. **WRITE {message} ON paper WITH pen** — Player types the verb. The engine checks for `writing_instrument` capability. The pen provides this. The paper mutates: `paper.lua` → `paper-with-writing.lua` (or similar). The paper object's code is rewritten to include the message written on it.
3. **Message is permanent** — Once written with pen, the ink is indelible. The paper becomes a different object with the message embedded in its definition.
4. **Player learns:** Writing requires a tool. Pen/pencil is the simple path.

**Trade-off:** Requires finding the pen/pencil (exploration). But no risk, no injury.

### Path B: Blood (Dark, Consequential)

1. **Find knife or pin** — Player locates a tool with `injury_source` capability (e.g., knife on kitchen counter, pin in sewing kit).
2. **CUT SELF WITH knife** — Player types the verb. The engine processes the self-injury mutation:
   - Player's code mutates from `player.lua` → `player-bloody.lua` (or the player gains a `is_bleeding = true` flag, or they gain a `has_blood_resource = true` capability).
   - Message appears: "You draw the knife across your palm. Blood wells up and drips onto your hand. It hurts. A lot."
   - Player is now in a "bloody" state. They have blood as a resource.
3. **WRITE {message} ON paper WITH blood** — Player types the verb with blood as the writing instrument. The engine:
   - Consumes the blood resource (player's state mutates back to clean).
   - Paper mutates: `paper.lua` → `paper-with-blood-writing.lua`. The paper's code is rewritten to include the message in blood-red text.
   - Message appears: "You draw your bloody finger across the paper, writing in red. The words sink into the fibers. It's disturbing and permanent."
4. **Message is permanent and disturbing** — Blood writing cannot be erased. The paper becomes a dark artifact.
5. **Player learns:** Multiple tools solve the same problem. Blood is a resource obtained through self-injury. Sacrificing yourself has narrative weight.

**Trade-off:** Requires self-injury (risk and role-play cost). But no search for a pen needed. Teaches that sometimes puzzles demand sacrifice.

### Path C: Prick Self WITH Pin (Alternate Injury Method)

Same as Path B, but using a pin instead of a knife:

1. **PRICK SELF WITH pin** — Similar to CUT SELF, but using a pin instead of a knife.
2. **Message appears:** "You prick your finger with the pin. A bead of blood forms. It stings."
3. **Player is now bloody** and can write with blood.

**Trade-off:** Pin causes less narrative drama than a knife but accomplishes the same goal.

## Alternative Solutions

The two main paths (pen/pencil vs. blood) represent the complete solution space. No third path exists in the current design, but the system is extensible:

- **Future:** A pencil, crayon, or any object with `writing_instrument` capability could work.
- **Future:** A blood donor NPC could provide blood without self-injury (if implemented).
- **Future:** A character skill might unlock blood-writing without the injury verb (unlikely, but possible).

## What the Player Learns

1. **Multiple tools solve the same problem** — Both pen and blood satisfy the "write on paper" requirement. The engine matches capability, not specific items.
2. **Blood is a resource** — Injury tools (knife, pin) produce blood. Blood can be used as a writing instrument. This creates a tool chain: injury_tool → blood resource → writing capability.
3. **Self-injury has consequences** — The player must actively choose to hurt themselves. This carries narrative weight. The player's state changes visibly (they become bloody). This is not a consequence-free mechanic.
4. **Paper mutates with content** — When the player writes on paper, the paper's code is rewritten (per D-14). The paper literally becomes a different object that includes the written message. The player's creativity (what they write) becomes part of the game state.
5. **Capability matching enables flexibility** — The engine doesn't care what tool provides the writing capability. Pen, pencil, or blood all work. This teaches that the game is built on matching capabilities, not specific item IDs.
6. **Dark gameplay is optional** — The blood path exists, but the player can avoid it by finding a pen. The game respects player agency in choosing their playstyle.

## Failure Consequences

### Attempting to Write Without a Tool
If the player tries `WRITE {message} ON paper` without a writing instrument in inventory:

- Engine returns: "You have nothing to write with."
- The player must find or create a writing tool.
- **Learning moment:** Tools are required.

### Attempting Injury Without the Right Tool
If the player tries `CUT SELF` without a knife or similar tool:

- Engine returns: "You have no way to cut yourself safely. (Ouch.)"
- The player must find an injury tool first.
- **Learning moment:** Even self-injury requires the right tool.

### Attempting to Write Again After Using Pen
If the player has already written on the paper with pen, attempting to write again:

- The paper may become a different object that is no longer writable (pen ink is permanent).
- Alternative: The player could write over it or on the back (if multiple surfaces exist).
- **Design note:** Pen writing is final. Pencil writing (if implemented) would be erasable.

## Status

**Designed** — Detailed game design established. Awaiting implementation.

---

## Design Notes

### Why Blood as a Writing Instrument?

Per design-directives.md:
- "Blood is a dark, consequential resource. Players must actively choose to injure themselves to get this writing material. This creates moral/physical stakes around writing."
- Blood writing teaches that the game world has dark, serious elements. Not all paths are clean and simple.

### Why Multiple Paths?

- **Accessibility:** Players who dislike self-injury gameplay can find a pen.
- **Replayability:** Players who want a darker experience can choose blood.
- **Skill gating:** Future designs might lock the blood path behind a "dark ritual" skill, making pen the only safe path for most players.

### Tool Chain Design

Blood writing demonstrates a tool chain:
```
injury_tool (knife/pin) → blood resource (player state change) → writing capability → paper mutation
```

This is sophisticated design: multiple systems interact to create an emergent gameplay path.

### Paper as a Canvas

The paper mutates to reflect what the player wrote. Per design-directives.md:
- "When words are written, the paper object's code MUTATES to include those words. The paper literally becomes a different object (paper-with-writing) via the mutation engine. The paper's code IS its state, including whatever the player wrote."

This is the game's philosophy in action: player creativity becomes permanent game state.

---

## Related Systems

- **Tool Convention:** Defined in `design-directives.md` (Tools System section)
- **Paper Object:** Defined in `design-directives.md` (Writing & Paper section)
- **Injury & Blood:** Defined in `design-directives.md` (Injury & Blood section)
- **Mutation Model:** Defined in `design-directives.md` (Mutation Model section)
- **Tool Objects Design:** Full details in `tool-objects.md`
