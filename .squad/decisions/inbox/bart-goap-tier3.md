# Decision: Tier 3 Goal-Oriented Parser Implementation

**Author:** Bart (Architect)
**Date:** 2026-07-18
**Status:** Implemented
**Affects:** Parser pipeline, game loop, object metadata, verb dispatch

---

## Decision

Implemented Tier 3 backward-chaining prerequisite resolver as a **pre-check** mechanism in the game loop, sitting between input parsing and Tier 1 verb dispatch. The planner checks if a verb+object has unmet tool requirements and, if so, builds and executes a chain of preparatory steps through existing Tier 1 handlers.

## Key Design Choices

### 1. Pre-check vs Post-failure

The planner runs BEFORE the verb handler, not after a failure signal. Rationale: current verb handlers print failure messages and return void — retrofitting return codes to 40+ handlers was impractical. The pre-check approach reads FSM transition metadata (`requires_tool`) to detect unmet prerequisites without executing the handler.

### 2. In-place container manipulation

The planner opens containers in place (on surfaces/in the room) rather than picking them up first. This avoids hand-capacity conflicts during plan execution. The player's hands remain free for the final action.

### 3. Nested containment search (3 levels)

The planner searches: player hands → room contents → container contents → surface contents → items inside containers on surfaces. This handles the nightstand drawer → matchbox → match chain without special-casing.

### 4. Narrated execution, no confirmation

Plan execution prints "You'll need to prepare first..." then each step's natural output. No player confirmation prompt. The player learns the chain and can do it manually next time.

### 5. UNLOCK as exit-level verb

The UNLOCK handler operates on exits (doors), not objects. This matches the existing OPEN handler pattern for exits. The `key_id` field on exits specifies which key works. Future: extend to locked containers.

## Files Changed

- **Created:** `src/engine/parser/goal_planner.lua` (~220 lines)
- **Modified:** `src/engine/loop/init.lua` (planner integration, prepositional parsing, context tracking)
- **Modified:** `src/engine/verbs/init.lua` (UNLOCK handler, exit examine/feel, help text)
- **Modified:** `src/meta/objects/candle.lua` (prerequisites table)
- **Modified:** `src/meta/world/cellar.lua` (iron door: key_id, state descriptions, open mutation, on_feel)

## Risks Addressed

- **Infinite loops:** MAX_DEPTH=5 prevents runaway planning
- **Wrong inferences:** Planner only fires when `requires_tool` is explicitly declared on FSM transitions
- **Hand capacity:** In-place container opening eliminates mid-plan "hands full" failures
- **Partial execution:** Stop-on-failure preserves consistent world state; player keeps partial progress

## Future Work

- Extend planner to handle `requires_property` prerequisites (not just `requires_tool`)
- Add exit-level prerequisites (auto-unlock, auto-open before movement)
- Use `known_objects` context tracking to limit planning to objects the player has discovered
- Support multiple tool sources with priority ordering (prefer already-available tools)
