# Portal Unification Plan

**Author:** Bart (Architecture Lead)
**Date:** 2025-07-28
**Status:** Implementation plan — decisions locked by Wayne
**Tracking:** D-PORTAL-ARCHITECTURE

---

## 1. Summary

Exits currently live as inline tables in room files with their own parallel mutation system (`becomes_exit`), keyword resolution (`exit_matches`), boolean state flags, and effect pipeline — duplicating ~322 lines of engine code across 8 files. We are replacing this with **portal objects**: first-class `.lua` files that use the standard object system (FSM, mutation, sensory, materials, templates). Room `exits` tables become thin directional references pointing to portal object IDs. Five architecture decisions are locked. Migration is phased: template + engine first, bedroom door proof-of-concept second, remaining rooms third, cleanup fourth.

---

## 2. Locked Decisions (D-PORTAL-ARCHITECTURE)

| # | Decision | Detail |
|---|----------|--------|
| **D1** | GO on Option B | Doors/windows/gates become first-class objects. Exit tables become thin routing references. |
| **D2** | Template name: `portal` | New template at `src/meta/templates/portal.lua`. Not "passage", not "door" — `portal` covers doors, windows, gates, trapdoors, tunnels, magical passages. |
| **D3** | Explicit `traversable` per FSM state | Each FSM state declares `traversable = true/false`. The engine reads this flag — no boolean `open`/`locked` checks on exits. |
| **D4** | Paired objects linked by `bidirectional_id` | A door between two rooms = two portal objects (one per room side), sharing a `bidirectional_id`. State changes sync via the engine. |
| **D5** | Migration starts with bedroom-hallway door | The bedroom's `exits.north` oak door is the first conversion — it's the most complex exit (barred, breakable, FSM states) and proves the pattern. |

---

## 3. Phase 1: Portal Template + Engine Support

**Goal:** Build the infrastructure so portal objects can exist and movement can resolve them.

### 3.1 Create `src/meta/templates/portal.lua`

Define the base shape for all traversable objects:

```lua
return {
    guid = "{new-guid}",
    id = "portal",
    name = "a passage",
    keywords = {},
    description = "A passage between rooms.",

    size = 5,
    weight = 100,
    portable = false,
    material = "wood",

    -- Portal-specific metadata (engine-executed per P8)
    portal = {
        target = nil,              -- destination room ID (required)
        bidirectional_id = nil,    -- shared ID linking paired portal objects
        direction_hint = nil,      -- "north", "south", etc. for disambiguation
    },

    -- Passage constraints
    max_carry_size = nil,          -- nil = no limit
    max_carry_weight = nil,

    -- FSM defaults
    initial_state = "open",
    _state = "open",
    states = {},
    transitions = {},

    -- Sensory defaults
    on_feel = "A passage.",
    on_smell = nil,
    on_listen = nil,

    -- Standard object fields
    container = false,
    capacity = 0,
    contents = {},
    categories = {"portal"},
    mutations = {},
}
```

### 3.2 Add `find_portal_by_keyword()` to `src/engine/verbs/helpers.lua`

A new helper that searches visible objects in the current room for portal-template objects matching a keyword. Uses the existing `matches_keyword()` — no new matching logic. This replaces `exit_matches()` for portal objects.

```lua
function M.find_portal_by_keyword(context, keyword)
    -- Search room instances for portal-template objects matching keyword
    -- Also match against portal.direction_hint for "go north" → portal resolution
    -- Return the portal object (or nil)
end
```

### 3.3 Update `src/engine/verbs/movement.lua`

Modify the movement flow to resolve portal objects:

1. Look up `room.exits[direction]`
2. **New path:** If exit has a `portal` field (thin reference), resolve the portal object from the registry by ID
3. **New path:** If no exit found, call `find_portal_by_keyword()` to search by keyword
4. Check `portal.states[portal._state].traversable` — if false, print state-appropriate blocked message
5. Process `on_traverse` effects from the portal object
6. Move player to `portal.portal.target`
7. **Legacy path:** If exit has no `portal` field, fall through to existing exit-table handling (backward compatibility during migration)

### 3.4 Add bidirectional sync to `src/engine/fsm/init.lua`

When a portal object transitions state, the engine looks up its `bidirectional_id`, finds the paired portal in the other room, and applies the same state change. This keeps both sides consistent.

### Acceptance Criteria — Phase 1

- [ ] `portal.lua` template exists and loads without error
- [ ] `find_portal_by_keyword()` resolves portal objects by keyword and direction hint
- [ ] Movement resolves thin exit references → portal objects → traversable check
- [ ] Bidirectional sync: changing state on one side changes the paired portal
- [ ] Existing exit-table movement still works (backward compatibility)
- [ ] All existing tests pass (zero regressions)

---

## 4. Phase 2: Bedroom Door Proof of Concept

**Goal:** Convert the bedroom-hallway oak door end-to-end. Prove the pattern works with the most complex exit in Level 1.

### 4.1 Create portal object files

**Bedroom side** — `src/meta/objects/bedroom-hallway-door-north.lua`:
- Template: `portal`
- Material: `oak`
- `portal.target`: `"hallway"`
- `portal.bidirectional_id`: `"bedroom-hallway-passage"`
- `portal.direction_hint`: `"north"`
- FSM states: `barred` → `unbarred` → `open` → `broken` (all with `traversable` flag)
- Full sensory text per state (`on_feel`, `on_examine`, `on_smell`, `on_listen`, `on_knock`, `on_push`)
- Transitions: unbar, open, close, break (with `requires_capability`, strength checks)
- Mutations: `break` → `becomes` broken variant (D-14 code mutation)
- `on_traverse`: wind effect (extinguishes candle)

**Hallway side** — `src/meta/objects/bedroom-hallway-door-south.lua`:
- Same `bidirectional_id`: `"bedroom-hallway-passage"`
- `portal.target`: `"start-room"`
- `portal.direction_hint`: `"south"`
- Sensory text from hallway perspective
- Same FSM states (synced via bidirectional mechanism)

### 4.2 Update room files to thin references

**`src/meta/world/start-room.lua`** — Replace `exits.north` inline table with:
```lua
north = { portal = "bedroom-hallway-door-north" },
```
Add the portal object to the room's `instances` list.

**`src/meta/world/hallway.lua`** — Replace `exits.south` inline table with:
```lua
south = { portal = "bedroom-hallway-door-south" },
```
Add the portal object to the room's `instances` list.

### 4.3 Retire `bedroom-door.lua`

The existing `src/meta/objects/bedroom-door.lua` (furniture-template door with `linked_exit`/`linked_passage_id`) is replaced by the two portal objects. Remove it once the portal objects are verified.

### 4.4 Verify all interactions

Test every verb that touches the bedroom door:
- `go north` / `north` / `n` — blocked when barred/unbarred, succeeds when open/broken
- `open door` — FSM transition: unbarred → open
- `close door` — FSM transition: open → unbarred
- `unbar door` — FSM transition: barred → unbarred
- `break door` — FSM transition + mutation; requires blunt force capability
- `look door` / `examine door` — state-appropriate description
- `feel door` — tactile text (works in darkness)
- `listen door` / `smell door` / `knock door` — sensory responses
- `go south` (from hallway) — bidirectional sync verification

### Acceptance Criteria — Phase 2

- [ ] Bedroom-hallway door works as two paired portal objects
- [ ] All verb interactions produce correct text
- [ ] Bidirectional sync: unbar from bedroom, door is unbarred from hallway
- [ ] Wind effect on traverse still extinguishes candle
- [ ] `bedroom-door.lua` (old furniture object) removed
- [ ] Existing exit-table exits (window, trapdoor) still work via legacy path
- [ ] All existing tests pass

---

## 5. Phase 3: Migrate Remaining Exits

**Goal:** Convert all 7 rooms' exit definitions to portal objects. Remove exit-specific engine code.

### 5.1 Exits to convert

| Room | Direction | Exit Type | Portal Object(s) |
|------|-----------|-----------|-------------------|
| start-room | north | oak door | ✅ Done in Phase 2 |
| start-room | window | leaded window | bedroom-courtyard-window (+ courtyard side) |
| start-room | down | trap door | bedroom-cellar-trapdoor (+ cellar side) |
| hallway | south | oak door | ✅ Done in Phase 2 |
| hallway | east | locked iron door | hallway-east-door (+ other side) |
| hallway | down | stairway | hallway-cellar-stairs (+ cellar side) |
| hallway | north | (any exits north) | TBD per room definition |
| cellar | up | stairway to hallway | cellar-hallway-stairs (paired with hallway side) |
| cellar | down | passage to deep cellar | cellar-deep-cellar-passage (+ deep cellar side) |
| deep-cellar | up | passage to cellar | (paired with cellar side) |
| storage-cellar | * | all exits | TBD per room definition |
| courtyard | * | all exits | TBD per room definition |
| crypt | * | all exits | TBD per room definition |

Each exit produces paired portal objects. Simple open passages (stairways, corridors) use a minimal portal with a single `open` state where `traversable = true`.

### 5.2 Remove exit-specific engine code

Once all exits are converted, remove:

| File | What to Remove |
|------|----------------|
| `helpers.lua` | `exit_matches()` function (~12 lines) |
| `containers.lua` | Exit fallback paths for open/close/lock/unlock via `becomes_exit` (~60 lines) |
| `destruction.lua` | Exit break handler, `becomes_exit` merge, exit-object sync (~40 lines) |
| `sensory.lua` | Exit-targeted look/examine/feel/listen paths (~30 lines) |
| `movement.lua` | Legacy exit-table resolution path (~50 lines, replaced by portal path in Phase 1) |
| `equipment.lua` | Exit edge-case references (~5 lines) |
| `acquisition.lua` | Exit edge-case references (~5 lines) |

### 5.3 Remove exit mutation system

- Remove all `becomes_exit` handling from the engine
- Remove `reveals_exit` pattern (trap door now uses FSM: `hidden` → `closed` → `open`, with `hidden` state having no `room_presence`)
- Remove `passage_id`, `linked_exit`, `linked_passage_id` fields from all object files

### 5.4 Simplify `traverse_effects.lua`

Effects now live on the portal object's `on_traverse` field. Simplify `traverse_effects.lua` to read from the portal object directly instead of from exit tables. The effect handlers themselves (e.g., `wind_effect`) remain unchanged.

### Acceptance Criteria — Phase 3

- [ ] All room exits use thin portal references
- [ ] All exit-specific engine code paths removed
- [ ] `becomes_exit` mutation system removed
- [ ] `exit_matches()` removed (replaced by standard `matches_keyword` on portal objects)
- [ ] Zero inline exit state (no `open`, `locked`, `hidden`, `broken` flags on exit tables)
- [ ] All existing tests updated and passing

---

## 6. Phase 4: Cleanup + Validation

**Goal:** Remove dead code, update tests, update docs, add meta-lint rules.

### 6.1 Dead field cleanup

Remove from all files:
- `linked_exit`
- `linked_passage_id`
- `passage_id`
- `reveals_exit`
- `becomes_exit` (in mutation tables)
- `key_id` on exit tables (key requirements move to FSM transition `requires_tool`)

### 6.2 Test updates

- Update `test/rooms/test-bedroom-door.lua` — verify portal-based door interactions
- Update `test/verbs/test-door-resolution.lua` — verify portal keyword resolution
- Update `test/objects/test-bedroom-door-object.lua` — verify portal object structure
- Add new tests for bidirectional sync
- Add new tests for `traversable` flag blocking/allowing movement
- Add regression tests for all converted exits
- Run full suite: `lua test/run-tests.lua`

### 6.3 Documentation updates

**Convert analysis files to living docs.** The two analysis files are point-in-time snapshots. Docs must reflect the CURRENT state of the system, not when we analyzed it. Rename and rewrite:

| Analysis file (delete after conversion) | Living doc (create) | Owner |
|-----------------------------------------|---------------------|-------|
| `resources/research/architecture/portal-engine-analysis.md` | `docs/architecture/engine/portal-system.md` | Brockman (from Bart's notes) |
| `docs/design/portal-design-analysis.md` | `docs/design/portal-interactions.md` | Brockman (from CBG's notes) |

The living docs describe HOW the portal system works NOW — not the analysis that led to the decision. The analysis files are deleted once the docs are written (research served its purpose).

**Other doc updates:**
- Update `docs/objects/bedroom-door.md` and `docs/objects/trap-door.md`
- Update `docs/architecture/objects/deep-nesting-syntax.md` (exit encoding changes)
- Update `docs/design/design-directives.md` (add D-PORTAL-ARCHITECTURE reference)
- Update `docs/architecture/engine/effects-pipeline.md` (traverse effects now on portal objects)
- Add `docs/architecture/objects/portal-pattern.md` — the canonical portal object reference

### 6.4 Meta-lint rules (EXIT-* category)

Add portal validation rules to the meta-lint system:

| Rule | Severity | Description |
|------|----------|-------------|
| EXIT-01 | 🔴 Error | Portal object must have `portal.target` defined |
| EXIT-02 | 🔴 Error | Portal object must have `traversable` on every FSM state |
| EXIT-03 | 🔴 Error | Portal `bidirectional_id` must have exactly one matching partner |
| EXIT-04 | 🟡 Warning | Portal `portal.direction_hint` should match the room exit direction key |
| EXIT-05 | 🟡 Warning | Room thin exit reference should point to an object with `template = "portal"` |
| EXIT-06 | 🔴 Error | No inline exit state allowed (`open`, `locked`, `hidden` on exit table = error) |
| EXIT-07 | 🟡 Warning | Portal object should have `on_feel` (P6 darkness requirement) |

### Acceptance Criteria — Phase 4

- [ ] Zero dead exit fields in codebase
- [ ] All tests pass
- [ ] Documentation updated
- [ ] EXIT-01 through EXIT-07 meta-lint rules implemented
- [ ] Full `lua test/run-tests.lua` green
- [ ] `.\test\run-before-deploy.ps1` passes

---

## 7. Issue Tracker — One Issue Per Portal (TDD)

Each portal has its own GitHub issue. All follow TDD: tests written FIRST, then implementation.

| # | Portal | Rooms | Type | Phase |
|---|--------|-------|------|-------|
| #198 | Bedroom-Hallway Door | start-room ↔ hallway | door (4-state FSM) | **Phase 2** (proof of concept) |
| #199 | Bedroom-Courtyard Window | start-room ↔ courtyard | window | Phase 3 |
| #200 | Bedroom-Cellar Trapdoor | start-room ↔ cellar | trap_door (hidden→revealed→open) | Phase 3 |
| #201 | Cellar-Storage Door | cellar ↔ storage-cellar | door (iron-bound) | Phase 3 |
| #202 | Storage-Deep Cellar Door | storage ↔ deep-cellar | door (locked) | Phase 3 |
| #203 | Deep Cellar-Hallway Stairway | deep-cellar ↔ hallway | stairway (wind effect) | Phase 3 |
| #204 | Deep Cellar-Crypt Archway | deep-cellar ↔ crypt | archway (iron gate) | Phase 3 |
| #205 | Hallway-Level2 Staircase | hallway → level-2 | stairway (boundary) | Phase 3 |
| #206 | Hallway-West Door | hallway → manor-west | door (boundary, locked) | Phase 3 |
| #207 | Hallway-East Door | hallway → manor-east | door (boundary, locked) | Phase 3 |
| #208 | Courtyard-Kitchen Door | courtyard → manor-kitchen | door (boundary, breakable) | Phase 3 |

**Execution order:** #198 first (Phase 2 proof of concept). Remaining (#199-#208) in Phase 3, parallelizable per room.

---

## 8. Who Does What

| Agent | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|-------|---------|---------|---------|---------|
| **Bart** | `portal.lua` template, `find_portal_by_keyword()`, movement.lua portal path, bidirectional sync | Review portal object structure | Remove exit-specific engine paths, simplify traverse_effects.lua | Dead field audit, architecture docs |
| **Flanders** | — | Create bedroom-hallway-door-north.lua + south.lua portal objects | Create all remaining portal object files | — |
| **Moe** | — | Update start-room.lua + hallway.lua exits to thin references | Update all 7 room files to thin exit references | — |
| **Smithers** | — | — | Remove exit fallback paths from containers.lua, destruction.lua, sensory.lua verb handlers | — |
| **Nelson** | — | Verify bedroom door interactions, write portal test cases | Update all exit-related tests | Full regression suite, deploy gate |
| **Lisa** | — | — | — | EXIT-01 through EXIT-07 meta-lint rules |
| **Brockman** | — | — | — | Documentation updates |

---

## 8. Dependencies

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4
```

- **Phase 2 requires Phase 1:** Portal template and engine support must exist before creating portal objects.
- **Phase 3 requires Phase 2:** Bedroom door proof-of-concept must be verified before bulk migration.
- **Phase 3 internal ordering:** Remove exit-specific engine code AFTER all exits are converted (not before — legacy path must work during migration).
- **Phase 4 requires Phase 3:** Cleanup and lint rules only make sense when all exits are portals.
- **No cross-phase parallelism:** Each phase is a gate. Do not start Phase N+1 until Phase N acceptance criteria are met.
- **Within Phase 3:** Flanders (portal objects) and Moe (room files) can work in parallel per room, but Smithers (engine cleanup) waits until all rooms are converted.

---

## 9. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Bidirectional sync bugs** | State desync between paired portals (door open on one side, closed on other) | Medium | Unit test every sync scenario. FSM engine handles sync atomically — no partial updates. |
| **Keyword collision** | "door" matches multiple portal objects in same room | Medium | Portal objects use specific keywords ("oak door", "iron door"). `find_portal_by_keyword` disambiguates via `direction_hint`. |
| **Backward compatibility during migration** | Mixed rooms (some exits thin, some inline) break movement | Low | Legacy exit-table path stays in movement.lua until Phase 3 complete. Both paths coexist. |
| **Traverse effects regression** | Wind/candle extinguish breaks when effects move to portal object | Medium | Dedicated traverse effect tests before and after migration. |
| **Test coverage gaps** | Untested exit paths break silently | Medium | Nelson audits all exit-related tests in Phase 2. No Phase 3 without test coverage report. |
| **Portal object bloat** | Simple open stairways feel over-engineered as full objects | Low | Minimal portal objects (single `open` state, 10-line files) are fine. Template inheritance keeps them small. |

---

## 10. Reference

| Document | Location | Purpose |
|----------|----------|---------|
| Engine architecture analysis | `resources/research/architecture/portal-engine-analysis.md` | Bart's analysis of current exit system, Option A vs B tradeoffs, code impact (→ becomes `docs/architecture/engine/portal-system.md` in Phase 4) |
| Game design analysis | `docs/design/portal-design-analysis.md` | CBG's genre precedent, scenario comparison, designer ergonomics (→ becomes `docs/design/portal-interactions.md` in Phase 4) |
| Bart's decision proposal | `.squad/decisions/inbox/bart-door-architecture.md` | Architecture recommendation with principle alignment scores |
| CBG's decision proposal | `.squad/decisions/inbox/cbg-door-design.md` | Design recommendation with genre analysis |
| Core principles | `docs/architecture/objects/core-principles.md` | The 9 inviolable object system principles |
| Deep nesting syntax | `docs/architecture/objects/deep-nesting-syntax.md` | Room file topology encoding (will need updates) |
| Meta-lint rules | `docs/meta-lint/rules.md` | Existing rule catalog (EXIT-* rules to be added) |
