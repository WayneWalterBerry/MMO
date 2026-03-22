# Chest — Object Design

> A heavy wooden storage container requiring two hands to carry. Opens and closes to control access to contents.

## Description

A substantial oak or pine chest with iron bands and a heavy wooden lid. The exterior is solid and sturdy — difficult to move alone. When closed, the lid latches firmly; opening requires deliberate effort (a satisfying mechanical *click* as the latch gives way). The chest dominates physical space; carrying it demands full attention.

**Type:** Container (portable, two-handed)  
**Material:** `oak` (primary) or `pine` (alternative)  
**Status:** Design complete; implementation pending

### Sensory Details

| Sense | When Closed | When Open |
|-------|------------|-----------|
| **Look** | Solid wooden chest, iron bands, brass latch. Lid fits snugly. Heavy. | Lid propped open, revealing interior lined with faded cloth. Hinges show wear. Contents visible. |
| **Feel** | Wood smooth with age, iron bands cold, latch sturdy. Heavy to lift. | Smooth interior surfaces, hinges, cloth lining (soft with dust). |
| **Listen** | Latch closes with satisfying *click*. Lid settles with wood-on-wood creak. | Quiet interior (echo if empty, muffled if full). Hinges groan if moved. |
| **Smell** | Old wood, faint iron, storage mustiness. | Interior: cloth, wood, air that's been sealed. Contents smells emerge. |
| **Touch** | Cold iron, warm wood, smooth finish. Substantial weight felt immediately. | Interior cloth feels woven, perhaps with age-rot. |

## Container Mechanics

The chest inherits from the **Container** template with additional two-handed carry constraints (see [Chest Mechanics Design](../design/chest-mechanics.md)).

### Capacity

- **Volume:** 8 item slots (large, deep storage)
- **Weight limit:** 30 units (can hold substantial items; not unlimited)
- **Item size limit:** Max size 3 per item

### Open/Closed States

Chest controls content accessibility via its open/closed state (following Container template sensory rules):

- **Closed:** Contents are **NOT accessible**. Players cannot look, feel, search, or examine items inside.
- **Open:** Contents are **fully accessible**. All sensory verbs work on interior items.

### FSM States

```
closed ↔ open
```

- **closed** (default) — Lid locked/latched shut. Contents hidden, inaccessible. Latch mechanism active.
- **open** — Lid propped open on hinges. Inside surface fully accessible.

## Surfaces

| Surface | State | Capacity | Max Item Size | Accessibility |
|---------|-------|----------|---------------|---|
| **inside** | open only | 8 | 3 | Fully accessible when open; blocked when closed |
| **inside** | closed | 8 | 3 | Hidden (all sensory verbs fail) |

## Interaction Verbs

| Verb | Context | Result | Sensory |
|------|---------|--------|---------|
| **LOOK** | At closed chest | See exterior (metal bands, latch, wood finish) | Visual only |
| **LOOK** | Inside (chest open) | Describe contents, lining, interior | Visual only |
| **FEEL** | On closed chest | Feel wood, iron, weight, sturdy construction | Tactile only |
| **FEEL** | Inside (chest open) | Feel contents, cloth lining, hinges | Tactile only |
| **LISTEN** | To chest (any state) | Describe mechanical sounds (latch, hinges, creaks) | Auditory only |
| **SMELL** | At closed chest | Old wood, faint iron, storage must | Olfactory only |
| **EXAMINE** | At chest | Full sensory detail (see Look, Feel, Listen, Smell above) | Multi-sensory |
| **OPEN** | Closed chest | Transition to open state; hear satisfying click + hinge creak | Auditory feedback |
| **CLOSE** | Open chest | Transition to closed state; hear soft thud + latch click | Auditory feedback |
| **PICK UP** / **TAKE** | Any state | Require both hands free; see [Chest Mechanics](../design/chest-mechanics.md) | Constraint check |
| **PUT DOWN** / **DROP** | Any state | Release chest; hands become available | Hand slot freed |
| **PUT {item} IN chest** | Open only | Place item in inside surface; capacity/weight checked | Success/rejection |
| **GET {item}** | Inside (open only) | Remove item from chest contents | Success/rejection |

## Properties

| Property | Value | Notes |
|----------|-------|-------|
| **Name** | "a wooden chest" / "chest" | Display name; no state suffix |
| **Size** | 5 | Large object |
| **Weight** | 20 (base, empty) | Substantial but portable with two hands |
| **Weight capacity** | 30 | Contents can weigh up to 30 units |
| **Portable** | `true` | Can be moved between rooms (with two-hand constraint) |
| **Hands required** | 2 | Requires both hands to carry |
| **Container** | `true` | Is a container (inherits from Container template) |
| **Categories** | `container`, `furniture`, `wooden` | For object classification |
| **Keywords** | chest, trunk, storage, wooden chest, heavy chest, treasure chest | Search/reference terms |

## Location & Placement

The chest appears in **Level 01** in locations where storage and treasure hunting are relevant:

- **Crypt** — One chest contains rare items (puzzle rewards)
- **Deep Cellar** — Secondary chest contains base supplies
- **Possible future rooms** — Treasure chambers, bandit hideouts, tombs

Instances can be placed on room surfaces (floor, shelf) using the standard spatial system (ON/UNDER/BEHIND).

## Design Rationale

### Why Two Hands?

The two-handed requirement reflects in-world weight and gameplay impact:
- **Realism:** Heavy wooden chest needs both hands to carry safely
- **Strategic choice:** Players sacrifice combat readiness or dual-wielding to transport
- **Inventory puzzle:** Creates moment of vulnerability when moving loot; can't hold candle while carrying
- **Pacing:** Forces deliberate movement choices; can't casually cart full chest around

### Why Portable (Not Furniture)?

Unlike fixed furniture (wardrobe, bed), chests are portable — players move them between rooms. This enables:
- **Treasure hunting loops** — Find chest in one room, carry to another
- **Base building** — Accumulate possessions in a safe location
- **Puzzle mechanics** — Move heavy object to discover secrets beneath/behind

### Prime Directive Connection

Error messages when hands are occupied feel natural and conversational:
- ✅ "You'd need to put the chest down first." (trying to pick up while holding candle)
- ✅ "Both your hands are full." (trying to add item while carrying chest)
- ✅ "There's not enough room in the chest." (when full by count or weight)

These messages guide the player without frustration.

## Interaction Sequence Example

**Scenario:** Player enters crypt, finds chest, wants to carry it back to bedroom.

```
> look
You see a wooden chest in the corner...

> examine chest
[full sensory description]

> open chest
The latch yields with a click. Hinges groan as the lid opens.

> look inside
Inside: a silver key, leather pouch, manuscript scroll

> get key
You take the silver key.

> get pouch
Both your hands are now full carrying the chest. You'd need to put the chest down first.

> drop chest
You set the chest down carefully.

> get pouch
You take the leather pouch.

> get key   [already have it]
Already carrying it.

> take chest
You carefully lift the chest with both hands, taking both hand slots.

> go north  [move to bedroom]
You go north to the Bedroom.
```

## See Also

- **[Chest Mechanics Design](../design/chest-mechanics.md)** — Two-handed carry system, hand slots, interaction constraints
- **[Container Template](../templates/container.md)** — Base inheritance and open/closed sensory rules
- **[Nightstand](./nightstand.md)** — Another composite object with container behavior (comparison)
- **[Two-Handed Carry Design Requirement](./00-design-requirements.md#req-057-two-handed-carry)** — REQ-057: Player hand slot system

---

**Last Updated:** 2026-03-25  
**Status:** Design complete, ready for implementation  
**Implementation Order:** After Container template fully tested; coordinate with hand-slot system (REQ-057)
