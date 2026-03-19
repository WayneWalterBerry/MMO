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
