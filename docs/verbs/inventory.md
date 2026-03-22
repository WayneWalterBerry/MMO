# Inventory

> Check your carrying status, health, injuries, time, and game information.

## Synonyms
- `inventory` — Check what you're carrying
- `i` — Shorthand for inventory
- `health` — Check health and injuries (alias)
- `injuries` — List injuries (alias)
- `time` — Check game time (alias)
- `help` — Show command help (alias)
- `quit` — Exit the game (meta command)

## Sensory Mode (Inventory/Health/Injuries)
- **Works in darkness?** ✅ Yes — you know what you're carrying
- **Light requirement:** None

## Syntax
- `inventory` — Check what you're carrying and wearing
- `i` — Shorthand for inventory
- `health` — Check health status and injuries
- `injuries` — List active injuries
- `injury` — List injuries (alias)
- `wounds` — List wounds (alias)
- `time` — Check game time of day
- `help` — Show verb command list
- `quit` — Exit the game

## Behavior

### Inventory
- **Carried items:** Lists hands and bag contents
- **Worn items:** Lists equipped armor/clothing
- **Format:** Organized by location (hands, inventory, worn)

### Health/Injuries
- **Active injuries:** Lists each injury with location and severity
- **Health calculation:** Shows current health vs. max
- **Treatment status:** Shows which injuries have bandages applied

### Time
- **Current time:** Shows hour and time of day
- **Day/night:** Indicates if daylight or night

### Help
- **Verb list:** Displays organized help with all commands
- **Categories:** Organized by action type (Movement, Observation, etc.)

### Quit
- **Game exit:** Exits the game cleanly

## Design Notes
- **Status verbs:** These are meta-commands for checking state, not interacting with world
- **No arguments:** All take no parameters
- **Always accessible:** Work in darkness, no requirements
- **Help categorization:** Help command uses same categories as verb system

## Implementation
- **File:** `src/engine/verbs/init.lua` → Multiple handlers
- **Handlers:**
  - `handlers["inventory"]`, `handlers["i"]`
  - `handlers["health"]`, `handlers["injuries"]`, `handlers["injury"]`, `handlers["wounds"]`
  - `handlers["time"]`
  - `handlers["help"]`
  - `handlers["quit"]`
- **Ownership:** Smithers (UI Engineer) — presentation and formatting
