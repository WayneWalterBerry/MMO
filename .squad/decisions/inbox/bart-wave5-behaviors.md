# D-WAVE5-BEHAVIORS: Pack Tactics + Territorial + Ambush Engine Modules

**Author:** Bart (Architecture Lead) | **Date:** 2026-08-17 | **Status:** ✅ Implemented (WAVE-5)
**Affects:** Flanders (territory-marker.lua), Nelson (tests), Moe (room topology for BFS)

## Decisions

### D-PACK-ALPHA-HEALTH: Alpha Selection Uses Highest Health (Q4 Override)
The plan spec said `alpha_selection = "highest_aggression"` but Q4 resolution overrides to **highest current health**. Ties broken by max_health. This is simpler and more gameplay-intuitive — the healthiest wolf leads.

### D-TERRITORY-DUAL-FORMAT: Territory Marker Dual-Format Bridge
Flanders' territory-marker.lua stores `owner`, `radius` at the top level. Engine tests expect `territory.owner`, `territory.radius` subtable. Engine (territorial.lua) reads BOTH via `marker_owner()` / `marker_radius()` helpers. territory-marker.lua updated to include `territory = { owner, radius, timestamp }` subtable alongside top-level fields. **Flanders:** keep both formats in sync when editing territory-marker.lua.

### D-TERRITORY-MARKER-CONTRACT: Engine Contract for Territory Markers
Any object with `id == "territory-marker"` OR a `territory` subtable is treated as a territory marker. Ownership resolved via: `marker.territory.owner` → `marker.owner` → `marker.creator` (first non-nil wins). Radius defaults to 2 if not specified.

### D-PACK-STAGGER-FLAG: Pack Attack Stagger Mechanism
Non-alpha wolves in a pack use a `_pack_waited` flag to skip one attack turn. Flag alternates each tick — wolves idle for one turn then attack on the next. This is the simplified Phase 4 approach; full coordinated zone-targeting deferred to Phase 5.

### D-AMBUSH-GENERIC: Generic Ambush Behavior Pattern
Any creature can declare `behavior.ambush = { condition = fn, narration = "..." }`. Creature skips action selection until condition returns true. `_ambush_sprung` flag prevents re-hiding. Spider's existing `behavior.web_ambush` also supported as a separate check.

### D-RETREAT-THRESHOLD: Defensive Retreat at 20% Health
`pack_tactics.should_retreat()` triggers when `health / max_health < 0.20`. This runs in creature_tick BEFORE action selection — wounded creatures flee immediately rather than attacking. Separate from morale.check() which uses `flee_threshold` from combat.behavior.

## Affected Agents
- **Flanders** — territory-marker.lua now has `territory` subtable; keep in sync with top-level fields
- **Nelson** — test-pack-tactics.lua (4 tests), test-territorial.lua (5 tests) all pass
- **Moe** — BFS radius=2 covers most of Level 1's 7 rooms; verify room topology supports intended territory boundaries
- **Comic Book Guy** — Pack tactics and territorial behavior are simplified Phase 4 versions; full system in Phase 5
