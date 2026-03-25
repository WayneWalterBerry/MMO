# Puzzle 017: The Chain Mechanism

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐ Level 2 (Introductory / Environmental Discovery)  
**Zarfian Cruelty:** Merciful (impossible to fail, one-step mechanical action)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Environmental/Spatial (Reveal) + Discovery  
**Author:** Comic Book Guy (Creative Director)  
**Last Updated:** 2026-07-23  
**Critical Path:** NO — optional, but gates the ritual path to the silver key (Puzzle 012)  
**Issue:** #126

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Deep Cellar |
| **Objects Required** | Chain (existing), hidden stone alcove (new, room-level) |
| **Objects Created** | Ceremonial incense sticks (×3), beeswax altar candles (×2) — revealed from alcove |
| **Prerequisite Puzzles** | 006 (Iron Door Unlock — must enter Deep Cellar) |
| **Unlocks** | Puzzle 012 ritual path (provides fresh incense), room lighting (candles for sconces) |
| **GOAP Compatible?** | Yes — "PULL chain" is a single-step action, fully auto-resolvable |
| **Multiple Solutions?** | 1 (pull the chain) |
| **Estimated Time** | 1–2 min (discover chain, pull it, examine alcove, take items) |

---

## Overview

The Deep Cellar's vaulted ceiling holds a secret. An iron chain hangs from the central boss — heavy, rust-spotted, ending in a ring at chest height. It was clearly meant to be pulled. When the player does, a counterweight mechanism engages in the ceiling, and a concealed stone panel slides open in the west wall, revealing a hidden stone alcove sealed since the chamber was last used for its original purpose.

Inside the alcove: a bundle of ceremonial incense sticks (frankincense and myrrh resin, preserved by the dry air) and a pair of thick beeswax altar candles. The original builders stored their ritual supplies in a sealed compartment, protected from decay and theft, accessible only to those who knew the mechanism.

This puzzle solves Issue #126's dual problem: the chain has no defined effect, and the room is missing incense and candles. The answer is elegant — the incense and candles were always here. They were just hidden behind the chain mechanism, waiting for someone to pull.

### Why This Matters

The chain puzzle is the **gateway** to Puzzle 012 (Altar Ritual). The incense burner on the altar contains only cold grey ash — spent incense from the last ceremony, centuries ago. The residual resin fragments clinging to the sides are atmospheric detail, not functional fuel. To properly burn incense for the ritual, the player needs the fresh ceremonial incense from the chain alcove.

The beeswax candles serve triple duty:
1. **Room lighting** — Place them in the empty wall sconces to illuminate the Deep Cellar (callback to Puzzle 001: Light the Room)
2. **Ritual offering** — A beeswax candle in the offering bowl fulfills "offer flame to the sleepers" (Puzzle 012)
3. **Light insurance** — If the player's tallow candle is burning low, these are higher-quality replacements with longer burn time

This creates a beautiful dependency chain:

```
Pull Chain (017) → Get Incense + Candles
                 ↓
         Light Incense in Burner + Place Candle in Offering Bowl (012)
                 ↓
         Silver Key Revealed → Unlock Crypt Gate → Enter Crypt (014)
```

The chain puzzle transforms the Deep Cellar from a transit room into a place where discovery is rewarded. It teaches the player that environmental interactions reveal hidden content — an iron chain isn't decoration; it's a mechanism. Pull it.

---

## Solution Path

### Primary Solution: Pull the Chain

1. **Discover the chain** — The chain is room-level, mentioned in the room description. LOOK: "An iron chain hangs from the ceiling, ending in a heavy ring at chest height." FEEL: "Heavy iron links, rough with rust. A large ring at the bottom — meant to be grasped. The chain is taut, connected to something above."
   - The chain is discoverable by both LOOK (if lit) and FEEL (in darkness). The ring at the bottom is an unmistakable affordance — it's meant to be pulled.

2. **PULL chain** — The player grasps the ring and pulls. The chain resists, then gives with a heavy CLUNK. The counterweight mechanism engages in the ceiling. From the west wall comes the sound of stone grinding against stone — slow, deliberate, final.
   - Message: *"You grasp the iron ring and pull. The chain resists, then gives with a heavy CLUNK. Something mechanical shifts in the ceiling above. From the west wall comes the sound of stone grinding against stone — slow, deliberate, final."*
   - The chain locks into its pulled position (one-way ratchet mechanism). It cannot be pushed back.

3. **Investigate the west wall** — The player hears the grinding from the west wall and investigates.
   - LOOK (if lit): "A section of the west wall has slid aside, revealing a shallow stone alcove. Inside, arranged with care on a carved shelf: a bundle of dark sticks bound with twine, and two pale candles."
   - FEEL (in darkness): "Your fingers find an opening in the west wall that wasn't there before — a stone panel has slid back, revealing a shallow recess. Inside: a bundle of stiff sticks, waxy and resinous to the touch, bound with twine. And two thick, smooth cylinders — candles, heavier and finer than tallow."
   - SMELL: "From the open alcove, a sudden wave of fragrance — frankincense and myrrh, concentrated and potent. The incense has been sealed for centuries. The scent is extraordinary."

4. **TAKE items from alcove** — The player takes the incense sticks and/or candles.
   - TAKE incense: "You take the bundle of incense sticks. They're dark amber, sticky with ancient resin, and the smell is intense — like opening a sealed jar of spices."
   - TAKE candle(s): "You take a beeswax candle. It's heavier than your tallow candle — pale, smooth, and smells of honey."

5. **Optional: Place candles in sconces** — PUT candle IN sconce → LIGHT candle → Room illumination increases.
   - This is a micro-puzzle callback to Puzzle 001. The player has done this before (light a candle). Now they do it with better candles in a grander room. The sconces transition from `empty` → `occupied`, and the room gains persistent light.

### Sensory Discovery (The Real Design)

The chain is discoverable in total darkness. This is critical — the Deep Cellar has `light_level = 0`. A player who arrives without a light source (candle burned out, no lantern) can still:

1. FEEL the chain (described in room's `on_feel`: "...your hands find a broad stone surface at waist height")
   - Actually, the chain should be discoverable via room-level FEEL. The current room `on_feel` doesn't mention the chain. **NOTE FOR MOE:** Add chain to room's `on_feel` description.
2. PULL the chain (works in darkness — it's a physical interaction)
3. HEAR the grinding (confirms something happened)
4. FEEL the west wall to find the new opening
5. FEEL inside the alcove to discover the items
6. SMELL the incense burst (the sudden fragrance is a sensory confirmation)

The entire puzzle is solvable without light. This is important — it means even a resource-depleted player can discover the ritual components.

---

## What the Player Learns

1. **Environmental mechanisms exist** — An iron chain in a medieval chamber isn't decoration. It's a mechanism. The player learns that the game world has interactive architecture, not just portable objects. Per Frink's escape room research (§3.2 [21]): "The room itself is a puzzle."

2. **PULL is a verb** — The chain teaches the PULL verb in a natural context. A chain with a ring at the bottom is a universal "pull me" signal. This expands the player's verb vocabulary for future levels.

3. **Hidden compartments reward exploration** — The alcove wasn't visible until the chain was pulled. The game has secrets that require interaction to reveal. This teaches the player to try things — to pull chains, push walls, feel surfaces. Not everything is immediately visible.

4. **Sensory discovery works in darkness** — If the player arrives without light, they can still discover the chain by FEEL, pull it, and find the alcove contents by FEEL and SMELL. This reinforces the multi-sensory interaction system as a survival tool, not just a flavor system.

5. **Resources come from unexpected places** — The incense and candles aren't sitting on a shelf. They're sealed in a hidden compartment. This teaches that thorough exploration yields resources — the game rewards curiosity.

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Don't notice the chain | Miss the alcove entirely | FEEL room, LOOK ceiling, LISTEN (chain clinks) |
| Pull chain but don't investigate west wall | Heard the grinding but don't follow up | FEEL west wall, SMELL (incense fragrance is strong) |
| Don't take incense (only take candles) | Can't complete altar ritual via Path A | Return to alcove; incense persists |
| Don't pull chain at all | Can't do altar ritual; must use sarcophagus path (Path B) for silver key | No permanent consequence — sarcophagus provides alternate path |
| Already used hands for other items | Can't carry incense + candles simultaneously | Set down held item, take what's needed, manage inventory |

### Failure Reversibility

**No failure possible.** The chain is a one-way mechanism (can't be undone), but there's no reason to undo it. The alcove contents persist indefinitely. The player can take items now or return later. Zarfian Merciful: impossible to get stuck or waste resources.

### Two-Hand Inventory Consideration

The player likely arrives with:
- **Hand 1:** Light source (candle, lantern, or nothing if it burned out)
- **Hand 2:** Free, or holding a tool (crowbar from storage cellar?)

Pulling the chain requires one hand on the ring. If both hands are full, the player must set something down first. This creates a micro-decision but not a barrier — the Deep Cellar's stone altar and floor provide ample surface to set items.

Taking items from the alcove requires at least one free hand. The incense bundle is small (size 1) and the candles are small (size 1 each). But with two hands max, the player must make choices:
- Take incense + 1 candle (both hands used if already holding light source)
- Take 2 candles (if prioritizing light over ritual)
- Set down current light → take incense + candle → relight in sconce

This inventory micro-management is appropriate for Level 2 difficulty and reinforces the two-hand constraint taught in the Bedroom.

---

## Objects Required

### Existing Objects (No Changes Needed)

| Object | Role in Puzzle |
|--------|---------------|
| **chain** (`chain.lua`) | The pull mechanism. FSM already defined: `hanging → pulled`. Transition message already describes the mechanical effect. |
| **wall-sconce** (×2, `wall-sconce.lua`) | Receive altar candles for room lighting. FSM already defined: `empty → occupied`. |
| **incense-burner** (`incense-burner.lua`) | Receives ceremonial incense for Puzzle 012. Already has ash/residue description. |

### New Objects Needed (for Flanders)

#### 1. Ceremonial Incense Stick

| Property | Value |
|----------|-------|
| **id** | `incense-stick` |
| **template** | `small-item` |
| **name** | "a stick of ceremonial incense" |
| **material** | `resin` (frankincense/myrrh composite) |
| **keywords** | `incense`, `incense stick`, `resin`, `frankincense`, `myrrh`, `ceremonial incense`, `stick` |
| **size** | 1 |
| **weight** | 0.1 |
| **categories** | `small`, `combustible`, `ritual` |
| **portable** | true |

**Description:** "A dark amber stick of pressed resin, about the length of your hand. It gleams faintly and feels waxy-hard. The smell is extraordinary — concentrated frankincense and myrrh, sharp and sweet and ancient. It was sealed in the alcove for centuries, but the resin preserved itself."

**on_feel:** "Smooth, hard resin. Slightly tacky. Cylindrical, about the length of your hand and the width of a finger. It warms quickly in your grip."

**on_smell:** "Frankincense and myrrh — intense, concentrated, sacred. The smell of churches and temples and old ceremonies. It fills your nose and stays."

**on_listen:** "Silent. It's a stick."

**on_taste:** "Bitter resin, sharp and astringent. Not poisonous, but not pleasant. The taste lingers."

**FSM States:**

| State | Description | Properties |
|-------|-------------|------------|
| `unlit` | Dark amber resin stick, unburned | Default. Fragrant but inert. |
| `burning` | Smoldering, producing fragrant smoke | `provides_tool = "incense_smoke"`, `casts_light = false` (smolders, doesn't flame). Timed: burns for 3600 game-seconds. |
| `spent` | Ash stub, consumed | Terminal. Weight → 0.01. |

**Transitions:**

| From | To | Verb | Requires | Message |
|------|-----|------|----------|---------|
| `unlit` → `burning` | `light` | `fire_source` | "The resin catches the flame and begins to smolder. A thick, fragrant smoke rises — frankincense and myrrh, filling the chamber with the scent of ancient ceremony." |
| `burning` → `spent` | auto (timer) | — | "The incense stick crumbles to a fine grey ash. The smoke thins and fades." |

**Interaction with Incense Burner:**
When placed in the incense burner (`PUT incense IN burner`) and lit, the burner transitions to a `smoldering` state. This satisfies the first condition of Puzzle 012's ritual.

**Instance Count:** 3 sticks in the bundle. The player needs only 1 for the ritual — the extras are insurance (in case one is wasted or lost) and generosity (per Zarfian Merciful: always provide more resources than needed).

---

#### 2. Beeswax Altar Candle

| Property | Value |
|----------|-------|
| **id** | `altar-candle` |
| **template** | `small-item` |
| **name** | "a beeswax altar candle" |
| **material** | `beeswax` |
| **keywords** | `candle`, `altar candle`, `beeswax candle`, `white candle`, `wax candle`, `beeswax`, `ceremonial candle` |
| **size** | 1 |
| **weight** | 0.4 |
| **categories** | `light source`, `small`, `combustible` |
| **portable** | true |

**Description:** "A thick candle of pale beeswax, slightly yellowed with age but structurally perfect — the dry air preserved it. It's heavier and finer than the tallow candle you woke with. The wick is long and untrimmed. It smells of honey."

**on_feel:** "Smooth beeswax, firm and cool. Thicker than a tallow candle — about two fingers wide. The surface has a faint honeycomb texture. The wick is stiff and long."

**on_smell:** "Honey and beeswax. Clean and sweet — a world away from the rancid animal fat of tallow. This was made for ceremony, not utility."

**on_listen:** "Silent."

**on_taste:** "Beeswax. Faintly sweet, waxy, inoffensive. Better than tallow."

**FSM States:**

| State | Description | Properties |
|-------|-------------|------------|
| `unlit` | Pale beeswax candle, perfect condition | Default. No light. |
| `lit` | Burning with a clear, steady flame | `casts_light = true`, `light_radius = 2`, `provides_tool = "fire_source"`. Burns cleaner and brighter than tallow. Timed: 5400 game-seconds (90 min — 50% longer than tallow's 7200 due to denser wax, but the candle is shorter, having been in storage). |
| `extinguished` | Recently blown out, relightable | `casts_light = false`. Wick warm. Wax dripped. |
| `spent` | Consumed, pool of hardened wax | Terminal. Weight → 0.05. |

**Transitions:**

| From | To | Verb | Requires | Message |
|------|-----|------|----------|---------|
| `unlit` → `lit` | `light` | `fire_source` | "The beeswax catches cleanly — a bright, steady flame, warmer and whiter than tallow. The honey-sweet scent of burning beeswax fills the air." |
| `lit` → `extinguished` | `extinguish` / `blow` | — | "You blow out the candle. A clean wisp of sweet smoke. The darkness is less total here — your eyes remember the light." |
| `extinguished` → `lit` | `light` / `relight` | `fire_source` | "The wick catches again. The beeswax flame is steady and reliable." |
| `lit` → `spent` | auto (timer) | — | "The altar candle gutters and dies. A pool of pale wax marks where it stood." |

**Material Properties (Beeswax):**

| Property | Value | Rationale |
|----------|-------|-----------|
| hardness | 2 | Soft wax |
| density | 960 | Slightly denser than tallow (920) |
| fragility | 0.3 | Flexible, doesn't shatter — bends/dents |
| flammability | 0.8 | Highly flammable (fuel) |
| melting_point | 63°C | Higher than tallow (48°C) — burns slower |

**Design Note — Beeswax vs. Tallow:**
Beeswax candles are BETTER than tallow in every way that matters to the player:
- Brighter flame (cleaner burn, no sputtering)
- Sweeter smell (honey vs. rancid fat)
- Slightly longer burn per unit mass (higher melting point)
- Cleaner feel (no greasy residue)

This creates a tangible sense of upgrade — the player has been using the poor-man's candle (tallow). The ceremonial candles are the rich-man's version. The difference is sensory, not just mechanical. Per Frink's environmental storytelling (§2.6): the candle quality tells a story about who built this chamber and what they valued.

**Instance Count:** 2 candles in the alcove. One for a sconce (room light), one for the offering bowl or personal use. Or both in sconces if the player has the lantern from Puzzle 010. The allocation is the player's choice.

---

#### 3. Hidden Stone Alcove (Room-Level State Change)

The alcove is not a portable object — it's a **room feature** revealed by the chain mechanism. It should be modeled as a room-level state change or a hidden object that becomes accessible.

**Implementation Pattern (for Bart/Flanders):**

The alcove can be modeled as a hidden `surface` on the room that becomes accessible when the chain is pulled:

```lua
-- In deep-cellar.lua, add to instances:
{ id = "stone-alcove", type = "Stone Alcove", type_id = "{new-guid}",
    contents = {
        { id = "incense-stick-1", type_id = "{incense-guid}" },
        { id = "incense-stick-2", type_id = "{incense-guid}" },
        { id = "incense-stick-3", type_id = "{incense-guid}" },
        { id = "altar-candle-1",  type_id = "{candle-guid}" },
        { id = "altar-candle-2",  type_id = "{candle-guid}" },
    },
    hidden = true,  -- revealed when chain is pulled
},
```

**The alcove object itself:**

| Property | Value |
|----------|-------|
| **id** | `stone-alcove` |
| **template** | `furniture` |
| **name** | "a stone alcove" |
| **material** | `stone` |
| **keywords** | `alcove`, `niche`, `stone alcove`, `compartment`, `recess`, `opening`, `wall niche` |
| **size** | 3 |
| **weight** | — (immovable, part of wall) |
| **portable** | false |
| **hidden** | true (initially); false after chain is pulled |

**Description (revealed):** "A shallow alcove in the west wall, revealed when the stone panel slid aside. The recess is about two feet deep and lined with smooth stone. On a carved shelf inside: a bundle of dark sticks bound with old twine, and two pale candles standing upright in carved holders. A wave of concentrated incense scent washes out — frankincense and myrrh, sealed here for centuries."

**on_feel (revealed):** "Smooth stone recess in the wall, about two feet deep. A carved stone shelf inside holds objects — a bundle of stiff sticks (waxy, resinous) and two thick, smooth candles. The stone inside is dry and warmer than the walls — sealed air, undisturbed for centuries."

**on_smell (revealed):** "The concentrated fragrance of frankincense and myrrh floods out the moment the panel opens. Centuries of sealed resin, released in an instant. It's overpowering for a moment, then settles into a rich, warm background — transforming the chamber's dusty silence into something that smells like prayer."

**on_listen:** "Stone. Silent."

**Surfaces:**

```lua
surfaces = {
    inside = {
        capacity = 5, max_item_size = 2, weight_capacity = 5,
        contents = {"incense-stick-1", "incense-stick-2", "incense-stick-3",
                    "altar-candle-1", "altar-candle-2"},
        accessible = true,
    },
},
```

---

### Chain Mechanism — Technical Integration (for Bart)

The chain's `pulled` transition should trigger the alcove reveal. Implementation options per Principle 8 (objects declare behavior, engine executes):

**Option A — Transition trigger on chain:**
```lua
-- In chain.lua, add to the pulled transition:
triggers = {
    { target = "stone-alcove", action = "reveal" },
},
```

**Option B — Room-level event listener:**
```lua
-- In deep-cellar.lua, add:
on_state_change = {
    { object = "chain", state = "pulled", trigger = {
        { target = "stone-alcove", set = { hidden = false } },
    }},
},
```

Recommend **Option B** — keeps the coupling in the room metadata (where spatial relationships are defined), not on the chain object itself. The chain doesn't need to "know" about the alcove; the room knows that when the chain is pulled, the alcove is revealed. This is cleaner for Principle 8 compliance.

---

## Incense & Candle Placement Design

### The Problem (Issue #126)

The Deep Cellar room description references incense ("the smell of ancient dust, old wax, and something fainter — incense, or the memory of incense") and the room has empty wall sconces, but:
- No usable incense exists in the room
- No candles exist for the sconces
- The incense burner on the altar contains only spent ash

### The Solution

The incense and candles are **inside the hidden alcove**, sealed by the chain mechanism. This is a narrative-consistent answer: the original builders stored their ritual supplies in a protected, accessible-only-to-initiates compartment. The chain mechanism was their "key."

### Placement Map

```
    West Wall (expanded view)
    ┌─────────────────────────────────────────┐
    │                                         │
    │   [stone archway]     [hidden alcove]   │
    │   ┌──────────┐        ┌──────────┐      │
    │   │ iron gate │        │ incense  │      │
    │   │ (locked,  │        │ ×3 sticks│      │
    │   │  silver   │        │ candles  │      │
    │   │  padlock) │        │ ×2       │      │
    │   └──────────┘        └──────────┘      │
    │                       ↑                  │
    │                       stone panel        │
    │                       (slides open       │
    │                        when chain        │
    │                        is pulled)        │
    └─────────────────────────────────────────┘
```

### What Goes Where

| Item | Location | Purpose |
|------|----------|---------|
| Incense sticks ×3 | Stone alcove (hidden) | Fuel for incense burner → Puzzle 012 ritual |
| Altar candles ×2 | Stone alcove (hidden) | Light for sconces, offering for bowl, personal light |
| Old ash | Incense burner (on altar) | Atmospheric — signals past use, not functional fuel |
| Empty sconces ×2 | East and west walls | Receivers for altar candles |

### Candle Use Decision Tree

The player gets 2 altar candles. They can:

| Allocation | Consequence |
|------------|-------------|
| **1 sconce + 1 offering bowl** | Room lit + ritual complete. Optimal if player has lantern for personal light. |
| **2 sconces** | Room fully lit, but must sacrifice personal candle for offering. |
| **1 offering bowl + 1 personal** | Ritual complete + backup light. Sconces remain dark. |
| **1 sconce + 1 personal** | Partial room light + backup light. Must use personal candle for offering. |
| **2 personal** | Maximum light insurance. Must use personal candle for offering. |

This micro-decision is appropriate for ⭐⭐ difficulty. There's no wrong answer — all allocations lead to a solvable game state. But the player who HAS the lantern (Puzzle 010) has more flexibility, rewarding prior exploration.

---

## Design Rationale

### Why a Hidden Alcove?

**Narrative consistency:** The Deep Cellar was a ceremonial chamber built by a religious order. They stored their ritual supplies in a sealed compartment — protected from moisture, theft, and decay. This is historically accurate: medieval churches had "aumbries" (wall cupboards) for storing sacred vessels and supplies, often concealed behind panels. The chain mechanism is their version of a combination lock — only initiates knew to pull it.

**Material preservation:** The alcove explains WHY the incense and candles are still usable after centuries. The sealed stone compartment maintained the dry, cold conditions that preserved the beeswax and resin. The room's low moisture (0.3) and cold temperature (9°C) would keep beeswax stable indefinitely and preserve resin from degrading. This is Material Consistency (Principle 9) working as world-building.

**Gameplay function:** The chain provides a REASON to interact with the room's most prominent environmental object. Without this puzzle, the chain would either be a red herring (violating D-BUG022: no false affordances) or would need some other effect. The alcove gives the chain a satisfying, logical purpose.

### Why Gate Puzzle 012?

The altar ritual (Puzzle 012) is the room's most complex puzzle — a multi-step knowledge gate. By placing the incense behind the chain mechanism, we create a prerequisite that:

1. **Teaches environmental interaction** before requiring interpretive problem-solving
2. **Provides the player with tools** (incense, candles) before asking them to use those tools
3. **Creates progressive difficulty** — simple mechanical interaction (chain) → complex symbolic ritual (altar)
4. **Prevents accidental completion** — a player can't stumble into the ritual without first engaging with the room's architecture

This follows the Witness model (Frink §2.1 [11]): introduce one concept per puzzle, build on prior concepts in the next puzzle. The chain teaches "pull to reveal." The altar teaches "interpret text and perform symbolic actions."

### Why NOT Gate the Critical Path?

The critical path (UP → Hallway) remains completely ungated. Any player can walk to the stairway and ascend without ever pulling the chain. The chain puzzle only gates optional content (altar ritual → crypt). This follows Sideshow Bob's Puzzle 011 design: "The player has earned their escape. No gate-keeping."

The chain puzzle is pure enrichment — it rewards the curious player with resources and opens a deeper puzzle chain, but it never stands between the player and forward progress.

### Two Paths to the Silver Key

With this design, the silver key has two discovery paths:

| Path | Mechanism | Prerequisite | Difficulty |
|------|-----------|--------------|------------|
| **A: Ritual** | Pull chain → get incense → light incense → read scroll → perform ritual → key revealed behind altar | Chain + fire source + scroll interpretation | ⭐⭐⭐ (multi-step, knowledge gate) |
| **B: Brute Force** | Open sarcophagus with leverage tool → find key among bones | Crowbar (from Storage Cellar) | ⭐⭐ (tool requirement only) |

Path A is more narratively satisfying — the player follows the scroll's instructions and performs the ancient rite. Path B is more direct — the player forces open the sarcophagus and takes what they need. Both are valid. The game rewards both the scholar and the pragmatist.

---

## GOAP Analysis

### What GOAP Resolves
- "PULL chain" → single-step action, fully resolvable
- "TAKE incense" → standard take action (after alcove revealed)
- "TAKE candle" → standard take action
- "PUT candle IN sconce" → standard placement action

### What GOAP Cannot Resolve
- That pulling the chain reveals hidden content (discovery/exploration)
- That the alcove contents are needed for the altar ritual (knowledge gate)
- Where to allocate the two candles (strategic decision)

### GOAP Depth
- Pull chain: 1 step
- Take items: 1 step per item
- No tool-chain involved — this is pure discovery

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **FEEL (chain)** | "Heavy iron links. A large ring at the bottom — meant to be grasped." | Chain is pullable — the ring is an affordance |
| **LOOK (chain)** | "The chain disappears into a dark slot in the ceiling, connected to some mechanism above." | Connected to a mechanism — pulling it does something |
| **LISTEN (chain, idle)** | "A faint creaking from above — the mechanism." | Something mechanical is connected |
| **LISTEN (after pull)** | "Stone grinding against stone from the west wall." | Effect is at the west wall |
| **SMELL (after pull)** | "A sudden wave of frankincense and myrrh from the west wall." | Something fragrant was sealed — follow the smell |
| **FEEL (west wall, after pull)** | "An opening in the wall — a shallow recess with objects inside." | Alcove discovered by touch in darkness |
| **LOOK (alcove, if lit)** | "Dark sticks bound with twine, and two pale candles on a carved shelf." | Contents visible |
| **FEEL (incense sticks)** | "Stiff, waxy sticks. Resinous. They warm in your grip." | Incense — burnable material |
| **SMELL (incense sticks)** | "Frankincense and myrrh — concentrated, potent." | Confirms identity as ritual incense |

### Darkness-First Design

The entire chain puzzle is solvable without light. The sensory hints form a complete discovery path through FEEL, LISTEN, and SMELL:

1. FEEL → find chain → PULL
2. LISTEN → hear grinding from west wall
3. SMELL → follow incense fragrance to west wall
4. FEEL → find opening, discover contents
5. FEEL + SMELL → identify incense and candles

This is critical because the Deep Cellar has `light_level = 0`. A player who arrives without light (candle burned out, no lantern) is not stuck — they can still discover and complete this puzzle entirely by non-visual senses. The incense smell is the strongest sensory beacon in the room, and it only activates AFTER the chain is pulled — rewarding the player's exploration with a new sensory channel.

---

## Room Modifications Required (for Moe)

### Chain Connection to Alcove

The chain's pull must trigger the alcove reveal. Add to room definition:

```lua
on_state_change = {
    { object = "chain", state = "pulled", trigger = {
        { target = "stone-alcove", set = { hidden = false } },
    }},
},
```

### Room `on_feel` Update

The current room `on_feel` should mention the chain. Add to the tactile description:

> "...In the center of the chamber, something hangs from above — a heavy chain, iron links, ending in a large ring at about chest height."

### Room Description Update

The room description should hint at the west wall's sealed alcove — not reveal it, but allow a perceptive player to notice the seam:

> In the existing description, after "Iron sconces line the walls, unlit and cold," consider adding: "The west wall, where a stone archway frames an iron gate, has a subtle asymmetry — a faint rectangular outline in the stone, as if a panel were fitted into the wall beside the arch."

This gives a visual hint to lit-room players without spoiling the discovery. Per Frink's progressive hinting (§5.2 [29]): provide hints at multiple levels of engagement.

### New Instance in Room

Add the alcove and its contents to `deep-cellar.lua`:

```lua
-- In instances array, add:
{ id = "stone-alcove", type = "Stone Alcove", type_id = "{new-guid}",
    hidden = true,
    contents = {
        { id = "incense-stick-1", type_id = "{incense-guid}" },
        { id = "incense-stick-2", type_id = "{incense-guid}" },
        { id = "incense-stick-3", type_id = "{incense-guid}" },
        { id = "altar-candle-1",  type_id = "{candle-guid}" },
        { id = "altar-candle-2",  type_id = "{candle-guid}" },
    },
},
```

---

## Puzzle 012 Integration Note

With this design, Puzzle 012 (Altar Ritual) gains a new prerequisite: the player must have pulled the chain and obtained the ceremonial incense before they can light the incense burner for the ritual. The old ash in the burner is SPENT — insufficient as fuel. Only fresh incense sticks from the alcove can produce the "smoldering" state needed for the ritual.

This changes Puzzle 012's dependency chain:

```
Before (012 standalone):
  Fire source + incense residue → light burner → place flame in bowl → ritual complete

After (012 with chain prerequisite):
  Pull chain (017) → get incense sticks
  Fire source + incense stick → place in burner → light → burner smoldering
  Place lit candle in offering bowl → both conditions met → ritual complete
```

**Impact on Puzzle 012:**
- The `incense-burner` object should be updated: its `on_look` / `on_feel` should describe the ash as "spent" rather than implying relightable residue
- The burner needs a new state or container behavior: accepts `incense-stick` items, which can then be lit
- The ritual's Boolean-AND condition becomes: `burner.contains(lit_incense) AND bowl.contains(lit_candle)`

**NOTE FOR BOB:** Puzzle 012's doc should be updated to reflect this new prerequisite. The chain puzzle makes 012 slightly harder (adds one discovery step) but also more logical — the player doesn't magically reignite centuries-old ash; they use fresh incense they found.

---

## Related Puzzles

| Puzzle | Relationship |
|--------|-------------|
| **006 (Iron Door Unlock)** | Prerequisite — must enter Deep Cellar |
| **010 (Light Upgrade)** | Synergy — lantern frees candle allocation |
| **012 (Altar Ritual)** | Dependent — chain provides incense needed for ritual |
| **014 (Sarcophagus)** | Alternate path — provides silver key without ritual |
| **015 (Draft Extinguish)** | Synergy — altar candles provide light backup for stairway ascent |
| **001 (Light the Room)** | Callback — placing candles in sconces echoes the first puzzle |

---

## Object Summary Table

| Object | Template | Material | Size | Weight | Instances | Location |
|--------|----------|----------|------|--------|-----------|----------|
| `incense-stick` | small-item | resin | 1 | 0.1 | 3 | Stone alcove (hidden) |
| `altar-candle` | small-item | beeswax | 1 | 0.4 | 2 | Stone alcove (hidden) |
| `stone-alcove` | furniture | stone | 3 | — | 1 | West wall (hidden until chain pulled) |

**Total new objects:** 3 types, 6 instances (3 incense + 2 candles + 1 alcove)

---

*"The chain is hanging right there in the middle of the room. It has a ring on the end. It's obviously meant to be pulled. And yet, in every playtest of every text adventure ever made, at least 30% of players will walk past it without pulling it. That's not bad design — that's the difference between a player who explores and a player who speed-runs. Both are valid. But only one gets the incense." — Comic Book Guy*
