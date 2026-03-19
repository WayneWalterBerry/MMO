# Verb System

**Version:** 1.0  
**Last Updated:** 2026-03-21  
**Author:** Brockman (Documentation)

---

## Overview

The MMO engine uses a **verb-dispatch model** where player commands map to verb handlers. Each verb handler receives the current game context and a noun phrase, then performs the corresponding action.

**Design principle:** No per-interaction LLM tokens. All verbs use fast, local lookup tables. Synonyms map to canonical verbs for consistent behavior.

---

## Verb Categories

### Navigation & Perception (7 verbs)

| Verb | Aliases | Purpose |
|------|---------|---------|
| **LOOK** | *see* | Display full room description including objects and exits |
| **EXAMINE** | *x, find, inspect* | Detailed examination of a specific object |
| **READ** | *(via EXAMINE)* | Read text on an object; delegates to examine |
| **SEARCH** | *(via EXAMINE/LOOK)* | Search a container or location; delegates to examine |
| **FEEL** | *touch, grope* | Tactile sensory verb; describes texture and temperature |
| **SMELL** | *sniff* | Olfactory sensory verb; describes odor |
| **TASTE** | *lick* | Gustatory sensory verb; describes flavor (⚠️ can be dangerous!) |
| **LISTEN** | *hear* | Auditory sensory verb; describes sounds in/around object |

### Inventory Management (6 verbs)

| Verb | Aliases | Purpose |
|------|---------|---------|
| **TAKE** | *get, pick, grab* | Pick up an object and place in hand slots |
| **DROP** | — | Remove item from hand and place in current room |
| **INVENTORY** | *i* | List all carried items (hands + worn + bags) |
| **WEAR** | *put on* | Equip an item from hand to worn slot (e.g., backpack) |
| **PUT** | *place* | Move item from inventory into a container or surface |
| **OPEN** | — | Open a container or door |
| **CLOSE** | *shut* | Close a container or door |

### Object Interaction (8 verbs)

| Verb | Aliases | Purpose |
|------|---------|---------|
| **LIGHT** | *ignite* | Set an object on fire using a fire source and striker surface |
| **STRIKE** | — | Compound tool verb: strike match ON matchbox (fire-making) |
| **EXTINGUISH** | *snuff* | Put out a lit object; consumes 1 charge if applicable |
| **BREAK** | *smash, shatter* | Break an object; triggers mutations and spawns variants |
| **TEAR** | *rip* | Tear an object (paper, cloth); mutations system |
| **WRITE** | *inscribe* | Write text on an object using a writing instrument |
| **CUT** | *slash* | Cut an object using a sharp tool |
| **SEW** | *stitch, mend* | Repair or stitch an object using needle + thread |
| **PRICK** | — | Pierce an object or create a small hole |

### Meta & Help (2 verbs)

| Verb | Aliases | Purpose |
|------|---------|---------|
| **HELP** | — | Display available verbs and command syntax |
| **QUIT** | *exit* | Exit the game |

---

## Total: 31 Verbs

The verb table includes 31 handler entries, accounting for canonical verbs and their aliases.

---

## Tool Verbs: requires_tool / provides_tool

Several verbs use a capability-matching system rather than item-ID matching. Objects declare what capabilities they provide, and verbs check for required capabilities.

### Examples

#### WRITE verb
```
Requires: "writing_instrument"
Objects that provide it: pen, pencil, or player's blood (if bloody state active)
```

#### CUT verb
```
Requires: "sharp_tool"
Objects that provide it: knife, glass shard, needle
```

#### SEAR/BURN (via light)
```
Requires: "fire_source"
Objects that provide it: lit match, torch, candle-lit
```

#### STRIKE verb (compound tool)
```
Requires (matchbox): "fire_source" + "striker_surface"
Matchbox provides both capabilities
```

---

## Sensory Verbs: Multi-Sensory Descriptions

Objects can define multiple sensory descriptions, not just examine text. Each sensory verb delegates to a sensory field on the object if it exists.

### Sensory Fields on Objects

```lua
{
  id = "candle",
  description = "A tallow candle, half-burned.",
  sensory = {
    smell = "It smells faintly of tallow.",
    taste = "Waxy and unpleasant.",
    touch = "Smooth, cool to the touch.",
    listen = "It crackles softly as it burns.",
  }
}
```

If a sensory verb is called and the object has no matching sensory field, a default fallback is printed.

---

## Compound Tool Verbs: Two-Hand Inventory

The STRIKE verb (and similar future compound actions) requires **both hands free** or a strategic tool+target placement:

```
STRIKE match ON matchbox
```

- If both hands are occupied: can't execute
- The matchbox can be in inventory OR on a visible surface
- The player doesn't need to hold both; one can be on a table
- After striking: fire source is consumed, player gains temporary flame state

---

## Mutation Verbs: Object State Machines

When a verb triggers an object mutation, the handler:

1. Resolves the target object
2. Reads the object's `mutations` table
3. Looks for a mutation entry matching the verb (e.g., `mutations.break`)
4. Calls the mutation engine to transform the object
5. Spawns any new objects (e.g., shards from broken mirror)
6. Updates the registry

### Mutation Example

```lua
-- Object definition
{
  id = "mirror",
  mutations = {
    break = {
      becomes = "mirror-broken",
      spawns = { ["glass-shard"] = 3 },
      message = "The mirror shatters into three pieces."
    }
  }
}
```

When `BREAK mirror` is called, the engine:
- Removes the mirror from the room
- Adds mirror-broken to the room
- Adds 3 glass-shards to the room
- Prints the message

---

## Verb Dispatch Flow

```
User Input: "strike match on matchbox"
            ↓
Parser: split into verb="strike" noun="match on matchbox"
            ↓
Lookup: handlers["strike"]
            ↓
Handler receives (ctx, "match on matchbox")
            ↓
Handler finds objects, validates capabilities
            ↓
If valid: execute action (mutate, print feedback)
If invalid: print error message
```

---

## Adding New Verbs

To add a new verb:

1. **Define the handler** in `src/engine/verbs/init.lua`:
   ```lua
   handlers["newverb"] = function(ctx, noun)
       -- implementation
   end
   ```

2. **Add aliases** (if any):
   ```lua
   handlers["alias1"] = handlers["newverb"]
   handlers["alias2"] = handlers["newverb"]
   ```

3. **Update this doc** with the verb entry

4. **Update vocabulary.md** if the verb introduces new terms

---

## Reserved Verbs (Future)

These verbs are likely to be added in future phases:

| Verb | Purpose |
|------|---------|
| TALK/SAY | Interact with NPCs |
| GIVE | Hand an item to an NPC |
| GO/MOVE | Navigate to adjacent room |
| KNOCK | Knock on a door/surface |
| CLIMB | Climb an object |
| PUSH/PULL | Push or pull an object |
| UNDO | Undo last action (time rewinding) |

---

*Maintained by Brockman — Documentation*
