# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context

**Agent Role:** Architect responsible for engine design, verb systems, mutation mechanics, and tool resolution patterns.

**Work Summary (2026-03-18 to 2026-03-19):**
- Designed and built src/ tree structure (engine/, meta/, parser/, multiverse/, persistence/)
- Implemented four foundational engine modules: loader (sandboxed code execution), registry (object storage), mutation (object rewriting), loop (REPL)
- Established containment constraint architecture (4-layer validator: identity, size, capacity, categories)
- Designed template system + weight/categories + multi-surface containment for complex objects
- Implemented V2 verb system: sensory verbs (FEEL, SMELL, TASTE, LISTEN) all work in darkness
- Designed tool resolution pattern: verb-layer concern, supports virtual tools (blood), capability-based resolution
- Moved game start time from 6 AM → 2 AM for true darkness mechanic

**Architecture Decisions Established:**
- D-14: True code mutation (objects rewritten, not flagged)
- D-16: Lua for both engine and meta-code (loadstring enables self-modification)
- D-17: Universe templates (build-time LLM + procedural variation)
- D-37 to D-41: Sensory verb convention, tool resolution, blood as virtual tool, CUT vs PRICK capability split

**Latest Spawns (2026-03-19):**
1. Sensory verbs + start time fix (6 AM → 2 AM, FEEL/SMELL/TASTE/LISTEN implemented)
2. V2 tool pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK verbs, tool resolution helpers, dynamic mutation via string.format)

**Key Patterns Established:**
- `engine/mutation/` is ONLY code that hot-swaps objects via loadstring()
- Mutation rules separate from object definitions (composable, clean)
- Registry uses instance pattern (not singleton) — enables simultaneous multiverse registries
- Tool resolution uses capabilities (not tool IDs) — supports complex interactions
- Blood is a virtual tool: generated on-demand when `player.state.bloody == true`, not an inventory item

## Recent Updates

### Session: Parser Pipeline Completion (2026-03-19T18:12:24Z)
**Status:** ✅ COMPLETE  
**Outcome:** End-to-end parser pipeline (Phase 1 & 2) completed

**Phase 1 Results:**
- Extracts 54 verbs (31 primary, 23 aliases) from `src/engine/verbs/init.lua`
- Extracts 39 objects from `src/meta/objects/*.lua`
- Extracts 1 room with exits from `src/meta/world/start-room.lua`
- Generates 29,582 unique training pairs (1.6MB CSV)

**Phase 2 Results:**
- Embedding: GTE-tiny (384-dim, TaylorAI repo)
- Index size: 104.1MB raw, 32.5MB gzipped
- Model reference fixed (TaylorAI/gte-tiny, Issue #401)
- Output: `src/assets/parser/index.json` + `index.json.gz`

**Scripts Created:**
- `scripts/generate_parser_data.py` — Phase 1 training data generation
- `scripts/build_embedding_index.py` — Phase 2 GTE-tiny indexer
- `scripts/requirements.txt` — Python dependencies

**Decision filed:** `.squad/decisions.md` - Parser pipeline completion

**Next:** Play testing with current index; expand if empirical testing reveals gaps

---

## Cross-Agent Update: Player Skills System Design (2026-03-19T16-23-38Z)

**From:** Comic Book Guy (Game Designer)  
**Impact:** Verb system architecture, gameplay progression  

Comic Book Guy completed the player skills system design. Key implications for your work:

1. **Double Dispatch Gating:** Verb handlers will need to check TWO gates in sequence:
   - Skill gate: `if not player.skills[required_skill] then return "[BLOCKED]" end`
   - Tool gate: (your existing tool resolution pattern — no changes needed)

2. **Skill Discovery Multi-Path:** Your verbs don't change, but designers will add:
   - Skill manuals (readable objects triggering skill unlock)
   - Practice triggers (e.g., pricking self 3+ times unlocks blood-drawing skill)
   - Future: NPC teaching, puzzle-solve triggers

3. **Consumable Failures:** Skills can fail; failed attempts have consequences:
   - Failed lock pick → bent-pin.lua created (your mutation pattern, no changes)
   - Failed sewing → tangled-mess.lua created
   - You already support dynamic mutation; no new engine work

4. **Blood Writing System:** Your blood-as-virtual-tool design aligns perfectly:
   - PRICK SELF WITH pin → blood created
   - WRITE "text" ON paper WITH blood → paper-with-writing.lua (player text embedded)
   - Blood persists ~5 min, limited resource

5. **Integration Point:** Verb handlers (your domain) will be the dispatch layer for skill gating. No new module needed — skill check goes before tool check in each verb.

**Decision filed:** `.squad/decisions.md` - "Decision Memo: Player Skills System Architecture"

**Next steps for you:** When implementing new verbs, add skill gate check pattern at top of handler. Example pattern to establish:
```lua
-- Check skill gate first
if verb_requires_skill and not player.skills[verb_required_skill] then
  return string.format("[BLOCKED] %s", verb_blocked_reason)
end

-- Then check tool gate (your existing pattern)
local tool = find_tool_in_inventory(ctx, required_capability)
if not tool then
  return "[BLOCKED] You need the right tool for that."
end

-- Then proceed with action
```

---

## Cross-Agent Update: Documentation Sweep Complete (2026-03-19T16-23-38Z)

**From:** Brockman (Documentation)  
**Impact:** Documentation accuracy, team reference  

Brockman completed post-integration documentation sweep:
- README.md updated with current architecture status
- `docs/verb-system.md` created — 31 verbs documented
- `docs/src-structure.md` updated with accurate file paths
- All cross-references verified against actual code

The verb-system.md doc now lists all your implemented verbs. Helpful for designers onboarding and game design reference.

**Note:** Your feel verb container enumeration (feel-around fix) is now documented with full rationale in verb-system.md.

---

## Cross-Agent Update: Wasmoon Feasibility Confirmed (2026-03-19T16-28-39Z)

**From:** Frink (Technical Researcher)  
**Impact:** PWA architecture, `main_browser.lua` entry point  

Frink completed PWA + Wasmoon prototype research. Key implications for your engine:

1. **Parallel Entry Point:** Create `main_browser.lua` as a browser-specific variant. Don't modify existing `main.lua` — keeps CLI and browser deployments independent.

2. **Three Browser Adaptations Needed:**
   - `io.popen` for directory listing → replaced by build-time manifest
   - Blocking REPL loop → replaced by event-driven `process_command()` function
   - `print`/`io.write` → overridden to write to DOM (handled by wrapper)

3. **Zero Engine Changes Required:** Engine is pure Lua with 6 self-contained `require` calls. ~90% of your code runs unmodified in Wasmoon.

4. **Performance:** Per-command latency <5ms (same as CLI). Total PWA size ~168KB gzipped.

5. **Timeline:** 5–7hr prototype (Frink's estimate). If approved, Frink will handle browser integration; you don't need to change anything pre-prototype.

**Recommendation:** When Frink starts prototype, coordinate around `main_browser.lua` interface. Current expectation: expose a `process_command(input_string)` function that returns output string (vs. blocking REPL).

**Decision:** D-43 filed: PWA + Wasmoon Prototype Feasibility

---

## Cross-Agent Update: Command Variation Matrix Ready (2026-03-22T10-28-59Z)

**From:** Comic Book Guy (Game Designer)  
**Impact:** Parser training data, embedding model accuracy  

Comic Book Guy completed the command variation matrix — all ~400 natural language variations players might type for the 54 verbs (31 canonical + 23 aliases).

**Critical Finding:** The matrix covers 54 verbs, not just the 31 canonical handlers. This includes all aliases as real player input paths. Your scripts extract all 54 verbs correctly.

**How This Feeds Your Pipeline:**

1. **Your Phase 1 script** extracts 54 verbs from `src/engine/verbs/init.lua` (31 primary + 23 aliases) ✅
2. **Comic Book Guy's matrix** documents ~400 natural language variations for those 54 verbs
3. **Your Phase 1 pipeline** uses your 54-verb extraction to generate 29,582 training pairs
4. **Comic Book Guy's matrix** becomes the ground-truth validation set for QA testing

**The matrix is structured by:**
- **Category:** Navigation, Inventory, Interaction, Movement, Meta
- **Variations per verb:** 10-20 natural phrasings
- **Context variations:** darkness-aware (FEEL/SMELL), tool-present/absent, container states, edge cases

**Key Detail:** Pronoun resolution is set to "last-examined object" — this is simple and testable. No full discourse tracking needed.

**Next Step for You:** When Phase 3 runtime integration happens, the embedding matcher will be validated against this matrix. Your job: ensure the index can look up these ~400 variations reliably.

**Decision Filed:** `.squad/decisions.md` - "Command Variation Matrix for Embedding Parser"

---

## Directives Captured for Bart

### Directive 1: No Fallback Past Tier 2 (2026-03-19T17:22:26Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Impact:** Parser error handling, testability

When the embedding parser encounters a miss, fail visibly. Do not fall back to lower-tier heuristics. Misses must surface clearly for analysis and iteration, enabling empirical QA of parser quality.

**Implication for Your Work:** Your Phase 2 embedding index is Tier 2. When players query an unknown verb/object combination, the matcher either returns a high-confidence result or admits defeat. No fuzzy fallback.

### Directive 2: Trim Index & Play Test Empirically (2026-03-19T18:10:37Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Impact:** Index size, browser deployment, iteration strategy

The 32.5MB gzipped index is too large for browser assets. Trim it down, then play test empirically. If parser quality drops, that means too much was trimmed — iterate from there. Prefer data-driven decisions over theoretical coverage.

**Implication for Your Work:** Ship the current index as-is (already meets size constraint after gzip). Validate parser quality through play testing. Only expand if empirical testing reveals gaps.

---

### Play Test Bug Fixes — Batch 3 (2026-03-23)

**FSM verb aliasing for "light match":**
- The `light` verb handler only checked mutation path (`find_mutation`). FSM objects like the match use transitions with verb="strike", not mutations. Fix: after mutation check fails, query `fsm_mod.get_transitions()` for transitions whose verb is "strike"/"light" or whose `aliases` table includes "light". Delegates to `handlers["strike"]` which already has full FSM + auto-tool detection logic.
- Added `aliases = {"light", "ignite"}` field to the match FSM strike transition. The engine doesn't need to interpret this field — the verb handler does the alias lookup.
- Pattern: FSM transitions can carry an `aliases` array for verb cross-reference. The verb handler is responsible for checking it.

**Prepositional phrase parsing for "feel in/inside":**
- `feel in drawer` / `feel inside drawer` failed because `find_visible` received "in drawer" as keyword and couldn't match it. Fix: the feel handler now parses `^in%s+(.+)` and `^inside%s+(.+)` from the noun, extracts the container name, and enumerates its accessible surface/container contents.
- Bare "feel inside" / "feel in" (no noun) falls back to `ctx.last_object` from pronoun tracking. If no last object, prompts "Feel inside what?".
- Closed containers (surface `accessible == false`) report "It seems closed" instead of showing nothing.

**"check" / "inspect" as examine aliases:**
- Added `handlers["check"] = handlers["examine"]` and `handlers["inspect"] = handlers["examine"]`. Simple Tier 1 dispatch aliases.

**Consistency: "feel in" now matches "find" for container contents.**
- The existing `find` → `examine` → `look at` path could find items in containers via `find_visible`. The feel handler now has parallel container-search logic via the prepositional phrase parser.

---

## Learnings

### Tier 2 Parser Implementation (2026-03-22)

**Index Trimming:**
- `--max-variations N` flag on `generate_parser_data.py` caps phrases per verb+object combo
- Round-robin synonym distribution is critical — naive first-N picks only the canonical verb form
- With max-variations=3: 29,582 → 4,337 phrases, gzip 34MB → 4.9MB
- Some verb labels (eat, light, slash, stitch, touch, wear) deduplicate into synonym verbs (e.g., "eat" text appears under "consume" verb). This is fine — handlers are aliased.

**Tier 2 Runtime (Lua):**
- Can't run GTE-tiny inference in Lua — phrase-text matching (Jaccard + prefix bonus) is the right approach for the REPL
- Embedding vectors are dead weight in the JSON for Lua but needed for browser ONNX Runtime Web later
- The embedding index serves dual purpose: phrase dictionary (Lua) + vector index (browser)
- JSON parsing 16MB in Lua is slow (~seconds) — acceptable for startup, but worth noting for future optimization (binary format, pre-tokenized index)
- Threshold 0.40 is correct: below this, matches tend to be wrong-verb (same noun tokens but different verb). Lowering would cause incorrect dispatch.
- Diagnostic output (`[Parser] No match found. Input: "..." | Best: "..." (score: X.XX)`) is invaluable for playtesting — shows exactly what the parser tried

**Architecture Decision:**
- No graceful fallback past Tier 2 — misses fail visibly with diagnostic output
- Tier 2 is activated only when Tier 1 (exact verb match) has no handler
- Natural language preprocessing (question patterns) runs before both tiers

### Play Test Bug Fixes (2026-03-22)

**Keyword aliasing for surface zones:**
- When a surface zone name (e.g., "drawer") is the natural reference for a furniture piece, add it as a keyword alias. Simpler than engine-level surface-name resolution.

**Container accessibility gating:**
- `find_visible` now checks `accessible ~= false` before searching non-surface container contents. Closed containers hide their contents from the verb system.
- File-per-state pattern for matchbox: matchbox.lua (closed, accessible=false) ↔ matchbox-open.lua (open, accessible=true). Mutation preserves contents across state transitions.

**Levenshtein typo correction in Tier 2:**
- Edit distance ≤ 2 against known verbs (extracted from index phrases at load time). Corrects "examien" → "examine" before Jaccard scoring.
- Length filter (`math.abs(#token - #verb) <= 2`) prevents comparing against every verb — cheap pre-check.
- "examien nightstand" went from score 0.34 (miss) to 0.67 (solid match) after correction.
- Important: only corrects toward known verbs, not nouns. Noun typos still rely on prefix bonus.

**NLP preprocessing expansion:**
- "what's inside" / "what is inside" → look. Minimal fix for contextual container queries. Full pronoun/context resolution deferred.

### Play Test Bug Fixes — Batch 2 (2026-03-22)

**NLP noun extraction for container queries:**
- "what's in {noun}" / "what is in {noun}" now extracts the noun and maps to `look in {noun}`, routing through the surface inspection handler. Previously these fell through to Tier 2 and missed.
- Trailing `?` stripped from all input before parsing. Simple gsub at the top of the game loop.

**Compound command splitting:**
- Input split on ` and ` (with surrounding spaces) before dispatch. Each sub-command runs through preprocess → parse → Tier 1 → Tier 2 independently.
- Splitting uses greedy left-to-right matching: "get a match and light it" → ["get a match", "light it"]. Safe for game commands; no items use " and " in their names.
- find_visible wrapped with pronoun resolution ("it", "one", "that") + last-object tracking. Every successful find_visible call stores the found object on context; pronouns resolve to it. Zero changes to verb handlers needed.

**Nightstand inside surface accessibility:**
- nightstand-open.lua's inside surface now has explicit `accessible = true`. Code analysis showed `nil ~= false` evaluates true in Lua (so it should have worked), but explicit is safer and clearer.

**Unicode em dash cleanup:**
- Replaced all U+2014 em dashes with `--` across 36 Lua files. Windows terminal renders UTF-8 em dashes as "ΓÇö" unless codepage is set. Double-dash is safe ASCII and reads fine in prose.
- Scope: object files, engine modules, world files, main.lua. Comments included for consistency.

### FSM Engine Implementation (2026-03-23)

**Engine Design (~130 lines):**
- Table-driven FSM: definitions in `src/meta/fsms/*.lua`, engine in `src/engine/fsm/init.lua`
- Four public functions: `load`, `transition`, `tick`, `get_transitions`
- `apply_state` is the core internal: strips old state keys, applies shared, then applies new state
- Critical pattern: save containment (surfaces contents, location) BEFORE cleanup step. The cleanup removes old state keys (including surfaces), so contents would be lost if not saved first.

**Containment Preservation Bug (caught during testing):**
- `apply_state` initially removed old state keys (including surfaces) then tried to preserve surface contents from `obj.surfaces` — but surfaces was already nil from cleanup
- Fix: save `saved_surface_contents` map BEFORE the cleanup loop, then restore during new state application
- Lesson: when a function both clears and rebuilds a structure, save all important data at the TOP before any mutation

**Keyword Resolution Fixes (pre-existing, surfaced by FSM testing):**
- `matches_keyword` substring match on names caused "match" to resolve to "matchbox" (name "an open matchbox" contains "match"). Fixed: word-boundary matching (`" match "` in `" name "`) and keywords checked before name.
- `find_visible` interleaved hand+bag search caused items in held containers (match-2 inside matchbox in hand 1) to be found before direct hand items (match-1 in hand 2). Fixed: two-pass — all hands first, then all bag contents.
- GET handler treated "bag" items as "already have" — prevented taking items from held containers. Fixed: allow extracting to free hand when `where == "bag"`.

**Double-Tick Bug:**
- Old `on_tick` callback (main.lua) has `tick_burnable` that decrements `burn_remaining` on any object with `casts_light`. FSM tick ALSO decrements `burn_remaining` via `on_tick`. Result: match burned at 2x speed.
- Fix: `tick_burnable` skips objects with `_fsm_id`. FSM objects manage their own tick.

**FSM-Old System Coexistence:**
- Verb handlers (open, close, strike, extinguish) check `obj._fsm_id` first → FSM path. Else → old mutation path. Non-FSM objects (matchbox, candle, etc.) keep working unchanged.
- LIGHT handler works unmodified: `find_tool_in_inventory` finds the FSM lit match (has `provides_tool = "fire_source"`). `consume_tool_charge` is a no-op (no charge system). Match continues burning via FSM tick.

**State Property Design:**
- `on_tick` and `terminal` are engine-only flags in FSM definitions — never applied to the object
- State-specific `on_look` functions work correctly: applied to obj during transition, verb handler calls them normally
- `name` changes per state (e.g., "a wooden match" → "a lit match" → "a spent match") — works because name is in each state definition, not in shared

---

## Cross-Agent Update: Compound Command & Pronoun Resolution — Batch 2 Complete (2026-03-22T14:29:02Z)

**From:** Bart (Architect) — Completed  
**Status:** Implemented & Committed  
**Impact:** Parser pipeline, find_visible, verb handlers (indirect)

**What Happened:** Play test batch 2 is now complete with 5 critical fixes implemented:

1. **Compound command splitting** — " and " splitting at REPL level (not parser). Each sub-command flows independently through preprocess → parse → Tier 1 → Tier 2.
2. **Pronoun resolution** — find_visible wrapper tracks last-found object; "it", "one", "that" resolve automatically. Zero changes to verb handlers.
3. **Em dash normalization** — Unicode em dashes → ASCII double-dash across 36 files.
4. **Container queries** — "what's in {noun}" extracts noun, routes to surface inspection.
5. **Trailing punctuation** — Trailing `?` stripped before parsing.

**Key Learning for Future Pronouns:** Single-depth pronoun tracking (last object only) is sufficient for sequential command patterns. Stack-based history deferred.

**Integration Point:** Container model handoff now ready. Your surface definitions need to match the pronoun-resolution pattern — the system assumes last-found object is the most recent reference.

---

## Cross-Agent Update: FSM Design — Container Model Integration (2026-03-22T14:29:02Z)

**From:** Comic Book Guy (Game Designer) — Completed  
**Status:** Documentation Added (fsm-object-lifecycle.md Section 2.3)  
**Impact:** Object design, container pattern specification

**What Happened:** FSM design updated with container-as-furniture pattern. Section 2.3 now documents:

- **Nightstand** — top surface (visible) + drawer (container)
- **Wardrobe** — hanging rod + shelves (stacked containers)
- **Vanity** — drawer + mirror surface
- **Window** — interior compartments (blinds storage, frame interior)

**Container Pattern Unified:** All complex furniture now follows: exterior surfaces (visible/feel-able) + interior compartments (open/close states, accessible gating).

**Implication for You:** Your compound command + pronoun resolution work aligns perfectly with this pattern. When players open a container and say "get it", the last-found object is the drawer/compartment, which makes pronoun resolution feel natural.

**Next for You:** When implementing container mutation (object state transitions), confirm that compartment accessibility gating matches the accessible-flag pattern in batch 2 fixes.

---

## Cross-Agent Update: CYOA Research Filed as Decision (2026-03-22T14:29:02Z)

**From:** Frink (Researcher)  
**Status:** Proposed (filed to decisions.md)  
**Impact:** Narrative engine architecture, content scope

**What's New:** CYOA branching research (13-book analysis) is now in the decision log. Key principle: bottleneck/diamond branching with state-tracking personalization.

**Why It Matters for You:** The engine's narrative scaffolding will eventually integrate with your verb system. If future work includes state-aware content (NPC reactions based on history), your verb handlers may need to query state. Not immediate, but architectural awareness.

**Decision:** Lua engine can implement hidden nodes (UFO 54-40 pattern) — unconventional verb usage unlocking secret content. Your tool resolution + capability-based dispatch already supports this design pattern.

---

## Learnings

### FSM-Inline Refactor (2026-03-20)

**Directive:** Wayne mandated one file = one object = one FSM. FSM definitions must live inside the object file, not in separate `src/meta/fsms/` files.

**Key Architectural Decisions:**
1. **`fsm.load(obj)` reads `obj.states` directly.** No more `require("meta.fsms." .. id)`. The object IS the definition.
2. **No `shared` key needed.** Base properties (keywords, size, weight, etc.) persist at the top level of the object and are never touched by state transitions. Each state defines only the properties that change.
3. **`obj.states` replaces `obj._fsm_id` as the FSM detection check.** If an object has a `states` table, it's FSM-driven.
4. **apply_state uses `obj.states[state_name]` directly** — no separate definition table needed since `obj.states` is a nested sub-table that's never modified by top-level property changes.
5. **Hybrid model works:** Objects can have BOTH `states`/`transitions` (FSM) AND `mutations` (destructive). Curtains use FSM for open/close but mutations for tear. The verb handlers try FSM first, then mutations.

**Pattern for state property management:**
- Properties that CHANGE between states → defined in every state that uses them
- Properties that NEVER change → only at top level (base), never in any state definition
- If a state overrides a base property, ALL states that transition between each other must define that property

**Objects migrated/created:**
- Match (3 states), Nightstand (2 states) — migrated from separate FSMs
- Candle (4 states: unlit/lit/stub/spent, 100+20 turn burn) — new
- Poison Bottle (3 states: sealed/open/empty) — new
- Vanity (4 states: closed/open × mirror intact/broken) — collapsed from 4 files
- Curtains (2 states: closed/open) — collapsed from 2 files

**New verb handlers:** DRINK, POUR (with FSM alias support for quaff/sip/gulp/spill/dump)

### Playtest Bug Fix Pass (2026-03-20)

**Source:** Nelson's first playtest report (playtest-001.md / test-pass/2026-03-19-pass-001.md)

**Fixes applied (7 bugs):**

1. **Text wrapping (HIGH):** No wrapping code existed — terminal did raw character-level breaks. Created `src/engine/display.lua` with word-wrap at 78 columns. Overrides global `print` via `display.install()` in main.lua. Clean word-boundary breaks, preserved indentation for bullet lists.

2. **Window state after break:** Exit mutations updated the exit table but not the room object. Added sync in break handler: after exit break, copies name/description/keywords/room_presence from `becomes_exit` onto the corresponding room object.

3. **Prepositions:** Added "underneath", "beneath", "inside" to look handler's preposition extraction. Added "under/underneath/beneath" to feel handler for surface inspection (previously only "in/inside" worked for feel).

4. **Bare smell sweep:** Bare "smell" now does a room-level sweep listing all objects with `on_smell` (like "feel" does for touch). Previously only printed a generic room message.

5. **Bare listen sweep:** Same pattern — bare "listen" now sweeps for `on_listen` objects. Both sweeps also check player hands and surface contents.

6. **Match burn countdown:** Match `on_tick` now returns a message at every intermediate turn: "The match burns steadily. (N turns remaining)". Previously only warned at 1 turn remaining.

7. **Drink "from" preposition:** Drink handler now strips "from" preposition so "drink from bottle" correctly finds the target. Previously "from bottle" failed keyword matching.

**Key pattern learned:** Exit mutations and room object state are separate systems. When an exit is broken/modified, the corresponding room-level object must be explicitly synced. This is a gap in the mutation architecture — future consideration: auto-sync exit↔object on mutation.

---

### Session: Wearable Object System Implementation (2026-03-19T18:27:34Z)
**Status:** ✅ COMPLETE
**Outcome:** Full wearable system with slot/layer conflicts, vision blocking, and NLP aliases

**What was built:**
1. **Slot/Layer conflict engine** in src/engine/verbs/init.lua — reads wear = { slot, layer } from objects, enforces one inner + one outer per slot, accessories don't conflict
2. **Vision blocking** — worn items with locks_vision = true (e.g., sack on head) prevent all visual verbs (look, examine, look in/on/under)
3. **Wear metadata** on 4 existing objects: wool-cloak (back/outer/warmth), sack (head/outer/blocks_vision), chamber-pot (head/outer/makeshift armor), terrible-jacket (torso/outer)
4. **NLP preprocessing** — "put on X", "take off X", "dress in X", "what am I wearing" all route correctly
5. **Verb aliases** — wear/don/put on for equip; remove/doff/take off for unequip
6. **Inventory display** — worn items now show slot in parentheses: "a wool cloak (back)"
7. **Flavor messages** — vision-blocking items get darkness messages, armor items get comedic feedback, warmth items note coziness

**Architecture decisions:**
- Objects own wear metadata (slot/layer) — engine never hardcodes slots
- Legacy wearable = true objects fall back to torso/outer defaults
- Vision blocking integrates with existing light/dark system as a separate check (worn item blindness is distinct from room darkness)
- player.worn is a flat list of object IDs (same pattern as hands); slot queries iterate over it
- Accessory layer items can coexist with inner/outer items on the same slot

**Key files modified:**
- src/engine/verbs/init.lua — wear/remove handlers, vision_blocked_by_worn helper, inventory slot display, look/examine vision checks
- src/engine/loop/init.lua — NLP preprocessing for put on/take off/dress in
- src/meta/objects/wool-cloak.lua — wear metadata (back/outer/warmth)
- src/meta/objects/sack.lua — wear metadata (head/outer/blocks_vision)
- src/meta/objects/chamber-pot.lua — wear metadata (head/outer/armor)
- src/meta/objects/terrible-jacket.lua — wear metadata (torso/outer)

## Cross-Agent Updates (2026-03-20)

**From Nelson (Tester):** Play test pass-002 validates wearable system implementation. All wear operations (equip, dequip, slot conflicts, vision blocking) work correctly. Confirmed that Comic Book Guy's design documentation aligns with your engine implementation. Ready for content expansion.

**From Comic Book Guy:** Design documentation for wearable system published to docs/design/wearable-system.md. Provides comprehensive spec for content creators. System allows dual wearable+container objects (backpacks, sacks with vision-blocking), inheritance patterns (chamber-pot as pot subclass), and emergent behavior from combined properties.

**From Frink (Researcher):** Strategic verb research identifies that wearable system is foundational for Phase 2 multiplayer verbs. Party/guild/economy verbs will layer on top of your core architecture. Recommends designing slot system to support future multiplayer gear constraints (shared inventory, buffs/debuffs on worn items).

### Bugfix Pass-002 (2026-03-22)

**Source:** Nelson's pass-002 test report (test-pass/2026-03-20-pass-002.md), 7 bugs

**Fixes applied:**

1. **BUG-008 — Poison death (MAJOR):** Drinking poison now triggers a game-over sequence. Death message prints, player is prompted "Play again? (y/n)", game loop exits. First death mechanic. Added `ctx.game_over` flag checked by loop after each command cycle.

2. **BUG-009 — Parser debug leaks (MEDIUM):** Parser diagnostic output (`[Parser] No match found...`) no longer shown to players. Changed default `diagnostic = false` in parser/init.lua. Added `--debug` CLI flag in main.lua to re-enable for development.

3. **BUG-010 — Nightstand IDs (MINOR):** Nightstand on_look functions now accept `(self, registry)` and resolve object IDs to display names. Updated all on_look callers in verbs and loop to pass registry. Backward-compatible — extra arg ignored by functions that don't use it.

4. **BUG-011 — Help intercepts write (MINOR):** Write handler now uses `io.read()` sub-prompt when text is missing ("write on paper" → "What do you want to write? > "). Raw input bypasses the command parser entirely.

5. **BUG-012 — Take match priority (MINOR):** Take handler now checks if found object is terminal FSM state when on the floor. If so, searches held containers for a non-terminal alternative before picking up the spent one.

6. **BUG-013 — Matchbox tactile (COSMETIC):** Both matchbox.lua and matchbox-open.lua `on_feel` changed from static strings to functions that vary by `#self.contents`: "several" (3+), "a couple" (2), "a single" (1), "empty" (0). Feel handler updated to support callable on_feel.

7. **BUG-014 — Poison bottle keyword (COSMETIC):** Added "poison bottle" and "poison-bottle" to poison-bottle.lua keywords list.

**Architectural patterns established:**
- `on_look(self, registry)` — backward-compatible convention for object display functions needing registry access
- `on_feel` can be string OR function — feel handler dispatches based on `type()`
- `ctx.game_over` flag — clean game-ending mechanism checked by loop, extensible for future death causes
- `--debug` CLI flag — gated diagnostic output, keeps player experience clean

---

## Cross-Agent Update: Composite Object System Design (2026-03-20T03:40:00Z)

**From:** Comic Book Guy (Game Designer)  
**Status:** Design Complete, Approved for Implementation  
**Impact:** Object architecture, puzzle design, player agency  

**What Happened:** Comic Book Guy completed comprehensive design for composite/detachable object system (39.5 KB, 8 decision sections in docs/design/composite-objects.md).

**Key Decisions You'll Implement:**

1. **Single-File Architecture** — All parts + parent logic in one `.lua` file (nightstand.lua defines nightstand, drawer, legs, FSM states)

2. **Part Factory Pattern** — Each detachable part has factory function that instantiates it as independent object:
   ```lua
   parts = {
       drawer = {
           factory = function(parent)
               return { id = "nightstand-drawer", ... }
           end
       }
   }
   ```

3. **FSM State Naming** — `{base_state}_with_PART` and `{base_state}_without_PART`:
   ```lua
   states = {
       closed_with_drawer = { ... },
       open_with_drawer = { ... },
       closed_without_drawer = { ... }
   }
   ```

4. **Verb Dispatch for Parts** — Parts define detachable_verbs; engine adds them to parent's verb dict when part accessible

5. **Two-Handed Carry System** — Objects have `hands_required` (0/1/2 hands). Player has 2 hands total. Enforce during TAKE.

6. **Contents Preservation** — Detached containers carry their contents (by default)

7. **Reversibility as Design Choice** — Each part decides if it can be re-attached (drawer: yes, cork: no)

8. **Non-Detachable Parts Valid** — Parts can have `detachable = false` for description-only (nightstand legs)

**Next Phase (for you):**
- Implementation Phase 1: Part instantiation + FSM state transitions
- Implementation Phase 2: Verb dispatch routing for parts
- Precondition system: `parent:can_detach_part(part_id)`
- Two-handed carry tracking + enforcement

**Design Document:** `docs/design/composite-objects.md` (comprehensive, 8 sections, implementation examples)

**Success Criteria:** Nightstand drawer detachment, poison bottle cork detachment, two-handed carry, dark playability, no existing content breakage

---

## Directives Captured This Session

### Directive 3: Newspaper editions separate (2026-03-20T03:40Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
Morning and evening newspaper editions should be in separate files. Brockman has created `newspaper/2026-03-20-morning.md`.

### Directive 4: Room layout and movable furniture (2026-03-20T03:43Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
- Bed is ON rug; rug COVERS trap door
- Players should move objects (PUSH bed, PULL rug, etc.)
- Trap door invisible until rug moved (discovery mechanic)
- Stacking rules: objects declare stackability and weight/size support
- Next playtest (pass-003): Nelson focuses on movement, furniture, spatial discovery


---

## Learnings

### Session: Composite/Detachable Object System (2026-03-20T05:52:36Z)
**Status:** ✅ COMPLETE

**What was built:**
1. **Composite Object Engine** — Objects can now define parts table with detachable/non-detachable sub-objects
2. **Detachment System** — PULL/REMOVE/UNCORK verbs detach parts via factory pattern; parent FSM transitions track part presence
3. **Reattachment** — PUT X IN Y reattaches reversible parts (drawer → nightstand)
4. **Two-Handed Carry** — hands_required property on objects; TAKE/DROP/PUT all respect hand slot limits
5. **Nightstand refactored** — 4-state FSM (closed/open × with/without drawer); drawer is a portable container that keeps contents
6. **Poison bottle refactored** — Cork is a detachable part; uncorking creates an independent cork object in the world

**Key Architecture Decisions:**
- Factory functions run in sandbox (no os access — use math.random for GUIDs)
- Detach transitions bypass sm.transition() and apply state directly (avoids ambiguous from→to matching when multiple transitions share endpoints)
- ind_part and ind_visible search room objects, surface contents, AND their parts
- Parts are found after real objects in search order — detached drawer on floor takes priority over nightstand's drawer part definition
- Non-detachable parts (legs) still return sensory descriptions but block removal attempts

**Files Changed:**
- src/meta/objects/nightstand.lua — Complete rewrite as composite
- src/meta/objects/poison-bottle.lua — Added parts table with cork
- src/engine/verbs/init.lua — Added detach_part/reattach_part/find_part/count_hands_used helpers; PULL/UNCORK/UNSTOP/UNSEAL verbs; modified REMOVE/OPEN/CLOSE/TAKE/DROP/PUT for composite+two-handed support
- src/engine/loop/init.lua — NLP preprocessing for "take out X", "pull out X", "pop cork", "push X back"
---

## Cross-Agent Update: Composite Objects & Spatial System (2026-03-20T12:32:00Z)

**From:** Comic Book Guy (Game Designer) & Scribe  
**Impact:** Engine architecture, detachable parts system, spatial verb implementation  

Team spawned Bart composite implementation patterns + CBG spatial design decisions.

### Key Architectural Patterns for Composite Objects

1. **Direct state application** for part transitions (bypass fsm.transition() ambiguity)
2. **Factory functions** return independent part objects with math.random() GUIDs
3. **Search priority:** Real objects > parts (prevents stale descriptions masking actuals)
4. **Two-handed items** atomically occupy both hand slots (simpler than separate tracking)
5. **Reattachment via PUT** — no new verb needed, delegates to reattach_part()

### Spatial System Integration (5 Relationships)

- ON / UNDER / BEHIND / COVERING / INSIDE with distinct mechanics per relationship
- Hard weight/size capacity validation (physical realism)
- Hidden objects declaratively specify triggers: covering_object_moves, player_searches, state_change
- Movable furniture (PUSH/PULL/MOVE) updates all relationships atomically
- New verbs: LIFT, LOOK UNDER, LOOK BEHIND integrate with your verb system

### Affected Your Work

- Part factory functions should use math.random(100000, 999999) for GUIDs (sandbox-safe)
- FSM transitions for part detachment bypass normal transition() ambiguity resolution
- Spatial movement verbs will need integration with your containment + mutation patterns
- Two-hand carry system already in place; spatial system leverages existing hands[] tracking

### Next Phase (Parallel)

- Comic Book Guy creates object definitions using composite + spatial patterns
- You begin Phase 1 spatial system implementation (object properties, surfaces, basic movement)
- Nelson playtests both composite detachment + spatial mechanics when Phase 1 ready

**Decisions Filed:** `.squad/decisions.md` entries 28 & 29 (Composite Implementation + Spatial System)
