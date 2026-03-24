# Chest — Object Design

> A heavy wooden storage container requiring two hands to carry. Opens and closes to control access to contents.

## Description

A substantial oak or pine chest with iron bands and a heavy wooden lid. The exterior is solid and sturdy — difficult to move alone. When closed, the lid latches firmly; opening requires deliberate effort (a satisfying mechanical *click* as the latch gives way). The chest dominates physical space; carrying it demands full attention.

**Type:** Container (portable, two-handed)  
**Material:** `oak` (primary) or `pine` (alternative)  
**Status:** 🟢 In Game — `src/meta/objects/chest.lua`

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

## Transitions

| From | To | Verb | Message | Mutate |
|------|-----|------|---------|--------|
| closed | open | open | The iron latch yields with a satisfying *click*. The heavy lid groans open on stiff hinges, releasing a breath of stale, sealed air. | `keywords = { add = "open" }` |
| open | closed | close | You lower the heavy lid. It settles with a deep wooden *thud* and the latch catches with a click. | `keywords = { remove = "open" }` |

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

## Edge Cases

### One-Handed Carry Attempt
The player tries to pick up the chest while holding something in one hand:
- **Response:** "The chest is far too heavy to lift with one hand. You'd need both hands free."
- **If both hands occupied:** "Both your hands are full. You'd need to put everything down first."
- The chest *never* becomes one-handed. Even empty, its size and bulk demand two hands.

### Examining Contents While Closed
Player uses `look inside chest`, `feel inside chest`, or `search chest` while closed:
- **Look inside:** "The lid is shut tight. You can't see inside."
- **Feel inside:** "The lid is latched closed. You can't reach inside."
- **Search:** Per D-PEEK decision, search can *peek* at contents without opening (engine reads `contents` directly). The player doesn't learn the chest opened — search is observational, not mutational.
- **Smell:** Faint storage mustiness seeps through the wood — smell is NOT fully gated. You can smell *something* even through closed wood, but you can't identify individual items by smell alone.

### Put Item in Closed Chest
`put key in chest` while chest is closed:
- **Response:** "The chest is closed. You'd need to open it first."
- The engine checks `accessible` before allowing container placement.

### Get Item from Closed Chest
`get key from chest` while chest is closed:
- **Response:** "The chest is closed. You can't reach what's inside."

### Open Chest While Carrying It
Player is carrying the chest (both hands occupied) and tries to open it:
- **Response:** "You'd need to put the chest down first — you can't open it while carrying it."
- This is a two-step sequence: drop chest → open chest.

### Carrying a Full Chest
The chest's total weight = base weight (20) + contents weight. If contents push total weight beyond a reasonable carry threshold:
- The engine should track combined weight but NOT prevent carrying (the `hands_required = 2` is the constraint, not weight-based failure).
- **Future consideration:** A stamina or encumbrance system could slow movement with heavy loads.

### Dropping a Chest
When dropped (or put down), the chest stays in its current open/closed state. Contents remain inside. The chest lands on the floor surface of the current room.

### Closing the Lid on Contents
If an item is too large to fit and visually "sticks out," the chest can still close (no physics simulation of protruding objects). The `capacity` and `max_item_size` checks happen at insertion time, not at close time.

### Nesting Containers
Per Principle 0.5 (deep nesting), a chest CAN contain other containers (e.g., a leather pouch inside a chest). The engine supports nested containment up to 3 levels. A chest inside another chest is blocked by `max_item_size = 3` vs chest `size = 5`.

## Comedy & Flavor Opportunities

### The Dramatic Lift
When the player first picks up the chest, the description should convey genuine physical effort:
- "You grip the iron handles and heave. The chest comes up reluctantly, like it's been napping and resents the disturbance."
- Subsequent pickups can be shorter: "You hoist the chest again, your arms already remembering the weight."

### The Empty Chest Disappointment
Opening an empty chest should deflate expectations:
- "The lid swings open to reveal... absolutely nothing. The chest's interior stares back at you with the hollow indifference of a broken promise."
- Contrast with opening a chest that HAS contents: "The lid swings open, and the interior gleams with possibility."

### The One-Hand Attempt
The error message for trying to carry one-handed should be gently mocking:
- "You grip one handle and pull. The chest doesn't so much as twitch. It's not *that* kind of chest."

### The Unnecessary Close
If the player closes an already-closed chest:
- "It's already closed. The latch clicks smugly, as if to confirm."

### Acoustic Properties
Tapping or knocking on the chest in different states:
- **Empty, closed:** A hollow *bonk* resonates. "Sounds empty. Or very well-packed."
- **Full, closed:** A dull *thud*. "Something's in there."
- **Open:** The knock just sounds like hitting wood. "Less dramatic without the acoustics."

### The Smell of History
The chest's interior smell should tell a story of what it's been used for:
- "Cedar and old leather — this chest has stored something valuable. Or at least something someone *thought* was valuable."

## Implementation Notes for Flanders

### Key Properties for chest.lua

```
guid = "{GENERATE-NEW-GUID}"    -- Flanders: assign unique GUID at creation
template = "furniture"
id = "chest"
name = "a wooden chest"
material = "oak"                 -- resolves via materials.get("oak")
size = 5
weight = 20
portable = true
hands_required = 2
container = true
openable = true
accessible = false               -- changes per state (false=closed, true=open)
capacity = 8
max_item_size = 3
initial_state = "closed"
_state = "closed"
```

### State-Specific Accessible Flag
- `closed` state: `accessible = false` — blocks all container verbs
- `open` state: `accessible = true` — enables look-inside, feel-inside, put-in, get-from

### Pattern Reference: drawer.lua
The chest follows the exact same FSM + container pattern as `drawer.lua`:
- Two states (closed/open) with per-state `description`, `on_feel`, `on_look`, `accessible`
- Transitions with `mutate` for keyword add/remove
- `on_look` function in open state lists contents via registry
- `on_feel` function in open state reports presence/absence of contents

### Differences from Drawer
| Property | Drawer | Chest |
|----------|--------|-------|
| size | 3 | 5 |
| weight | 2 | 20 |
| capacity | 2 | 8 |
| max_item_size | 1 | 3 |
| reattach_to | "nightstand" | nil (standalone) |
| transition message | "slides out with a soft wooden scrape" | "latch yields with a click, lid groans open" |
| secondary material | none | iron (decorative bands, latch, handles) |

### Iron Hardware Note
The chest has iron bands, hinges, handles, and latch as decorative elements. The primary `material` field is `"oak"`. Iron hardware is described in sensory text but does not need a separate material entry — it's flavor, not a burnable/meltable component (unless a future fire system needs to distinguish).

### Categories and Keywords
```
categories = {"container", "furniture", "wooden"}
keywords = {"chest", "trunk", "storage", "wooden chest", "heavy chest", "treasure chest"}
```

## See Also

- **[Chest Mechanics Design](../design/chest-mechanics.md)** — Two-handed carry system, hand slots, interaction constraints
- **[Container Template](../templates/container.md)** — Base inheritance and open/closed sensory rules
- **[Nightstand](./nightstand.md)** — Another composite object with container behavior (comparison)
- **[Two-Handed Carry Design Requirement](./00-design-requirements.md#req-057-two-handed-carry)** — REQ-057: Player hand slot system

---

**Last Updated:** 2026-07-25  
**Status:** 🟢 In Game — implemented as `src/meta/objects/chest.lua`  
**Implementation Order:** After Container template fully tested; coordinate with hand-slot system (REQ-057)  
**Enhanced by:** Comic Book Guy — added Edge Cases, Comedy & Flavor, Implementation Notes for Flanders  
**Implemented by:** Flanders — 2026-07-27
