### 2026-03-21T19:17Z: User directives — Player architecture refinements
**By:** Wayne Berry (via Copilot)

**Directive 1 — Health is derived, not stored:**
Health is NOT a standalone state. It's the SUM of injuries. A player's "health number" is computed from their active injuries. No separate health state — just a health number that reflects the aggregate of all injuries.

**Directive 2 — Injury-specific healing:**
Objects heal SPECIFIC injuries, not generic health. An antidote cures a specific poison (not all poisons). A different antidote cures a snake bite. A bandage stops bleeding but doesn't cure poison. The healing relationship is encoded on the healing object AND references the specific injury type it treats.

**Directive 3 — Injuries are the player's health state:**
The player's "health state" IS their collection of injuries. Players should be able to assess their injuries via a verb (like `injuries` or `check health`), just like `inventory` shows carried objects.

**Directive 4 — Inventory is first-party in player.lua:**
The objects a player is carrying should be stored in the player's `.lua` file as a nested array (nested because of containers — a bag can contain items). The engine mutates this array as the player picks up and drops objects. Inventory is a first-class engine construct — the engine interacts with the player.lua nested array, not a separate system.

**Directive 5 — Engine only knows player.lua:**
The engine should only know how to interact with the player.lua file. Inventory, injuries, health — it's all in player.lua. The engine reads and mutates this file. This is the single source of truth for player state.

**Why:** Wayne is establishing that the player.lua file is the canonical mutable state for the player, and that health/injuries/inventory are all nested data structures within it — not separate engine systems.
