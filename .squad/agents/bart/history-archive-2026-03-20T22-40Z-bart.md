# Bart — History Archive (2026-03-18 to 2026-03-20T22:40Z)

## Agent Summary
**Role:** Architect — engine design, verb systems, FSM mechanics, mutation patterns, puzzle systems.
Bart designed and built the entire MMO engine from scratch: loader, registry, mutation, loop, verb system (31 verbs), FSM engine, GOAP backward-chaining planner, parser pipeline (Tier 1/2/3), composite/detachable object system, spatial relationships, terminal UI, multi-room engine, and SLEEP mechanics. He is the primary implementer of all engine code.

## Date Range
2026-03-18 to 2026-03-20T22:40Z

## Major Themes
- Engine foundation (loader, registry, mutation, loop)
- Verb system (31 verbs, 4 categories, tool resolution, skill gates)
- FSM architecture (inline state machines, timed events, cyclic states)
- Containment (4-layer validation, composite objects, detachable parts)
- Parser pipeline (Phase 1/2 embedding, Tier 1 exact match, Tier 2 Jaccard+Levenshtein, Tier 3 GOAP)
- Terminal UI (split-screen, ANSI, scrollback)
- Multi-room engine (shared registry, per-room FSM ticking)
- Spatial system (PUSH/PULL/MOVE, covering, hidden objects, trap door puzzle)

## Key Deliverables

### Engine Foundation (2026-03-18 to 2026-03-19)
- Built src/ tree: engine/, meta/, parser/, multiverse/, persistence/
- Implemented loader (sandboxed execution), registry (object storage), mutation (object rewriting via loadstring), loop (REPL)
- Containment constraint architecture (4-layer: identity, size, capacity, categories)
- Template system + weight/categories + multi-surface containment

### Verb System (2026-03-19)
- V2 verb system: 31 verbs across 4 categories (sensory, inventory, object interaction, meta)
- Sensory verbs (FEEL, SMELL, TASTE, LISTEN) all work in darkness
- Tool resolution: capabilities-based, supports virtual tools (blood)
- WRITE/CUT/PRICK/SEW/PICK LOCK verbs, dynamic mutation via string.format

### Parser Pipeline (2026-03-19)
- Phase 1: Extracts 54 verbs + 39 objects → 29,582 training pairs (1.6MB CSV)
- Phase 2: GTE-tiny (384-dim) embedding → 104.1MB raw, 32.5MB gzipped index
- Scripts: generate_parser_data.py, build_embedding_index.py
- Tier 2 runtime: Jaccard + prefix bonus scoring, threshold 0.40, Levenshtein typo correction

### SLEEP Verb (2026-03-19)
- Clock-advance mechanic, duration parsing, FSM ticking during sleep (~10 ticks/game hour)
- Dawn-crossing detection, candle-burnout detection, safety limits (10min–12hr)

### Wearable System (2026-03-19)
- WEAR/REMOVE verbs, slot/layer conflicts, vision blocking (sack-on-head)
- player.worn flat list, accessory layer coexistence, legacy fallback

### FSM Engine (2026-03-20)
- Table-driven FSM (~130 lines): load, transition, tick, get_transitions
- Inline FSM refactor: one file = one object = one FSM (Wayne directive)
- Objects migrated: match (3 states), nightstand (2), candle (4), poison bottle (3), vanity (4), curtains (2)
- New verbs: DRINK, POUR with FSM alias support
- Double-tick bug fix (tick_burnable skips FSM objects)

### Composite/Detachable Objects (2026-03-20)
- Parts table with factory pattern, detach/reattach system
- PULL/REMOVE/UNCORK verbs, two-handed carry (hands_required 0/1/2)
- Nightstand refactored (4-state FSM: closed/open × with/without drawer)
- Poison bottle cork detachable

### Spatial System (2026-03-20)
- move_spatial_object() helper, PUSH/MOVE/SHIFT/SLIDE/SHOVE/LIFT handlers
- Rug + trap door puzzle: push bed → pull rug → discover trap door → open → exit appears
- Blocking relationships, covering system, hidden object reveal

### Multi-Room Engine (2026-03-20)
- Direction verbs: N/S/E/W/U/D + aliases, go/enter/descend/ascend
- All rooms loaded at startup, shared registry, per-room contents
- Cellar room created (dark, iron door, barrel, torch bracket)
- BUG-027/028 fixes (state labels, key resolution)

### GOAP Tier 3 (2026-03-20)
- Backward-chaining prerequisite resolver (~220 lines)
- "light candle" auto-chains: open drawer → open matchbox → take match → strike match → light candle
- UNLOCK verb for exits (doors), key_id matching
- Pre-check mechanism (runs BEFORE verb handler), stop-on-failure

### Terminal UI (2026-03-20)
- Split-screen: status bar + scrollable output + input prompt
- Print interception via display module, scrollback via /up /down /bottom
- --no-ui flag for plain mode, pcall wrapper for cleanup

### Object Batch + Bugfix Pass-007 (2026-03-20T22:00Z)
- candle-holder.lua (composite, detachable candle)
- wall-clock.lua (24-state cyclic FSM)
- Enhanced candle.lua (extinguish/partial burn/timed_events)
- Enhanced match.lua (no-relight path, timed_events)
- BUG-031 FIXED (compound "and" + GOAP clean output)
- BUG-032 FIXED ("burn" as GOAP synonym for "light")

### Timed Events Engine + READ Verb + Wall Clock (2026-03-20T22:15Z)
- D-TIMER001: Two-phase tick, room pause/resume, sleep integration, cyclic states
- D-READ001: Skill grant protocol via READ verb
- D-CLOCK001: Wall clock misset puzzle support (SET/ADJUST verbs)

### Window & Wardrobe FSM Consolidation (2026-03-20T21:45Z)
- Merged window.lua + window-open.lua into single FSM
- Deleted window-open.lua, wardrobe-open.lua

## Bug Fixes Applied (32+ across 7 passes)
- Pass-001: Text wrapping, window state sync, prepositions, bare smell/listen sweep, match burn countdown, drink preposition
- Pass-002: Poison death (BUG-008), parser debug leaks (BUG-009), nightstand IDs (BUG-010), help intercepts write (BUG-011), take match priority (BUG-012), matchbox tactile (BUG-013), poison bottle keyword (BUG-014)
- Pass-003: Drawer reattach (BUG-017 CRITICAL), wardrobe IDs (BUG-015), put sack on head (BUG-016), kick→lick (BUG-018), FSM state labels (BUG-019), lowercase message (BUG-020), parser startup debug (BUG-021), play again (BUG-022)
- Batch 2: NLP noun extraction, compound command splitting, pronoun resolution, nightstand accessible, unicode em dash cleanup
- Batch 3: FSM verb aliasing, prepositional feel in/inside, check/inspect aliases
- Pass-007: BUG-031 (compound+GOAP), BUG-032 (burn synonym)

## Architecture Decisions Filed
D-14 through D-CLOCK001 (45+), including:
- D-14: True code mutation
- D-16: Lua for engine + meta-code
- D-17: Universe templates
- D-37 to D-41: Sensory verbs, tool resolution, blood as virtual tool
- D-OBJ001–D-OBJ006: Object patterns (timed_events, candle burn, match spent, wall clock, candle holder, terminal states)
- D-TIMER001, D-READ001, D-CLOCK001: Timer engine, READ skill grant, wall clock puzzle

## Cross-Agent Updates Received
- Comic Book Guy: Skills system design, FSM lifecycle design, command variation matrix, composite object design, spatial system design
- Brockman: Documentation sweep, verb-system.md published
- Frink: Wasmoon feasibility, CYOA research
- Nelson: Playtest reports (passes 001–007)

## User Directives Captured
1. No fallback past Tier 2 (parser misses fail visibly)
2. Trim index & play test empirically
3. Newspaper editions separate
4. Room layout and movable furniture (bed ON rug, rug COVERS trap door)
5. No special-case objects; clock as 24-state FSM
6. Wall clock supports misset time for puzzles
