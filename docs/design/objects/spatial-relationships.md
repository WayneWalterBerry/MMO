# Object Spatial Relationships: Hiding vs On-Top-Of

**Date:** 2026-03-27  
**Designer:** Comic Book Guy (Creative Director)  
**Based on:** Wayne Berry play-test feedback (2026-03-27)  
**Status:** Design Complete  

---

## Core Insight

The game must distinguish between two fundamentally different spatial relationships:

1. **Resting on** — Both objects visible, both discoverable through normal searching
2. **Covering/hiding** — Top object visible, bottom object HIDDEN until the top object is moved

This distinction is the difference between a **descriptive game** and a **discovery game**.

---

## Four Core Spatial Relationships

### 1. Resting On (Both Visible)

**Example:** Candle on nightstand

```
What player sees: "A candle rests on the nightstand."
What player knows: Nightstand exists. Candle exists. Both are visible.
What happens if player searches: Finds both objects.
Interaction required to see both: None.
Real-world analogy: A book on a table — you can see both at once.
```

**Properties:**
- Both objects visible simultaneously
- Both objects discoverable through SEARCH, EXAMINE, LOOK
- No special interaction needed to reveal either object
- Player can take candle without moving nightstand
- Canonical verbs: PUT X ON Y, TAKE X FROM Y

**Gameplay implication:** Straightforward inventory puzzle. "What do I have? What goes where?"

---

### 2. Covering/Hiding (Top Visible, Bottom Hidden)

**Example:** Rug over trap door

```
What player sees: "A threadbare rug covers the stone floor."
What player knows: There is a rug.
What's hidden: Trap door (player doesn't know it exists yet)
Interaction required: Must move/lift/pull back the rug
Discovery moment: "You pull back the threadbare rug, revealing a trap door!"
Real-world analogy: A rug hides a trap door. A painting hides a wall safe. A book hides a bookmark.
```

**Properties:**
- Top object (rug) is visible
- Bottom object (trap door) is INVISIBLE until trigger occurs
- Hidden object does not appear in SEARCH results
- Hidden object does not appear in EXAMINE output
- LOOK UNDER rug gives hints, doesn't reveal completely
- Moving/lifting/pulling the rug triggers revelation
- Canonical verbs: MOVE RUG, LIFT RUG, PULL BACK RUG, LOOK UNDER RUG

**Gameplay implication:** Discovery and puzzle. "What's hidden? How do I reveal it?" This is **mystery as mechanic**.

---

### 3. Behind (Front Visible, Back Hidden)

**Example:** Something behind curtains

```
What player sees: "Red velvet curtains hang from an iron rod."
What player knows: There are curtains.
What's hidden: Whatever is behind the curtains (painting? window? secret door?)
Interaction required: Must open/pull aside/look behind the curtains
Discovery moment: "You pull the curtains aside, revealing a small window."
Real-world analogy: Curtains hide what's outside. A portrait hides a safe. A cabinet door hides shelves.
```

**Properties:**
- Front object (curtains) is visible
- Back object is INVISIBLE until opening/moving the curtains
- Like COVERING, but with a directionality verb (PULL ASIDE, OPEN, LOOK BEHIND)
- Hidden object does not appear in SEARCH results
- LOOK BEHIND or EXAMINE curtains gives hints

**Gameplay implication:** Similar to COVERING, but with different verb expectations.

---

### 4. Inside (Container Mechanics)

**Example:** Matches inside matchbox

This is a container relationship, handled elsewhere in the `containers.md` document. Not covered here, but differs from COVERING because:
- The inside object is potentially **semi-visible** (you can see matches in a glass jar; can't see them in a sealed box)
- Containers use different verbs (OPEN, CLOSE, PUT IN, TAKE FROM)
- Discovery is via OPEN, not via moving the container

---

## Player Experience Design

### Why This Matters

From Wayne's play-test:

> The game doesn't distinguish between a candle on a nightstand and a rug over a trap door. Both are just "objects in the room." This feels flat.

The difference between these two cases is **MYSTERY**. 

- Candle on nightstand: "I can see everything in this room."
- Trap door under rug: "Wait... I didn't know *that* was there."

### How Hiding Creates Engagement

**Hidden objects should feel like discoveries, not data.**

When a player reveals a hidden object:
- The reveal should be **dramatic in narration, not mechanical**
- The discovery should create a **narrative moment**, not just update an inventory
- Players should feel clever for exploring, not confused

### Search and Hints

Search is the player's primary exploration tool. Hidden objects must be handled carefully:

**Level 1: Hidden (No Search Result)**
```
> search room
You find: a candle, a matchbox, a pillow.
[Rug is visible but trap door is NOT listed—it's hidden.]
```

**Level 2: Hint in Examine**
```
> examine rug
A threadbare rug. One corner seems raised, as if something is beneath it.
[Player doesn't know what's under it yet. But they know something IS there.]
```

**Level 3: Full Reveal**
```
> move rug
[Detailed discovery message:]
You pull back the threadbare rug. Your foot catches on an edge—a wooden seam runs through the stone floor. A TRAP DOOR, disguised by its surroundings.
```

This progression creates **puzzle potential**: 
- The hint teaches "look for signs"
- The reveal rewards exploration
- The discovery feels earned, not arbitrary

---

## Gameplay Implications

### This Is How We Hide Puzzle Elements

The game's core mechanic is **discovery through exploration**. Every puzzle hinges on finding what's hidden:

- A switch hidden behind a portrait
- A key hidden under a loose floorboard
- A healing herb hidden in a dark corner
- A secret passage hidden behind movable furniture

**Without hiding, the game is flat. With it, the game is a treasure hunt.**

### Players Learn a New Play Pattern

As players discover hidden objects, they learn:
- "I should look UNDER things"
- "I should MOVE furniture"
- "I should EXAMINE surfaces carefully"
- "Something that seems ordinary might hide something extraordinary"

This is *emergent play pattern*. It teaches the player how to think about the game world.

### Verb Consequences by Cover Type

Different cover types suggest different verbs. The game should encourage exploration through verb choices:

| Cover Type | Suggested Verbs | Real-World Reason |
|-----------|-----------------|-------------------|
| Rug | MOVE, LIFT, PULL BACK | Rugs are heavy but movable |
| Curtains | PULL ASIDE, OPEN, LOOK BEHIND | Curtains hang and open |
| Painting | MOVE, LIFT, LOOK BEHIND | Paintings are wall-hung |
| Furniture | PUSH, PULL, MOVE | Furniture is portable but heavy |
| Cloth | LIFT, PULL BACK, FOLD | Cloth is light and flexible |
| Fallen leaves | BRUSH ASIDE, MOVE, SEARCH | Leaves scatter easily |

Players naturally try different verbs. Hiding mechanics should **respond to verb variety**, not force a single "correct" verb.

---

## Interaction Model

### The Interaction Lifecycle

```
1. DISCOVERY PHASE
   Player encounters rug: "A threadbare rug covers the floor."
   Player assumes: "It's just a rug."
   
2. HINT PHASE  
   Player examines rug: "One corner seems raised, as if something is beneath it."
   Player suspects: "Maybe there's something under here."
   
3. INTERACTION PHASE
   Player moves rug: [Detailed narration of effort]
   
4. REVEAL PHASE
   Player sees what was hidden: Trap door.
   Player is rewarded with discovery.
```

### The Reveal Narration

The reveal is critical. It should be **specific, sensory, and dramatic**:

**Bad:**
```
You move the rug. Trap door revealed.
```

**Good:**
```
You grab the edge of the rug and pull it back. Your foot catches—there's an edge here, a *seam* in the stone. As you move aside more of the rug, the outline becomes clear: a wooden trap door, disguised to match the surrounding floor. Your heart rate picks up. This is no accident.
```

The good version:
- Uses senses (sight: seam, heart rate rising as emotional sense)
- Builds drama ("This is no accident")
- Answers questions without exposition ("disguised to match the floor")
- Creates player investment in what happens next

---

## Design Constraints

### Anti-Patterns (What Not To Do)

1. **Don't hide objects without hints.** 
   - Bad: Player searches room, finds nothing. Later, discovers trap door by random trial.
   - Good: EXAMINE rug gives hint. Player discovers through intentional exploration.

2. **Don't make hidden objects feel arbitrary.**
   - Bad: "Why is the key hidden under this random tile?"
   - Good: "The tile is cracked and loose—clearly something has disturbed it."

3. **Don't punish players for missing hidden objects on their critical path.**
   - Bad: Only solution to puzzle is a hidden object that's too obscure.
   - Good: Hidden objects are alternate solutions or rewards, not mandatory gates.

4. **Don't make "find the hidden thing" a puzzle by itself.**
   - Bad: Player must randomly try every surface to find the trap door.
   - Good: The game gives enough hints that exploration feels targeted, not random.

---

## Implementation Guidance

### For Object Designers (Flanders)

When designing an object with hidden contents:

1. **Declare the relationship in object definition:**
   ```lua
   covers = {
       object_id = "trap-door",
       visible_when_hidden = false,
       hint_in_examine = "One corner seems raised...",
       discovery_message = "You pull back the threadbare rug...",
   }
   ```

2. **Write the hint into EXAMINE output:**
   - The hint should be a single sentence
   - It should suggest something is worth investigating
   - It should NOT spoil what's hidden

3. **Write the discovery message:**
   - 2-3 sentences that describe the reveal
   - Include sensory details
   - Explain WHY it was hidden (camouflage, age, deliberate concealment)

### For Room Designers (Moe)

When laying out a room with hidden objects:

1. **Place hints deliberately.**
   - Don't hide hints too obscurely (defeats the purpose of the hint)
   - Don't make hints so obvious that discovery feels unearned

2. **Consider player expectations.**
   - What surfaces would players naturally examine in this room?
   - What is suspicious or unusual?
   - What invites exploration?

3. **Test the hint → discovery progression.**
   - Does the EXAMINE hint lead naturally to the verb?
   - Does the verb succeed in revealing the hidden object?
   - Is the discovery message satisfying?

---

## Examples in Level 1 (Bedroom)

### The Trap Door Under the Rug

**Setup:**
- Room contains: rug, nightstand, bed, chest
- Hidden object: trap door (under rug)

**Discovery Progression:**

| Step | What Player Does | What Game Shows |
|------|------------------|-----------------|
| 1 | `search room` | "You find: a candle, matches, rug, nightstand, bed, chest." (Trap door NOT listed) |
| 2 | `examine rug` | "A threadbare rug. One corner is noticeably raised, as if something is beneath it." |
| 3 | `move rug` | [Detailed discovery message about trap door] |
| 4 | `examine trap door` | "A wooden door set flush into the stone floor, easy to miss if you weren't looking for it." |

**Puzzle Potential:**
- Does the player think to examine the suspicious rug?
- Does the raised corner hint feel natural or forced?
- When discovered, does the trap door create a *reason* to explore further? (What's down there? Should I go?)

---

## Testing Checklist

For each hidden object:

- [ ] Hidden object does NOT appear in SEARCH results while covered
- [ ] EXAMINE of covering object includes a hint (single sentence, suggestive but not spoilery)
- [ ] MOVE/LIFT/PULL of covering object triggers discovery message
- [ ] Discovery message is 2-3 sentences, sensory, and explains the concealment
- [ ] Hint → Verb progression feels natural (not forced or random)
- [ ] Hidden object is NOT on critical path (players can complete level without finding it)
- [ ] Discovery feels rewarding (players are satisfied, not frustrated)

---

## Related Systems

- **Containers** — `containers.md` covers INSIDE relationships
- **Spatial System** — `spatial-system.md` has the full data model for all relationships
- **Search Mechanics** — `search-traverse.md` defines how SEARCH interacts with visibility
- **Object Discovery** — How objects become known to the player system

---

## Conclusion

Hidden objects are not a nice-to-have feature. They are the **core mystery mechanic** that makes exploration feel rewarding.

The difference between "a flat list of objects" and "a living, mysterious world" is hiding.

Design it carefully. Make the hints work. Write the discovery messages with care. 

**The reveal is the reward.**
