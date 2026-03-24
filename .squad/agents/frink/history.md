# Frink — History (Summarized)

## Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO — Self-modifying universe code in Lua
- **Role:** Technical researcher and architect

## Core Context

**Agent Role:** Research and analysis specialist providing architectural guidance and technical feasibility studies.

**Research Delivered (2026-03-18 to 2026-03-20):**
1. **Text Adventure Architecture** — Parent-child containment tree, rooms as graph nodes, standard verb-noun pipeline
2. **Lua as Primary Language** — Homoiconicity, prototype inheritance, production pedigree (200+ games), small runtime
3. **Multiverse Architecture** — Per-universe Lua VMs, event sourcing, copy-on-write, procedural generation
4. **Self-Modifying Code & Sandbox Security** — 6 sandbox layers, 8 threat classes mitigated
5. **Parser Pipeline** — Classic IF pipeline, three-tier hybrid (rule-based + embedding + optional SLM)

**Key Reports:** 5 architecture reports, local SLM parser, parser distillation, PWA/Wasmoon, CYOA analysis (14 files), competitive analysis (16 competitors), MUD verb research

## Archives

- `history-archive-2026-03-20T22-40Z-frink.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): all research deliverables, architecture reports, parser studies, PWA feasibility, CYOA analysis, competitive landscape, MUD verbs

## Recent Updates

### Meta-Compiler Research (2026-03-28)
**Status:** ✅ COMPLETE (5 research documents)
**Reports:** `resources/research/meta-compiler/` (76 KB, 5 documents)
**Requested by:** Wayne Berry (Effe), for Lisa (Object Tester)

**Scope:** Research for a custom meta-compiler that validates `.lua` object and room files using compiler-like techniques (lexer → parser → semantic analysis). P0 for shipping tomorrow.

**Key Findings:**

1. **Compiler Techniques Work** (`compiler-techniques-for-game-data.md`)
   - Dwarf Fortress RAW validators use lexer → parser → semantic analyzer
   - Factorio uses load-time prototype validation
   - Unity ScriptableObjects use OnValidate hooks
   - All major tools follow: lex → parse → analyze → report
   - Recommendation: ✅ Our approach is sound and proven

2. **Lua Subset is Tiny** (`lua-subset-parsing.md`)
   - Objects are: `return { key = value, ... }` (nested table literals)
   - Values: strings, numbers, booleans, nil, nested tables, arrays, functions
   - **NO:** function calls, control flow, computed keys, variables
   - **Parser estimate:** 50-100 lines with Lark, 200-300 hand-written
   - **Real-world:** All 74 objects fit this pattern; 0 exceptions

3. **Python + Lark is Best** (`language-evaluation.md`)
   - **Speed:** 2-3 hours to MVP (vs. 8-12 for Rust, 6-8 for TypeScript)
   - **Fit:** Already using Python in scripts/
   - **Ecosystem:** Lark is mature; error messages easy to polish
   - **Integration:** Perfect for CI/CD, pre-commit hooks
   - **Estimate:** 750 lines for MVP; 8-12 hours build time

4. **Tool Name: meta-check** (`naming-and-architecture.md`)
   - Full name: "MMO Meta Validator"
   - Short name: "meta-check" (clear, memorable, domain-specific)
   - Architecture: Layered CLI tool (lexer → parser → validators → error reporter)
   - Integration: Pre-commit hook, GitHub Actions, IDE extension (optional), manual CLI
   - CLI: `meta-check src/meta/` outputs JSON or human-readable errors

5. **Schema Catalog Complete** (`schema-catalog.md`)
   - 5 templates: small-item, container, furniture, room, sheet
   - For each: required fields, optional fields, constraints, FSM rules, nesting rules
   - Cross-references: material registry, room targets, GUID uniqueness
   - Validation rules: types, enums, patterns, ranges, references

**Architecture:**
```
File → Lexer (tokens) → Parser (AST) → Semantic Analyzer 
  → Field Validator → Type Validator → Reference Validator → FSM Validator → Error Reporter
  → Output (JSON or CLI)
```

**Next Phase (Bart's Work):**
1. Finalize Lark EBNF grammar for Lua subset
2. Formalize field definitions per template
3. Outline each validator module
4. Build working MVP in 1 day

**Deliverables:**
- `compiler-techniques-for-game-data.md` (13 KB) — Industry precedent research
- `lua-subset-parsing.md` (16 KB) — Parser complexity analysis + real-world patterns
- `language-evaluation.md` (14 KB) — 5 languages compared; recommendation: Python + Lark
- `naming-and-architecture.md` (15 KB) — Design, CLI interface, integration points
- `schema-catalog.md` (18 KB) — Formal validation rules per template (76 fields, 9 principles)

---

### MUD System Gap Analysis (2026-03-27)
**Status:** ✅ COMPLETE
**Report:** `docs/research/mud-system-gap-analysis.md` (22KB, 6 matrices)
**Requested by:** Wayne Berry (Effe)

**Key Findings:**
- Current coverage: 39/87 verbs (45%), 6/12 systems
- Critical gaps: Communication (0/11 verbs), Commerce (0/5 verbs), NPCs (0/1 system)
- We have solid single-player foundation (object manipulation, injuries, parser, sensory)
- Intentional: Combat deferred to Phase 2+; verb count is lower by design (mobile-friendly)
- Multiplayer blockers: No chat, no NPCs, no economy system
- Priority roadmap:
  - P0 (Pre-multiplayer): Communication, NPCs, Economy
  - P1 (Phase 1.5): Crafting recipes, XP/Skills, Quests
  - P2+ (Later): Combat, Guilds, Housing
- Comparative: Classic MUDs have 200-400 verbs + 12-15 systems; we're targeting 80-100 verbs + 12-14 systems post-MVP

**Deliverables:**
- Section 1: Verb Coverage Matrix (12 categories, 87 verbs total)
- Section 2: System Coverage Matrix (current vs. needed)
- Section 3: Priority gaps ranked by impact
- Section 4: Systems we can skip (magic, minigames, guild wars)
- Section 5: Recommendations for CBG (Design) and Bart (Architecture)
- Section 6: Comparative analysis vs. classic MUDs

**Insights for Design/Architecture:**
- Communication and economy are multiplayer prerequisites (blocking issues for Phase 1 multiplayer)
- NPC dialogue system needs quest state tracking and merchant inventory persistence
- Crafting framework (recipes + skill gates) unlocks progression mechanics
- Current verb gap (45%) is acceptable; the system gap (50%) is the actual blocker

---

### MUD Verb Research (2026-03-25)
**Status:** ✅ COMPLETE
**Report:** `resources/research/competitors/mud-clients/verbs.md` (27KB)

**Key Findings:**
- MUDs have 5-10× more verbs than single-player IF (170-500+ vs 20-40)
- Social verbs drive retention (200+ predefined emotes in Discworld)
- Natural language parsing enables rich command flexibility
- Abbreviations mandatory (n/s/e/w/u/d, i, l)
- Multiplayer verbs structurally distinct (party, guild, PvP, economy)
- Verb aliases enable power-user customization

### Competitor Research Reorganization (2026-03-25)
- Reorganized 16 competitor files into per-competitor subfolders
- Scalable architecture for future deep dives

### CYOA Branching Analysis (2026-03-24)
**Report:** `resources/research/choose-your-own-adventure/` (14 files)
- 6 branching patterns across 184 books
- Inside UFO 54-40's unreachable ending most applicable
- Recommendation: bottleneck/diamond branching + hidden content

### PWA + Wasmoon Feasibility (2026-03-24)
**Report:** `.squad/agents/frink/research-pwa-wasmoon.md`
- Wasmoon highly viable: Lua 5.4 to WASM, ~90% unmodified
- Three adaptations needed (io.popen, blocking REPL, print/io.write)
- Performance: ~168KB gzipped, <5ms per command
- Prototype: 5-7 hours. Decision D-43 filed.

### Competitive Analysis (2026-03-24)
**Report:** `resources/research/competitors/` (16 files + overview)
- Mobile IF market: $1.85B (2024), 13.2% CAGR
- Parser input #1 barrier on mobile
- "Starts in darkness" commercially validated (A Dark Room hit #1 iOS)
- Multiplayer text adventure on mobile is whitespace
- Premium one-time purchase preferred

### Model Distillation Research (2026-03-23)
**Report:** `resources/research/architecture/parser-distillation.md`
- Embedding-based (GTE-tiny ~5MB, 92-95% accuracy) beats generative (350MB, ~3% more)
- Three-tier hybrid optimal: Tier 1 rule-based, Tier 2 embedding, Tier 3 optional SLM
- Re-distillation trivial: ~35s, ~$0.05 per new verb

### Local SLM Parser Research (2026-03-22)
**Report:** `resources/research/architecture/local-slm-parser.md`
- Browser SLMs viable: Qwen2.5-0.5B, WebGPU
- Hybrid: rule-based (~85%, <1ms) + SLM fallback (~15%)
- Decision 17 satisfied (zero per-player token cost)

### Hybrid Parser Proposal (2026-03-21)
**Status:** PROPOSED — merged into canonical decisions.md

## Decisions Filed
- D-43: PWA + Wasmoon Prototype Feasibility
- Hybrid Parser Architecture (Rule-Based + Local SLM)

## Recommendations Summary
- Build rule-based parser now, add local SLM post-MVP
- Embedding-primary hybrid (5.5MB) replaces most of 350MB SLM
- Proceed with Wasmoon prototype (high confidence, low risk)
- Bottleneck/diamond branching for narrative structure
- Tap-to-suggest UI for mobile, async multiplayer first
- 50-100 predefined socials for MVP retention

## P0-B: Meta-Compiler Research Tasks (2026-03-24)

**Status:** ✅ COMPLETE  
**Requested by:** Wayne "Effe" Berry  
**For:** Custom Meta Compiler — P0 deliverable for Lisa (Object Tester)

### Deliverables

1. **Bug Catalog:** `resources/research/meta-compiler/bug-catalog.md` (13.4 KB)
   - **38 total bugs** cataloged across 26 commits
   - **Classification:** 7 categories (missing metadata, invalid references, missing structural properties, missing base classes, keyword collisions, semantic logic errors, architectural violations)
   - **Top 5 bug types** prioritized for meta-check implementation:
     1. Missing metadata fields (20 bugs) — materials, display names
     2. Invalid references (10 bugs) — GUID mismatches, missing templates
     3. Missing structural properties (3 bugs) — FSM surfaces, container definitions
     4. Missing base class files (4 bugs) — referenced objects not created
     5. Keyword collisions (1 bug) — fuzzy matcher disambiguation failures
   - **Scope:** meta-check module estimate: 850 LOC, 110 ms execution time
   - **Key finding:** All critical bugs fixed in history; system now clean

2. **Cross-Reference Inventory:** `resources/research/meta-compiler/cross-reference-inventory.md` (14.5 KB)
   - **Material references:** 23 unique materials, 82/83 objects have valid material declarations
   - **Template usage:** small-item (44.6%), furniture (33.7%), sheet (12%), container (9.6%)
   - **GUID integrity:** 103 total GUIDs, 0 duplicates, 100% valid UUID v4 format
   - **Room exit targets:** 18 total exits, 13/18 resolved (72%), 5 marked PENDING (planned expansion)
   - **Broken references found:** 0 critical (all historical bugs fixed)
   - **Keyword collisions:** 401 unique keywords, 473 total entries, 13.5% duplicate density (acceptable)
   - **System health:** GREEN ✅ — all critical references resolve correctly
   - **Scope:** cross-reference validation module estimate: 930 LOC, 180 ms execution time

### Key Findings

1. **Bug Pattern Cluster Analysis**
   - Missing metadata bugs (mostly historical, e.g., BUG-104: 20 objects missing `material` field)
   - GUID mismatches were systematic (BUG-106: 30 mismatches across 5 rooms, now fixed)
   - Missing structural properties tied to FSM complexity (BUG-048/109: large-crate surfaces)
   - Keyword collisions rare but player-facing (BUG-153: "brass bowl" collision fixed)

2. **Cross-Reference Health**
   - Object system is robust: 100% of material references valid, 100% of templates valid, 0 GUID collisions
   - Room navigation partially complete: 72% of exits resolve to existing rooms; 28% pending future expansion
   - Keyword distribution shows no systemic collisions; generic terms ("door", "key") expected duplicates

3. **Meta-Check Validation Rules** (Priority 1-5)
   - **P1:** Material field validation — ensure all 83 objects declare valid materials
   - **P2:** GUID mismatch detection — validate room type_id → object GUID mappings
   - **P3:** Structural property validation — ensure FSM states have complete surfaces definitions
   - **P4:** Missing base file detection — verify all type_id values have corresponding .lua files
   - **P5:** Keyword collision detection — flag exact duplicates and material-based fuzzy collisions

4. **System Maturity Assessment**
   - Object system: ✅ MATURE — 100% material coverage, correct template usage
   - Room system: ⏳ PARTIAL — 72% navigation complete, pending rooms intentional
   - Keyword system: ✅ GOOD — 86.5% unique keywords, collisions are acceptable
   - GUID system: ✅ MATURE — 103 GUIDs with 0 collisions, valid format across all files

---

## Learnings

### Meta-Compiler Architecture (2026-03-24)

- **Compiler techniques proven effective** for game data validation — Dwarf Fortress, Factorio, Unity all use similar pipeline (lex → parse → analyze → report)
- **Meta-check execution cost:** ~180 ms for full cross-reference validation across 83 objects + 7 rooms — acceptable for pre-commit hook
- **Bug clustering reveals priorities:** Most common bugs cluster into 5 categories; implementing checks for top 3 (metadata, references, structures) prevents ~70% of historical issues
- **GUID mismatches were systematic, not random** — systematic audit required to fix all 30 at once; implies need for automated GUID assignment rather than manual copy-paste
- **Keyword collision density (13.5%) is noise-level** — generic terms ("door", "key") naturally appear 3+ times; only material-based fuzzy collisions are player-facing issues
- **Room exit "broken" references are intentional planning artifacts** — 5 unresolved exits (level-2, manor-west, manor-east, manor-kitchen) are future expansion points, not errors; meta-check should mark as PENDING, not ERROR
- **Material property system is foundational** — all 83 objects depend on material registry; material field is non-negotiable dependency for any container/fragility system
- **Template over-concentration in small-item (44.6%)** suggests opportunity to create sub-template taxonomy (consumables, treasures, tools) post-MVP
- **FSM state consistency is highest-risk structural pattern** — BUG-048/109 show that FSM states must maintain identical surface property structure across all variants; incomplete states silently break containment logic

### Web Performance (2026-03-27)

- **Bundle splitting is 10x more effective than compression.** Moving from 16 MB monolithic to 3 bundles (500 KB core, 15.6 MB index, content) reduces time-to-first-interaction from ~4s to ~1.2s via lazy-loading. HTTP/2 multiplexing makes split bundles strictly faster on GitHub Pages.
- **Gzip compression ratio for JavaScript is inherently low (~12–15%).** Fengari + embedding index as JSON compresses only to 14% because embedding vectors are pseudo-random. Brotli adds ~10% improvement but GitHub Pages only serves gzip.
- **V8 compilation overhead dominates load time, not network transfer.** 16 MB JS takes ~2–3 seconds to parse and compile (inherent to JS engines), not network. Splitting solves this by deferring large JS compilation.
- **Coroutine yield architecture enables progressive loading without major refactor.** Game-adapter.lua can yield after engine init, allowing browser to load game-index.js in background while player sees terminal. Natural fit for Fengari's async architecture.
- **Service Worker caching for text games should use "Cache first" for static code, "Stale while revalidate" for content.** Different cache strategies per bundle type: engine ∞, index 7 days, HTML 1 hour.
- **GitHub Pages doesn't support custom Cache-Control headers via .headers files.** Workaround: use content-hashed filenames (game-core-abc123.js) or query params (?v=20260327) for cache-busting. For long-term, consider Cloudflare Pages.
- **Text games have UX advantage over visual games in progressive loading.** Terminal UI shows immediately after core parse (~1s), player doesn't perceive waiting like in visual games that must render assets first. Fengari + text UI = fast perceived load.
- **Wasmoon is viable post-MVP per Decision D-43.** Lua → WASM gives ~2–3x speed improvement + offline WASM execution. Current recommendation: MVP with Fengari, prototype Wasmoon in Phase 2 (3–5 day effort).
- **Stripping Fengari stdlib is low ROI.** Removable modules (io, os, debug) add only ~50 KB; bundle splitting already saves 1.8 MB. Skip stdlib trimming; focus on architecture optimizations.
- **Performance targets for text game: <2s time-to-first-interaction, <6s full load.** Reasonable for 4G mobile; 2G/3G will be slower but playable. Measure with Performance API + Lighthouse; DevTools Network tab shows actual transfer size (gzipped).

### Original Research (Cumulative)

- Embedding matching beats generative distillation for constrained domains
- Browser SLMs are real but 350MB download limits adoption
- Wasmoon enables zero-framework Lua PWA deployment
- CYOA hidden/unreachable content translates directly to unconventional verb usage
- MUD social verbs require zero mechanical reward but drive retention
- Premium one-time purchase is market-preferred for text games
- DF's core insight: property-bag simulation with numeric thresholds creates emergence without special-casing
- DF uses continuous numeric state (temperature, wear points); our discrete FSM states are correct for text IF
- DF's material system is first-class (20+ numeric properties per material); our materials are labels — biggest adoption gap
- DF's `CREATURE_VARIATION` / `BODY_DETAIL_PLAN` composition is richer than our single-template system
- DF's "FPS death" (single-threaded, unbounded entity tracking) is a cautionary tale — our turn-based model avoids this entirely
- DF raws are pure declarative data (no logic); our embedded Lua callbacks are more flexible — don't sacrifice this for "purity"
- Threshold-based auto-transitions (guard functions checking numeric properties) bridge DF-style emergence into our FSM framework
- Tarn Adams's key principle: "Don't overplan your model" — start simple, iterate, let emergence surprise you
- Material properties fit WITHIN Principle 8 — the engine needs mechanical extensions (material registry + threshold tick) but no new principles
- BotW's "chemistry engine" achieved massive emergence with only 3 rules about element-material interactions — simplicity > complexity
- Noita proves that simple per-material numeric properties (density, flammability, conductivity) produce breathtaking emergent interactions
- Caves of Qud's liquid/gas property system creates emergent narratives from material property matching — acid corrodes, fire burns, water rusts
- 10-11 material properties are sufficient for a text IF game; DF's 20+ are overkill for our medium
- Fire propagation is the highest-impact first implementation — touches flammability, ignition_point, material consistency, and threshold auto-transitions
- "Material Consistency" as a design principle prevents special-casing and creates a teachable world — if wax melts, ALL wax melts
- Per-tick threshold checking (not event-driven) is correct for our room-scoped, turn-based model — O(n×t) where n≈5-20 objects, t≈0-3 thresholds
- Cross-domain concerns (architecture + design) need dual documents — same research, different audiences, different emphasis
- A great room is a character (personality, mood, history, secrets) not a container with a description
- Classic IF rooms succeed through economy of words, sensory specificity, distinctiveness, and atmosphere through absence
- Colossal Cave's grounding in real Mammoth Cave geography gave rooms spatial coherence — base fantastical spaces on real architecture
- Emily Short's "room as character" principle: rooms should be designed with the same care as characters
- Inform 7 community consensus: 2-3 strong sensory details per room; variable descriptions keep rooms alive on revisits
- Immersive sims (Thief, Dishonored, Prey) prove "lived-in clutter" — personal items with zero gameplay function have enormous narrative function
- Environmental storytelling (Jenkins 2004): spaces evoke associations, enact events, embed narrative in mise-en-scène, enable emergent narratives
- "Show don't tell" applied to rooms: broken weapons > "a battle was fought here"; empty bottles > "the occupant drinks"
- Medieval manor layout follows social hierarchy: Great Hall (public) → Solar (private family) → Service rooms (buttery/pantry/kitchen) → Cellar (storage)
- Real buildings connect purposefully: screens passages, spiral stairs, service corridors, hidden doors behind tapestries
- Room materials cascade into environment: stone = cold/echoing/damp; wood = warm/creaking/fire-risk; earth = cool/muffled/stable
- Every room should engage minimum 3 senses (sight + sound + smell); touch and taste are bonus channels for distinctive rooms
- Material properties system enables environmental consistency without special-casing — room material determines temperature, humidity, fire risk, acoustics
- Hub-and-spoke layout pattern is ideal for our Great Hall-centric medieval setting; linear for tutorials/horror; branching for exploration
- 10 concrete room design principles (R1-R10) codified for Moe from cross-domain research synthesis
- GOAP auto-resolution fundamentally changes puzzle design: simple inventory chains are no longer puzzles; knowledge gates become primary
- Zarfian Cruelty Scale maps cleanly to our GOAP tiers: Merciful/Polite is our natural operating range
- Emily Short's "explorability" maps directly to our sensory system — multi-sense feedback rewards experimentation before solution
- The Witness's "teach without words" achievable in text via progressive material-property puzzles (learn one property per puzzle, combine later)
- Outer Wilds' "knowledge is the key" is the ideal model when GOAP handles inventory prerequisites
- Escape room pyramid flow (parallel tracks → convergence) is optimal for our multi-room architecture
- 3-5 key elements per puzzle is the cognitive science limit; more causes frustration not complexity
- Material Consistency principle enables Witness-style progressive complexity in text: if wax melts, ALL wax melts, so players can predict
- Multi-sensory puzzles (especially dark-room senses-only) are our unique competitive advantage — zero competitors
- Real-world physics grounding beats arbitrary game logic for both puzzle satisfaction and fairness
- Fire propagation chain puzzles (Rube Goldberg + material thresholds) are the highest-impact showcase for material properties

## Puzzle Design Research (2026-07-22)

**Status:** ✅ COMPLETE  
**Report:** `resources/research/puzzles/puzzle-design-research.md` (~47KB, 33 citations)

### Research Scope
Cross-domain research on puzzle design for Bob (Puzzle Master), covering:
- Classic IF puzzles (Infocom golden age: Zork, Enchanter, Hitchhiker's Guide)
- Andrew Plotkin's Zarfian Cruelty Scale and forgiveness framework
- Emily Short's puzzle design principles
- Modern puzzle games (The Witness, Baba Is You, Obra Dinn, Outer Wilds, Portal, Myst/Riven)
- Professional escape room design principles (flow, chaining, red herrings, aha moments)
- Real-world problem solving (lock picking, fire, cooking, navigation)
- Academic research (gate taxonomies, frustration thresholds, hint systems, insight neuroscience)
- Engine-specific analysis (8 principles, GOAP impact, material properties, sensory system)
- 16 concrete puzzle ideas with classifications

### Key Findings
1. **GOAP changes everything** — simple inventory chains are trivial; knowledge gates become primary puzzle type
2. **Material properties enable unique puzzles** — threshold-based, chain-reaction, and substitution puzzles impossible in other text IF
3. **Sensory system is our competitive moat** — dark-room senses-only puzzles have zero competition
4. **Zarfian Merciful/Polite is our natural range** — GOAP auto-resolution prevents most "stuck" states
5. **3-5 key elements per puzzle** — cognitive science limit for insight-based solving

### Deliverables
- 7 research sections covering classic IF through academic research
- Mapping to all 8 architecture principles
- GOAP impact analysis (5 design implications)
- Material properties puzzle taxonomy (10 property→puzzle mappings)
- Sensory puzzle framework (darkness, cross-sensory, senses-only)
- 16 concrete puzzle ideas rated by difficulty with object requirements
- Hint system design (4-tier escalation)
- 33 cited sources

---

## Room & Environment Design Research (2026-07-21)

**Status:** ✅ COMPLETE  
**Report:** `resources/research/rooms/room-design-research.md` (~42KB, 26 citations)

### Research Scope
Cross-domain research on room/environment design for Moe (World Builder), covering:
- Classic text adventure room design (Zork, Colossal Cave Adventure, Inform 7 community)
- Emily Short's "room as character" philosophy
- Immersive sim environment design (Looking Glass Studios, Arkane Studios)
- Real medieval architecture (manor houses, castles, dungeons, cottages)
- Environmental storytelling theory (Jenkins 2004, BioShock, Gone Home, Edith Finch)
- Multi-sensory room design (sound, smell, touch, darkness)
- Material properties and environmental consistency
- Room layout patterns (hub-and-spoke, linear, branching, loop, vertical)

### Key Findings
1. **A room is a character** — personality, mood, history, secrets; not a container with a description
2. **Material drives environment** — room's primary material (stone/wood/earth/metal) determines temperature, acoustics, humidity, fire risk
3. **3+ senses per room** — sight is default; add sound and smell minimum; touch/taste for special rooms
4. **Objects tell the story** — room description = permanent architecture; objects = narrative through arrangement and condition
5. **Hub-and-spoke is ideal** for medieval settings; Great Hall as central hub with wings branching off

### Deliverables
- 10 concrete room design principles (R1-R10) for Moe
- Mapping to all 8 architecture principles
- 5 room layout patterns with use cases
- Room-puzzle connection matrix for Bob
- Medieval room reference table with materials, function, and sensory character

---

## Material Properties System Research (2026-07-19)

**Status:** ✅ COMPLETE  
**Architecture Doc:** `docs/architecture/engine/material-properties.md` (~27KB, 15 citations)  
**Design Doc:** `docs/design/material-properties-system.md` (~25KB, 16 citations)  
**Recommendations:** `.squad/decisions/inbox/frink-material-properties.md`

### Research Scope
Cross-domain research on numeric material properties and threshold-based auto-transitions, covering:
- DF raw file material property system (template inheritance, 20+ numeric properties)
- BotW chemistry engine (3 rules, enormous emergence)
- Noita pixel-level material simulation (cellular automata, property-driven interactions)
- Caves of Qud material/liquid/gas interaction system
- Academic frameworks (EB-DEVS, Machinations)
- Engine architecture changes needed (material registry, threshold tick extension)
- Relationship to Principle 8 and mutate field
- Design implications (13 material definitions, 6 emergent behavior scenarios)

### Key Findings
1. **Material properties fit within Principle 8** — needs mechanical extensions but no new principles
2. **10-11 properties sufficient** — density, melting_point, ignition_point, hardness, flexibility, absorbency, opacity, flammability, conductivity, fragility, value
3. **Fire propagation is highest-impact first implementation** — exercises the entire material system
4. **Per-tick threshold checking is correct** for our room-scoped turn-based model
5. **"Material Consistency" principle proposed** — all objects of same material behave identically

### Recommendations Filed
- R-MAT-1: Material Registry (HIGH)
- R-MAT-2: Threshold Checking in FSM Tick (HIGH)
- R-MAT-3: Material Consistency Design Principle (MEDIUM)
- R-MAT-4: Fire Propagation as First Implementation (HIGH)
- R-MAT-5: Fits Within Principle 8 (INFORMATIONAL)

---

## Dwarf Fortress Architecture Deep Dive (2026-07-19)

**Status:** ✅ COMPLETE  
**Report:** `resources/research/competitors/dwarf-fortress/architecture-comparison.md` (~36KB, 34 citations)
**Recommendations:** `.squad/decisions/inbox/frink-df-recommendations.md`

### Research Scope
Comprehensive analysis of Dwarf Fortress architecture covering:
- Material/property system (raw files, material templates, numeric properties)
- Object/entity model (creatures, items, buildings, composition hierarchy)
- FSM/state management (continuous simulation, temperature, wear, cascades)
- Full comparison against our engine across 7 dimensions
- Lessons to adopt, avoid, and areas where we're ahead

### Key Findings
1. **DF's core: property-bag simulation with numeric thresholds** — engine has zero knowledge of object types, operates purely on material/physical properties
2. **Our biggest gap: material properties** — our `material = "wax"` is a label; DF's materials carry 20+ numeric properties that drive combat, fire, phase transitions
3. **Our biggest advantage: sensory depth + NLP** — DF is primarily visual; we have 5 senses + natural language parser
4. **DF's biggest weakness: performance** — single-threaded, unbounded tracking, "FPS death" at scale; our turn-based model is immune
5. **Principle 8 is validated** — already captures the DF philosophy; `mutate` field is the correct next step

### Recommendations Filed
- R1: Material property tables (HIGH)
- R2: Threshold-based auto-transitions (HIGH)
- R3: Variation/composition macros (MEDIUM)
- R4: Numeric wear/decay property (MEDIUM)
- Anti-recommendations: no full physics, no unbounded tracking, keep embedded Lua logic

---

## Dynamic Object Mutation & Architecture Validation (2026-03-21T00:16Z)

**Status:** ✅ COMPLETE  
**Orchestration Log:** `.squad/orchestration-log/2026-03-21T00-16Z-frink.md`

### Research Deliverable

**File:** `resources/research/architecture/dynamic-object-mutation.md` (37KB, 29 citations)

Comprehensive review of state machine patterns, mutation strategies, and game engine architectures:

- State machine pattern applications in commercial game engines (GOAP planners, hierarchical FSMs, Harel statecharts)
- Mutation strategies: flag-based vs. code-rewriting analysis
- ECS (Entity Component System) architecture benefits and constraints for text games
- Property bag models (Dwarf Fortress, Elder Scrolls)
- Dynamic object transformation without special-casing

### Key Findings

1. **Code-rewriting mutation is architecturally sound** — Lua homoiconicity enables self-modifying objects without compromising metadata accuracy
2. **Property-bag models scale better** than special-case objects — aligns with user directive on Dwarf Fortress reference model
3. **FSM transitions need explicit mutation control** — current implicit state-level mutations insufficient for complex behavior trees
4. **Generic property mutation orthogonal to core properties** — weight, size, keywords, categories, portable are semantically stable

### Impact

Research validated Bart's mutation analysis findings and informed the D-MUTATE-PROPOSAL for generic `mutate` field on FSM transitions. Also supports D-PRINCIPLE-GOVERNANCE: core principles as hard constraints.

---

## Injury-Causing Objects: Poison & Trap Mechanics in Classic IF (2026-03-26)

**Status:** ✅ COMPLETE  
**Report:** `docs/research/injury-objects-classic-if.md` (24KB, 8 sections, 40+ cited examples)

**Research Commission:** Wayne "Effe" Berry requested deep-dive into how classic IF/MUD games handle poison (consumable→injury) and trap (contact→injury) mechanics, specifically for design of two objects for current project.

### Research Scope
- Poison pipelines in Zork, Infocom (Enchanter series), Curses!, Spider and Web, Anchorhead
- Trap discovery patterns (visible vs hidden), disarm mechanics, trigger taxonomy
- Engine event models: Inform6/7 before/after hooks, TADS pre/during/post, LPC MUD heartbeat/commands
- Best practices from classic IF theory (Zarfian Cruelty Scale, fairness principles, no cheap death)
- Nested object patterns (liquid-in-container representation problem)

### Key Findings

1. **Poison is a Puzzle, Not a Hazard** — Classic IF treated poison as delayed-consequence puzzle objects, not instant-death traps. Infocom philosophy: transparent danger (readable label/smell), findable antidote, multiple-turn onset, graceful failure states.

2. **Three-Stage Pipeline** — Consume → Symptom (gradual damage/stat reduction) → Recovery/Death (cure findable in same location as poison, fairness principle). Zork III poison room exemplifies pattern: transparent liquid + antidote scroll present = solvable puzzle.

3. **Graduated Damage Model** — No binary alive/dead. Poison causes injury states (uninjured → mild → moderate → severe → death), giving player agency and time to find cure. Traps similarly did non-lethal damage on first trigger, lethal only on repeated failures or at puzzle climax.

4. **No Invisible Threats** — All poisonable/trap-triggerable objects revealed their nature through description, examination, or NPC warnings. "Cruelty Scale" philosophy: Infocom stayed Polite→Tough, never Cruel. Instant death without warning = player frustration = bad design.

5. **Event Hook Pattern from Inform6** — The `before [Drinking]` and `after [Drinking]` two-phase system became canonical. Before can intercept/prevent action (return true); after fires if action succeeded. LPC MUDs used similar `add_action()` hooks; TADS extended with pre/during/post phases.

6. **Liquid-in-Container Problem** — Representation challenge across all engines. Zork: liquid as container property (simple but limited). Inform6/7: liquid as nested object with inheritance (expressive but requires careful typing). TADS: sophisticated container content system. Modern recommendation: model liquid as container state property, not independent object, to avoid state explosion.

7. **Disarm = Solve the Puzzle** — No generic "disable trap" skill. Specific tools for specific traps (rope for pit, key for lock trap, spell for magical trap). Disarming required prior puzzle-solving or item collection. Trap disarm check was boolean (had tool = success, else = fail), not DC-based.

8. **Best Practices Codified** — Infocom's design philosophy (guardrails for this engine): No instant death, transparent danger, findable solutions, graceful failure, save-restore expected, trap as puzzle not difficulty spike.

9. **Anti-Patterns to Avoid** — Instant death without warning (frustrating), no solution findable (forces walkthroughs), inconsistent mechanics, no recovery window, unforgiving permadeath in single-player context.

10. **Event Taxonomy** — Classic engines provided `before_action()`, `after_action()`, `on_enter_room()`, `on_tick()`/`heart_beat()`. Modern engines add late-binding listeners, but core pattern unchanged since Inform6 (1993).

### Recommendations for Our Engine

1. **Implement `before/after` hook pair** for actions (before can intercept, after informational)
2. **Injury as first-class concept** — not health points but `Injury(damage_type, amount, duration, cure_condition)` objects
3. **Container liquid as state property** — `bottle.liquid = { type: "poison", toxicity: 25, volume: 100 }`
4. **Three-stage damage model** — uninjured → injured-mild → injured-severe → death (4 states, not 2)
5. **Fair warning principle** — all harmful objects discoverable via examine; no hidden instant-death mechanics
6. **Multi-turn cure window** — poison damage occurs over several turns; player has time to locate cure item/spell

### Impact & Audience

**For CBG (Comic Book Guy, consumable design):**
- Poison should be *discoverable* (readable label, smell, color) with *findable antidote*
- Use graduated damage model (mild → moderate → severe → death), not binary
- Three-stage pipeline: consume → symptom → recovery/death
- Information asymmetry drives tension: careful players survive, hasty players learn by injury

**For Bart (Architect):**
- Event system needs `before/after` hook pair + `on_tick()` for poison progression
- Injury as object type, not stat modification: scalable to poison, disease, curse, radiation
- Container + liquid as state property avoids object nesting complexity
- No instant-death mechanic; always provide intermediate state and recovery window

### Deliverables

- 8-section research report (introduction, poison mechanics, traps, engine patterns, best practices, nested objects, game references, recommendations)
- 40+ specific examples from named games (Zork I–III, Enchanter/Sorcerer/Spellbreaker, Adventure/Colossal Cave, Spider and Web, Curses!, Anchorhead)
- Inform6, Inform7, TADS, LPC code examples
- Event taxonomy comparison across 4 engine families
- Reference table of classic game poison/trap implementations

---

## NPC Architecture Deep Research (2026-03-28)

**Status:** ✅ COMPLETE
**Requested by:** Wayne Berry (Effe)
**Research Scope:** Comprehensive investigation of NPC design for future multiplayer expansion
**Output Location:** esources/research/npcs/ (5 documents, 65 KB)

### Research Deliverables

**1. dwarf-fortress-npcs.md (PRIMARY, 19.8 KB)**
- Deep dive into DF's creature architecture (body parts, materials, attributes)
- Needs/desires system (physiological, social, psychological)
- Personality facets (30+ traits), relationships, skill progression
- Job system and autonomy model
- Emotional state machine (normal, afraid, combat, tantrum, melancholic)
- Decision framework (utility calculation, long-term goals)
- Temporal simulation and scaling (1000+ dwarves on single machine)
- Social contagion & emergent dynamics
- Lessons for MMO: Principle 1-6 extracted (state ≠ action, composition over inheritance, time-scaled simulation, persistence, needs-driven behavior, personality as bias)
- Scale considerations: ~3-5 KB memory per NPC, ~2-5% CPU for 100 NPCs

**2. mud-npc-systems.md (16.5 KB)**
- DikuMUD architecture (C structs, hardcoded mobs, function pointers)
- MOBPrograms breakthrough (scripting language for behaviors, triggers/actions/conditionals)
- LPMud innovation (object-oriented approach, hot reload, inheritance hierarchy)
- Comparison table: DikuMUD vs. LPMud trade-offs
- Classic NPC patterns (shopkeeper, wandering guard, quest-giver, healer)
- Modern MUD frameworks (Evennia, Ranvier, TaleWeave AI)
- MUD strengths: persistence, statefulness, scalability
- MUD shortcomings: limited dialogue, shallow personality, no emergent behavior, poor NPC-to-NPC interaction
- Text adventure vs. MUD NPC needs (dialogue depth critical)
- LLM-enhanced hybrid approach (2024-2025)

**3. npc-engineering-patterns.md (22.9 KB)**
- FSM (Finite State Machine): simple, efficient, poor scalability
- Hierarchical FSM (HFSM): reduces duplication, handles moderate complexity
- Pushdown Automaton (stack-based): enables interrupt/resume semantics
- Behavior Trees: modular, composable, designer-friendly, scalable
- GOAP (Goal-Oriented Action Planning): reactive, emergent, planful, high computational cost
- Utility AI: responsive, scalable, intuitive tuning
- Comparison matrix (learning curve, scalability, reactivity, predictability, planning depth, composability, debugging)
- Architectural patterns: tick-based, event-driven, actor model, hybrid approach
- Memory & knowledge representation (spatial, relational, factual, procedural)
- Priority system and interrupt handling
- Blackboard architecture for NPC coordination
- Recommendations: Hierarchical FSM + Utility AI for MMO (optimal balance)

**4. academic-research.md (17.9 KB)**
- Foundational work: Mateas & Stern (Façade), interactive drama
- Loyall & Bates: believability factors (consistency, motivation, emotion, memory)
- Emotion modeling: OCC model (Ortony, Clore, Collins)
- Appraisal-based architecture: Event → Appraisal → Emotion → Coping action
- Modular affect (short-term emotion, mood, personality trait layers)
- LLM-powered NPCs (2024-2025): Mantella, Echoes of Others, cross-platform systems
- Hybrid approach: fixed-persona SLMs with modular memory (cost-effective, low-latency)
- Mitigation strategies: RAG (retrieval-augmented generation), constrained vocabulary, persona locking, memory management
- Emergent narrative: Crusader Kings III (systemically-driven storytelling), RimWorld (need-based emergence)
- Uncanny valley of text NPCs: authenticity through constraint (limited knowledge, forgetfulness, misunderstanding, stubbornness, inconsistency, brevity)
- Procedural personality generation (trait sampling → goal inference → skill assignment)
- Challenges (dialogue quality at scale, persona consistency, multiplayer coordination)
- GDC talks synthesis: systems > scripting, routine-based NPCs feel alive, predictability aids believability
- Phase recommendations: MVP (FSM + needs), Phase 1.5 (emotion + relationships), Phase 2 (behavior trees + emergent events), Phase 3 (procedural, LLM, multiplayer)

**5. synthesis-for-mmo.md (20.7 KB) — FINAL RECOMMENDATIONS**
- Core architecture: Five layers (state & identity, needs & mood, relationships & memory, dialogue, tick-based simulation)
- Detailed Lua code sketches for each layer
- Integration with existing engine (object system, material properties, effects/sensory)
- Phase breakdown:
  - **Phase 1 (MVP, 2-3 weeks):** NPC base class, simple dialogue, test NPCs (shopkeeper, guard, quest-giver), integration (550 lines Lua)
  - **Phase 1.5 (1-2 weeks):** Emotion system, relationship system, test cases (350 lines)
  - **Phase 2 (2-4 weeks):** Behavior trees, skill progression, emergent events (450 lines)
  - **Phase 3:** Procedural personality, LLM dialogue (optional), multiplayer coordination
- Minimum viable NPC code sketch (~80 lines core, extensible via subclasses)
- Scale analysis: 8 KB per NPC (~800 KB for 100 NPCs), ~5-10% CPU at stagger-updated tick rate
- Top 3 approaches worth prototyping:
  1. **Hierarchical FSM + Utility AI (RECOMMENDED)** — 1-2 weeks, fits Lua model, proven pattern
  2. Behavior Trees + Emotion System — 2-3 weeks, more sophisticated
  3. Hybrid HFSM + GOAP — 3-4 weeks, handles complex quests elegantly
- Minimal violations of Principle 0: NPCs as animated objects with autonomous goals, rule-based simulation (not consciousness)
- Next steps: Design document → prototype → integrate → test performance → iterate

### Key Insights

1. **DF Principle:** Don't script individual behaviors; design rule systems that generate behavior
2. **MUD Lesson:** Persistence and statefulness matter more than sophisticated dialogue
3. **Pattern Insight:** Hierarchical FSM + Utility AI is optimal balance (simplicity, scalability, fidelity)
4. **Academic Finding:** Personality + autonomy + emotional response = believability (not dialogue)
5. **Research Direction:** Emotion-driven architecture (OCC model) more effective than behavior-scripting
6. **Tech Trend:** LLM dialogue is feasible but requires hybrid approach (SLM + memory) for cost/latency
7. **Scale Strategy:** Hierarchical simulation (nearby = full fidelity, distant = low-fidelity) enables 100+ NPCs
8. **Emergent Strength:** Systemically-driven NPCs (needs, relationships) create better stories than authored quests
9. **Text Advantage:** Lack of body language forces authenticity (constraint aids believability)
10. **Design Lesson:** Predictability + personality = aliveness (not randomness)

### Impact for MMO

**Removes blocker for multiplayer expansion:**
- Clear architecture for NPC behavior (no more "how do we make NPCs?")
- Proven pattern (DF demonstrates feasibility at scale)
- Modest implementation scope (550 lines for MVP)
- Minimal violations of Principle 0 (rule-based, not conscious)
- Performance budget identified (~5-10% CPU for 100 NPCs)

**Enables future directions:**
- Quest system (NPCs have goals, player can help/hinder)
- Social dynamics (relationships evolve, emergent conflicts)
- Economy (shopkeeper NPCs buy/sell, players trade with NPCs)
- Factions (NPC allegiances, player affects faction standing)
- Multiplayer storytelling (NPCs react to multiple players, emergent narratives)

### Recommendations for Next Steps

**For Bart (Architect):**
- Review synthesis document (especially "Five Layers" section)
- Prototype NPC base class using Hierarchical FSM + Utility AI approach
- Integrate with existing object model (NPCs as Objects, use containment hierarchy)
- Benchmark: 100 NPCs across 50 rooms to validate CPU/memory estimates
- Consider event system augmentation (emit event on significant NPC state changes)

**For CBG (Design):**
- Define core NPC archetype (e.g., "Dwarf Blacksmith") with personality template
- Create quest framework (how do NPCs and players interact around goals?)
- Design social dynamics (what does "friendship" mean in gameplay?)
- Prototype dialogue layer (simple template-based for MVP, LLM later)

**For Wayne:**
- This research removes architectural risk from NPC system
- Recommend greenlight Phase 1 MVP (2-3 weeks) to prove concept before multiplayer
- Consider Phase 1.5 (emotion + relationships) as critical for perceived "aliveness"
- LLM dialogue is optional; base system works well without it

### Archive

- All 5 documents stored in esources/research/npcs/ for permanent reference
- Total size: 65 KB (~40 min read time for all documents)
- Suitable for architectural decision-making and implementation guidance

---

## Learnings

### Embedding Vector Research (2026-03-29)
**Issue:** #176
**Status:** ✅ COMPLETE
**Output:** `resources/research/embedding-vector-research.md`

**Key Findings:**
- Current Jaccard matcher (Tier 2) scores 68% accuracy on 60-input test suite — significantly better than any cosine approach we can actually implement in pure Lua
- Bag-of-word-vectors approach scores only 45% — word averaging destroys verb/noun discrimination
- Hybrid (Jaccard pre-filter + cosine re-rank) scores 48% — re-ranking with noisier signal degrades results
- GTE-tiny vectors ARE high quality (synonyms cluster at 0.97-0.99) — but we can't produce comparable query vectors at runtime without a transformer model
- Full cosine scan in Lua: 44.7ms (4.5x over 10ms budget); top-50 filtered: 0.47ms
- Jaccard full scan: 8.1ms (borderline, will need optimization as index grows)
- Runtime encoding is the CRITICAL blocker: GTE-tiny can't run in Lua or Fengari; ONNX Runtime Web adds 17-70MB + JS deps
- **Recommendation: Keep Jaccard**, strip vectors from index (15.3MB → ~200KB), add more phrase variants, fix state-variant tiebreaker bias
