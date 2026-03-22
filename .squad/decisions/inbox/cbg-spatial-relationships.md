# D-SPATIAL-HIDE: Spatial Relationships — Hiding vs On-Top-Of

**Author:** Comic Book Guy (Creative Director)  
**Date:** 2026-03-27  
**Status:** Design Complete  
**Approval:** Pending team review  
**Related:** Wayne play-test feedback (2026-03-27)  

---

## Decision

The game must explicitly distinguish between two fundamentally different spatial relationships:

1. **Resting On** — Both objects visible (e.g., candle on nightstand)
2. **Covering/Hiding** — Top visible, bottom HIDDEN (e.g., rug over trap door)

This distinction is the core mystery mechanic. Without it, the game is a flat list of items. With it, the game becomes a treasure hunt.

---

## Context

From Wayne's play-test feedback:

> "The game doesn't distinguish between objects that sit ON something visible and objects that HIDE something beneath them. Both are just 'objects in the room.' This feels flat."

Current implementation treats all spatial relationships as equivalent. The player sees everything at once. But real discovery requires *hidden objects*.

---

## Solution Design

### Four Relationship Types

| Relationship | Example | Top Visible? | Bottom Visible? | Verb |
|--------------|---------|--------------|-----------------|------|
| Resting On | Candle on nightstand | ✓ | ✓ | PUT ON, TAKE FROM |
| Covering | Rug over trap door | ✓ | ✗ | MOVE, LIFT, PULL BACK |
| Behind | Curtains over window | ✓ | ✗ | PULL ASIDE, OPEN, LOOK BEHIND |
| Inside | Matches in matchbox | ~ | ~ | OPEN, CLOSE, PUT IN |

### Discovery Progression

For hidden objects, use a **three-phase reveal**:

1. **Hidden Phase:** Object does NOT appear in SEARCH results
2. **Hint Phase:** EXAMINE of covering object gives ONE sentence hint
3. **Reveal Phase:** Interaction verb (MOVE, LIFT, PULL) triggers dramatic discovery message

**Example:**

```
Phase 1: Hidden
  > search room
  You find: candle, matchbox, pillow.
  [Trap door NOT listed]

Phase 2: Hint
  > examine rug
  A threadbare rug. One corner is noticeably raised.
  
Phase 3: Reveal
  > move rug
  You pull back the threadbare rug. Your foot catches an edge—there's a seam here.
  A wooden trap door, disguised to match the surrounding floor.
```

---

## Key Constraints

### Visibility Gates

Hidden objects are **invisible** until trigger occurs:
- Do NOT list in SEARCH results
- Do NOT list in room object inventory
- Do NOT list in EXAMINE output of room
- Only become visible after move/lift/pull of covering object

### Hint Quality

Hints are ONE sentence, suggestive but not spoilery:
- "One corner is noticeably raised"
- "There's a faint outline here"
- "The floorboards seem loose"

**NOT:**
- "There's a trap door under this"
- "Something valuable is hidden here"

### Discovery Narration

Discovery messages are **2-3 sentences**, sensory, explain the concealment:

**Bad:**
```
Trap door revealed.
```

**Good:**
```
You pull back the rug. Your foot catches on an edge—a seam in the stone. 
A wooden trap door, disguised to match the floor. This is no accident.
```

---

## Gameplay Implications

### This Is How We Hide Puzzles

Every discovery-based puzzle hinges on hidden objects:
- Switch hidden behind portrait
- Key hidden under loose floorboard
- Herb hidden in dark corner
- Secret passage hidden behind movable furniture

### Players Learn Play Patterns

As players discover hidden objects, they learn:
- "I should look UNDER things"
- "I should MOVE furniture"
- "Ordinary surfaces might hide extraordinary secrets"

This is emergent learning, not tutorial text.

### Verb Variety by Cover Type

Different cover types naturally suggest different verbs:
- Rug: MOVE, LIFT, PULL BACK (movable but heavy)
- Curtains: PULL ASIDE, OPEN (hang and open)
- Painting: MOVE, LIFT (wall-hung)
- Furniture: PUSH, PULL (portable but heavy)

Players naturally try different verbs. Mechanics should respond to verb variety.

---

## Anti-Patterns (What NOT To Do)

1. **Don't hide without hints** — Players feel frustrated by trial-and-error discovery
2. **Don't make hidden objects feel arbitrary** — "Why is this key hidden here?"
3. **Don't gate critical paths with hidden objects** — Hidden = reward, not requirement
4. **Don't force a single 'correct' verb** — Let players discover through exploration

---

## Implementation Guidance

### Object Definition (Flanders)

```lua
covers = {
    object_id = "trap-door",
    visible_when_hidden = false,
    hint_in_examine = "One corner seems raised, as if something is beneath it.",
    discovery_message = "You pull back the threadbare rug, revealing a trap door.",
}
```

### Room Layout (Moe)

1. Place hidden object in room layout with `covered_by = "rug"`
2. Covering object gets hint in EXAMINE description
3. Interaction on covering object triggers discovery for hidden object

### Testing (Nelson)

For each hidden object:
- [ ] NOT in SEARCH results while covered
- [ ] EXAMINE hint is ONE sentence, suggestive
- [ ] Verb (MOVE/LIFT/PULL) triggers discovery
- [ ] Discovery message is 2-3 sentences, sensory
- [ ] Hint→Verb progression feels natural
- [ ] Object is NOT on critical path

---

## Related Systems

- **Full Spatial System:** `docs/design/spatial-system.md` (complete data model)
- **Object Designer Guide:** `docs/design/objects/spatial-relationships.md` (design playbook)
- **Search Mechanics:** `docs/search-traverse.md` (visibility rules)
- **Containers:** Separate from hiding (INSIDE is different from COVERING)

---

## Rollout Plan

### Phase 1: Test (Week 1)
- Implement hiding mechanics in trap door + rug
- Test visibility gates (hidden object not in search)
- Test hint clarity (examine gives hint, not spoiler)
- Test discovery narration (dramatic, sensory, explains concealment)

### Phase 2: Expand (Week 2)
- Add 3-5 more hidden objects in Level 1
- Vary cover types (rug, furniture, painting, cloth)
- Test verb variety (MOVE, LIFT, PULL ASIDE)

### Phase 3: Integration (Week 3)
- Verify interaction with search system
- Verify interaction with room traversal
- Verify interaction with puzzle design

### Phase 4: Level 2+ (Future)
- Scale pattern to other levels
- Add complexity (nested hiding, multi-part discovery)

---

## Approval Checklist

- [ ] Design captures Wayne's core insight (distinguish visible vs hidden)
- [ ] Four relationship types cover all player expectations
- [ ] Discovery progression (hidden → hint → reveal) is clear
- [ ] Implementation guidance is actionable for teams
- [ ] Anti-patterns are clear
- [ ] Testing checklist is complete

---

## Conclusion

**Hidden objects are not a feature. They are the core mystery mechanic.**

The difference between a flat world and an engaging one is hiding.

This decision locks in:
- What hidden means (invisible until trigger)
- How hints work (one sentence, suggestive)
- How discovery works (dramatic narration, not mechanical)
- How players learn (through exploration, not exposition)

**Design and build accordingly.**
