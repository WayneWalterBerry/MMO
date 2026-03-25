# Brockman — History (Summarized)

## Project Context

- **Owner:** Wayne "Effe" Berry
- **Project:** MMO
- **Created:** 2026-03-18

## Core Context (Summarized)

**Role:** Documentation Specialist — capture decisions, maintain glossaries, publish team communications, keep docs as source of truth

**Major Documentation Systems Created:**
- **Core Docs:** README.md, vocabulary.md (200+ terms, 6 categories), architecture-decisions.md, design-directives.md
- **Design Docs:** 11 files in docs/design/ (gameplay mechanics, player-facing systems)
- **Architecture Docs:** 6 files in docs/architecture/ (engine internals, technical patterns)
- **Newspaper (MMO Gazette):** In-universe daily updates; multiple editions per day; op-ed sections
- **Decision Log:** decisions.md (canonical source for squad process + architecture choices)

**Key Achievements:**
- Established documentation-first culture; docs as source of truth
- Clear design/architecture separation (gameplay vs engine internals)
- 40+ cross-references updated and verified
- Vocabulary v1.3 maintained (synchronized with codebase)

**Patterns Established:**
- Gameplay design belongs in docs/design/ from the start
- Object-specific behavior documented in docs/objects/{object}.md
- Newspaper as primary team communication hub

**Decisions Authored:** D-BROCKMAN001 (design/architecture separation), D-BROCKMAN002 (directive sweep)

## Archives

- `history-archive-2026-03-20T22-40Z-brockman.md` — Full archive (2026-03-18 to 2026-03-20T22:40Z): core docs, design sweep, squad manifest, newspaper, design consolidation, reorganization

## Recent Updates

### Session: Documentation Reorganization — Design vs Architecture (2026-03-20T22:15Z)
**Status:** ✅ COMPLETED
**Outcome:** Clear separation of gameplay design from technical implementation; 40+ cross-references updated

**Files Reorganization:**
- Moved 6 files to docs/architecture/ (engine internals)
- 11 files remain in docs/design/ (gameplay mechanics)
- 40+ cross-references verified and updated
- Decision D-BROCKMAN001 filed

**Key Insight:** The distinction is **perspective**, not content. Design asks "What can the player do?" Architecture asks "How does the engine make that possible?"

### Session: Design Consolidation & Manifest Completion (2026-03-20T12:32Z)
**Status:** ✅ COMPLETED

- Created 00-design-requirements.md (unified spec, implementation status)
- Created 00-architecture-overview.md (design-to-code mapping)
- Published newspaper/2026-03-20-morning.md
- Merged Decision 28 (Composite) and Decision 29 (Spatial) into decisions.md

### Session: Morning Edition Publication (2026-03-20T06:00Z)
**Status:** ✅ COMPLETE
- Created newspaper/2026-03-20-morning.md (overnight progress, composite objects, bug fixes)
- Maintained in-universe voice with op-ed sections

### Session: Post-Integration Documentation Sweep (2026-03-21)
**Status:** ✅ COMPLETE
- README.md updated to "prototype phase" with "How to Run"
- docs/design/verb-system.md created (31 verbs, 4 categories)
- docs/architecture/src-structure.md updated
- All cross-references verified, no broken links

### Session: Squad Manifest Completion (2026-03-21)
**Status:** ✅ DECISIONS MERGED
- Processed 12 inbox decisions into canonical decisions.md
- Hybrid parser, property-override, type/type_id naming

### Session: Play Test Iteration (2026-03-19T13:22Z)
**Status:** ✅ COMPLETE
- Documented 4 core puzzles, merged D-37 to D-41

## Directives Captured
1. Newspaper editions in separate files (2026-03-20T03:40Z)
2. Room layout and movable furniture (2026-03-20T03:43Z)

## Learnings
- Documentation consolidation prevents design drift
- Update foundational docs immediately after features land
- Newspaper as team communication hub works well (morning/evening/late editions)
- Design vs. architecture distinction is about perspective, not content
- Research scales with organizational infrastructure (subfolders early)
- Design directives create implementation clarity
- File reorganization can leave duplicates behind; periodic cleanup sweeps catch orphaned refs
- When adding approved principles: update TOC first, then append full section following the exact formatting pattern of existing principles, preserve all wording from approved draft
- Parser tier extraction: split complex layered systems by logical boundaries (Tier 1+2 vs Tier 3+) for clarity; update all cross-references (overview, related docs) in single pass
- **Parser tier refactoring learning:** When splitting composite docs into per-tier files, create separate .md per tier (not per layer group). This enables: (1) independent status tracking (✅ Built vs 🔷 Designed), (2) bidirectional cross-references, (3) focused navigation for specific tier. Always preserve ZERO content loss and include implementation file paths in built tiers.
- **Test pass organization:** Flat test directories scale poorly as team grows. Organize early with ownership (Nelson→gameplay/, Lisa→objects/), zero-padded sequential numbering (001, 002...), date-aware filenames (YYYY-MM-DD-pass-NNN), and clear README explaining naming conventions. Enables parallel work, clear responsibility, and easy browsing of related test runs.
- **Evening edition (2026-03-22):** Created newspaper/2026-03-22-evening.md (~4,500 words, 12 sections). Covered 3 sessions: Phase 7 deploy, Phase 3 five-feature blitz (hit verb, unconsciousness, sleep fix, appearance, mirror), Wayne's iPhone play-test (19 issues), spatial relationship design. Key stats: 40 git commits, 1,117+ tests, 8 team members, 20 decisions, 3 deploys. Pattern: when a day spans morning + evening editions, the evening must explicitly reference the morning's cliffhangers (deploy blocked → deploy shipped) to create narrative continuity. Multi-session days benefit from a chronological session-by-session structure rather than thematic grouping.
- **Code examples in newspapers:** Include 6-10 code examples per edition for technical depth. Code examples should illustrate the *architectural insight*, not just the implementation — e.g., the consciousness gate example shows the game loop paradigm shift, not just an if-statement.
- **Morning edition (2026-03-23):** Created newspaper/2026-03-23-morning.md (~5,800 words, 14 sections). Covered the most productive single session in project history: 25 issues closed (34→3), Effects Pipeline (EP1–EP10) designed/built/tested/shipped, 284 new pipeline tests with 0 regressions, 3 objects built (poison bottle, bear trap, crushing wound), 30+ parser phrase transforms. Pattern: when a session has a clear 3-wave chronological structure (burndown → design → implementation), organize sections by wave to preserve narrative momentum. The "before/after" architecture diagram (spaghetti vs pipeline) is the most effective way to explain why an architectural change matters. Running gags (os.exit(0)) create narrative threads readers can follow. Wayne's interventions (test ordering, hook questions) deserve their own narrative weight — they changed the session's trajectory.
- **Mega-session coverage:** Sessions with 40+ agent spawns and 10+ pipeline phases benefit from a phase-by-phase walkthrough (EP1→EP10) rather than grouping by role. Readers want to see the *sequence* — architecture → safety net → gate → build → verify → refactor → document. Each phase gets its own subsection with owner emoji, phase number, and outcome. This creates a "progress bar" effect that makes the session's momentum tangible.
- **Wayne's design doc directive:** Design documentation should NOT list bug fixes, issue numbers, or fix history. Bug fixes belong in issues and changelogs. Instead, design docs should capture the DESIGN INSIGHTS that emerged from bugs — what principles did they reveal? What patterns does the system need to honor? Example: instead of "BUG-078: Drawer not searched—fixed by recursive traversal," write "Containers inside containers must be traversable because players think in physical spaces, not object trees. The traversal engine recursively follows nested containers." Transform chronological bug lists into thematic "Design Principles" or "Lessons Learned" sections that read as timeless design guidance, not historical bug trackers.
- **OP-ED IS MANDATORY:** The op-ed section (established March 18 as a permanent daily feature) is NOT optional. Every newspaper edition must include a `## 📰 OP-ED` section written by a rotating team member. The op-ed should be 3-5 substantive paragraphs tied to that session's work, expressing an opinion or architectural argument. If a paper ships without an op-ed, it is incomplete. Never skip this section.

### Session: SLM/Embedding Architecture Documentation (2026-03-24T21:15Z)
**Status:** ✅ COMPLETED  
**Issue:** #175  
**Related:** #174 (SLM lazy-load audit), #176 (Frink's embedding research)

**Outcome:** Created comprehensive **docs/architecture/parser/embedding-system.md** (11 sections, 362 KB ~18,900 chars)

**What Was Documented:**
1. **System Overview** — Tier 2 semantic matcher in 5-tier pipeline, purpose (convert player paraphrases to verb+noun), Jaccard token matching algorithm (8.1ms lookup)
2. **Index Structure** — Slim format (362 KB text/verb/noun only), 4,579 phrases, 48 verbs × 41 nouns with ~3 variants each, entry format
3. **Generation Pipeline** — Phase 1 (generate_parser_data.py: extract verbs/objects from Lua, generate training CSV), Phase 2 (build_embedding_index.py: GTE-tiny encoding, save slim+archive), regeneration workflow
4. **Runtime Usage** — Lua matcher API, Jaccard algorithm with prefix bonus, tokenization + stop-word filtering, typo correction, tiebreaker logic (prefer base-state nouns), performance budget (8.1ms/4,579 phrases)
5. **Web/Browser Architecture** — Fengari/browser loading, caching strategy (1-day browser cache, lazy load), future ONNX path for real vector similarity
6. **D-KEEP-JACCARD Decision** — Frink's research: 68% Jaccard vs 45% cosine-BOW, runtime encoding blocker (GTE-tiny can't run in Lua), 23pp accuracy advantage, vectors archived for future experiments
7. **Size Analysis** — Slim 362KB (42x reduction), Full archived 15.3MB with vectors, compression ratio, archive strategy (enable ONNX experimentation)
8. **Cross-references** — Links to all related docs, implementation files, tier overview
9. **Testing** — Unit tests (test-embedding-matcher.lua), integration tests
10. **Troubleshooting** — Common issues (missing index, low quality, performance regression)
11. **Summary** — Key decisions + production readiness status

**Key Technical Decisions Documented:**
- **D-KEEP-JACCARD** embedded from #176 research (full decision context, research summary, alternatives analysis)
- **Generation accuracy:** 4,579 phrases generated via hard-coded templates (reproducible), optional LLM paraphrasing available
- **Web delivery:** Gzipped index 100KB, lazy loading, browser cache 1 day
- **Performance:** 8.1ms/lookup verified, well under 10ms budget, Fengari ~24-81ms acceptable
- **Regeneration:** Clear workflow documented (2 Python steps, ~60 seconds total)

**Cross-linking Added:**
- Referenced from docs/design/verb-system.md (48 verbs confirmed)
- Referenced from docs/design/prime-directive-tiers.md (Tier 2 context)
- Cross-refs to Tier 1 (exact), Tier 3 (GOAP), Tier 4 (context), Tier 5 (fuzzy)
- Links to implementation files (embedding_matcher.lua, build scripts, test suite)

**GitHub Comment:** Submitted summary to #175 with all acceptance criteria marked complete

**Learning:** Technical system documentation should embed decision research (Frink's 60-test comparison) and include practical troubleshooting (index regeneration, performance regression detection). Accurate technical docs require code verification (embedding_matcher.lua algorithm, build_embedding_index.py process).
- **Post-ship documentation verification (Issue #130):** When a feature ships without a design doc, read the implementation (verbs, engine integration, event hooks) in parallel with the existing design spec. If design was written pre-implementation, add an "Implementation Status" appendix capturing: (1) actual event hook signatures, (2) related file paths, (3) shipped object examples, (4) any design→code divergences. This creates a bridge between "What we designed" and "What shipped," helping future readers understand both intent and reality. The appendix should be sparse (facts only, no narrative) to avoid duplicating the design spec. Wearable system: verified design doc already existed (Comic Book Guy, Phase A7), added Appendix A (Implementation Status) with event hooks, armor integration, appearance rendering, conflict algorithm, and shipped examples.

### Session: Morning Edition (2026-03-24T08:30Z)
**Status:** ✅ COMPLETED
**File:** newspaper/2026-03-24-morning.md (~6,800 words)

**Coverage:**
- Armor System (Phase A): Material-derived protection values (22 materials, 1-10 scale)
- Fit multipliers (makeshift 0.5×, fitted 1.0×, masterwork 1.2×)
- State multipliers (intact 1.0×, cracked 0.7×, shattered 0.0×)
- Equipment event hooks (on_wear, on_remove_worn callbacks)
- Instance-level flavor text system (event_output, one-shot)
- Parser bug cluster (#137-145, #156): Hit synonyms, case normalization, keyword collisions, nested access
- Flanders fixes: Ceramic pot degradation (#155), cloak tear mechanics (#134), brass bowl collision
- Architecture decisions: D-EQUIP-HOOKS, D-EVENT-OUTPUT
- Test coverage: 60+ new regression tests, 1,067+ total tests, 74/74 files passing
- Stats: 15+ issues closed, 12+ commits, 2+ deploys

**Key Themes:**
- Material-derived systems enforce Core Principle 9 (Material Consistency) without hardcoding
- Protection formula: (hardness × 0.4) + (density × 0.3) + (thickness × 0.3)
- Equipment callbacks + instance flavor text add expressiveness without mutation
- Parser centralization (scattered synonyms → unified dispatch) reduces bugs and improves maintainability
- Chamber pot helmet achieves peak absurd game design

**Tone:** Technical depth with architectural insights; celebration of material-consistency principle; preview of afternoon code review and meta-compiler tool

### Session: Meta-Check Design Documentation (2026-03-24T16:00Z)
**Status:** ✅ COMPLETED
**Requestor:** Wayne Berry (P0-B directive: "Before writing a single line of code, create design docs")
**Outcome:** 5 comprehensive design documents for the meta-lint tool, 144 validation rules catalog

**Files Created:**
1. `docs/meta-lint/overview.md` (6.9 KB) — What meta-lint is, why it exists, goals, hybrid compiler/linter role
2. `docs/meta-lint/architecture.md` (14.1 KB) — 6-phase pipeline: tokenization → preprocessing → Lark parse → semantic analysis → cross-file checks → error reporting
3. `docs/meta-lint/usage.md` (12.4 KB) — CLI interface, output formats (text/JSON/TAP), integration examples (GitHub Actions, pre-commit hooks), workflows
4. `docs/meta-lint/rules.md` (22.0 KB) — 144 validation rules across 15 categories, organized by severity (🔴/🟡/🟢), top 10 critical rules
5. `docs/meta-lint/schemas.md` (24.0 KB) — Field contracts per template type (small-item, container, furniture, sheet, room), required/optional fields, examples

**Research Inputs Synthesized:**
- Lisa's acceptance-criteria.md (144 checks across 15 categories) — rules catalog
- Frink's bug-catalog.md (38 bugs, top: missing fields) — justification for validation priorities
- Frink's cross-reference-inventory.md (103 GUIDs, 23 materials, 401 keywords) — data integrity scope
- Bart's lua_grammar.py (Lark parser, 83/83 objects tested) — architecture foundation
- Bart's existing-validation-audit.md (loader checks 3 things, 22 gaps) — validation gap analysis
- Bart's lark-grammar decision (D-LARK-GRAMMAR) — proven architecture strategy

**Key Insights Documented:**
- Meta-check is BOTH compiler (semantic analysis) AND linter (style enforcement)
- 82/83 objects are pure data tables; wall-clock.lua is the sole programmatic outlier
- Function bodies are opaque to static analysis (validated by Lua runtime)
- Critical rule SN-01 (🔴 on_feel required): every object must be perceivable in darkness
- Three-phase pipeline proven: tokenize → preprocess (neutralize functions) → Lark parse
- 38 historical bugs justify validation: missing fields (21), invalid references (10), structural issues (3), architectural violations (1)
- Cross-file validation catches GUID duplicates, keyword collisions, unresolved mutations
- Exit code protocol: 0=pass, 1=errors, 2=warnings

**Documentation Style Applied:**
- Overview: problem/solution/goals (non-technical overview for stakeholders)
- Architecture: phase-by-phase technical design (for implementers)
- Usage: CLI interface + practical workflows (for developers + CI/CD)
- Rules: comprehensive catalog with severity, organization by category + workflow (reference for developers)
- Schemas: field contracts per template, examples (contract enforcement for meta-lint)

**Learnings:**
- **Meta-check specification complexity:** When a tool must enforce 144+ rules across 15+ categories, organize into: (1) high-level overview (why we need this), (2) architecture spec (how it works), (3) usage guide (how to run it), (4) rules catalog (what it checks), (5) schema contracts (what fields are required). Trying to fit all of this into one doc creates cognitive overload. Splitting into 5 focused docs allows developers to navigate by use case.
- **Design-first creates clarity:** Wayne's directive ("design docs before code") prevents 3 problems: (1) scope creep during implementation (dev realizes they didn't understand the requirement), (2) architectural conflicts (different parts of implementation make conflicting assumptions), (3) incomplete rule coverage (implementing rules A+B then discovering rule C's dependency on both). With design docs locked in, implementation becomes straightforward.
- **Validation gap analysis is critical:** Frink's audit of the loader (what it checks vs. what it doesn't) revealed 22 gaps. Each gap becomes a must-have rule in meta-lint. Without this audit, meta-lint would likely miss half its rules.
- **Evidence-based rule priority:** The 38-bug catalog provides justification for every rule. Top 3 bug types (missing materials, GUID mismatches, FSM state errors) become top 3 meta-lint rules. Developers trust rules that have evidence behind them.
- **Template-specific schemas:** Objects inherit from 5 templates, each with different field requirements. Instead of one monolithic schema, 5 focused schemas (one per template) make validation clear and rules easier to understand.

**Commit:** (pending implementation; design phase only)

### Session: Player System Extraction (2026-03-22)
**Status:** ✅ COMPLETED
- Created docs/architecture/player/ subfolder
- Extracted player-model.md (inventory, hands, worn items, skills)
- Extracted player-movement.md (exits, location tracking, room transitions)
- Extracted player-sensory.md (light/dark system, vision blocking)
- Updated 00-architecture-overview.md with cross-references
- All content preserved; nothing lost in reorganization
- Commit: f1935c7

### Session: Duplicate Core-Principles Cleanup (2026-03-22)
**Status:** ✅ COMPLETED
- Discovered and removed duplicate core-principles.md at root level
- Kept authoritative copy at docs/architecture/objects/core-principles.md
- Updated 4 cross-references in 4 files (00-architecture-overview.md, open-questions.md, decisions.md, orchestration-log)
- Commit: 92601d2

### Session: Parser Documentation Extraction (2026-03-25)
**Status:** ✅ COMPLETED
- Created docs/architecture/engine/basic-parser.md (202 lines, 7.4 KB)
- Extracted Tier 1 (Exact Dispatch) and Tier 2 (Phrase Similarity) from 00-architecture-overview.md
- Comprehensive coverage: design, characteristics, implementation strategy, flow diagrams, testing strategy, performance notes
- Updated 00-architecture-overview.md: removed 13 lines, added 1-line cross-reference
- Updated intelligent-parser.md: added basic-parser.md to REFERENCES section
- All content preserved; overview reduced by ~150 lines in focused extraction
- Commit: b1c49d2

### Session: Parser Tier Refactoring — 5 Dedicated Files (2026-03-25)
**Status:** ✅ COMPLETED
**Requestor:** Wayne Berry
**Outcome:** ONE .md file per parser tier (exactly 5 files) + updated architecture overview

**Files Created:**
1. `parser-tier-1-basic.md` (2.5 KB) — Exact verb dispatch [✅ Built]
2. `parser-tier-2-compound.md` (7.5 KB) — Phrase similarity fallback [✅ Built]
3. `parser-tier-3-goap.md` (19.6 KB) — GOAP backward-chaining [🔷 Designed]
4. `parser-tier-4-context.md` (7.7 KB) — Context window memory [🔷 Designed]
5. `parser-tier-5-slm.md` (9.7 KB) — SLM/LLM fallback, Phase 2+ [🔷 Designed]

**Files Deleted:**
- `basic-parser.md` (replaced by Tiers 1+2)
- `intelligent-parser.md` (replaced by Tiers 3-5)

**Changes to Overview:**
- Updated 00-architecture-overview.md Layer 2 section
- Added all 5 tier files with status badges (✅ Built vs 🔷 Designed)
- Cross-referenced each tier to its dedicated file
- Added architecture example showing tier fallback flow

**Content Preservation:** Zero loss — all content from both source files (basic-parser.md + intelligent-parser.md) split into tier-specific files with clear headers, status markers, and bidirectional cross-references.

**Each Tier File Includes:**
- Clear header: "# Parser Tier N: {Name}"
- Status badge: ✅ Built or 🔷 Designed (not yet implemented)
- File path of implementation (for built tiers)
- Cross-references to adjacent tiers
- Full design, examples, implementation notes
- Integration points with other tiers

**Commit:** e9cf2f0 with Co-authored-by trailer

---

## CROSS-AGENT UPDATES (2026-03-24T12:41:24Z Spawn Orchestration)

### Search Design Docs Rewrite
- **Status:** DELIVERED
- **Change:** Removed bug fix history from design docs (docs/design/verbs/search.md)
- **Added:** 8 formal design principles
- **Principles:**
  1. Search is non-mutating (read-only observation)
  2. Hidden objects remain invisible until revealed
  3. Containers are peekable during search (no state change)
  4. Content reporting on target miss
  5. Search cost reflects deliberateness
  6. Spatial relationships determine accessibility
  7. Container-accessible vs physically-blocked distinction
  8. Search reveals game world structure
- **Rationale:** Wayne directive — design docs capture design insights, not bug archaeology. Bugs belong in issues/changelogs.

### Decision Updated
- **D-WAYNE-DIRECTIVE-DESIGN-DOCS:** Design docs should NOT document bug fixes; capture design principles instead

### Session: Documentation Update — Issues #160 & #161 (2026-03-28T14:00Z)
**Status:** ✅ COMPLETED
**Outcome:** Two documentation issues fixed with comprehensive armor interceptor and equipment hook documentation

**Files Updated:**
1. `docs/architecture/engine/effects-pipeline.md`
   - Updated version from 2.0 to 3.0
   - Added Section 4.3: Armor Interceptor — Material-Derived Protection (SHIPPED)
   - Documented core protection formula: `actual_damage = max(1, incoming - protection)`
   - Documented protection calculation including: hardness (1.0×), flexibility (1.0×), density (0.5×)
   - Documented fit multipliers: makeshift 0.5×, fitted 1.0× (default), masterwork 1.2×
   - Documented degradation state multipliers: intact 1.0×, cracked 0.7×, shattered 0.0×
   - Documented location coverage via explicit `covers` array or `wear.slot` matching
   - Documented degradation transition formula: `break_chance = fragility × (damage / 20) × impact_factor`
   - Documented impact factors: piercing 0.5×, slashing 1.0×, blunt 1.5×
   - Referenced actual implementation at `src/engine/armor.lua`
   - Renamed section 4.4 to 4.5 (Interceptor Ordering)

2. `docs/architecture/engine/event-hooks.md`
   - Updated Section 2.2 table (Currently Active Hooks) to fix implementation location references:
     - `on_drop`: corrected to `acquisition.lua` (was `verbs/init.lua`)
     - `on_wear`: corrected to `equipment.lua` (was `verbs/init.lua`)
     - `on_remove_worn`: corrected to `equipment.lua` (was `verbs/init.lua`)
     - `on_open`: corrected to `containers.lua` (was `verbs/init.lua`)
     - `on_close`: corrected to `containers.lua` (was `verbs/init.lua`)
   - Updated Section 11.3 Implementation Location: removed stale line number references, emphasized file organization
   - Updated Section 12.5 Dispatch Points table: added `on_open` and `on_close`, corrected file references to match refactored verb handlers

**GitHub Issues Closed (via comment, not automated):**
- Issue #160: "Update event-hooks.md — add on_drop hook + equipment category" → DOCUMENTED
- Issue #161: "Update effects-pipeline.md to v3.0 — document armor interceptor" → DOCUMENTED

**Testing:**
- All 101 tests pass (0 regressions)
- Documentation changes verified to not break any gameplay systems

**Key Insights:**
- **Refactored verb system:** When verbs are split from `verbs/init.lua` into dedicated files (`equipment.lua`, `acquisition.lua`, `containers.lua`), documentation must be updated to reflect the new file structure. References like "line 5011" become outdated immediately.
- **Armor interceptor is high-value documentation:** Material-derived protection values, degradation model, and fit multipliers are complex mechanics that warrant detailed section treatment. Breaking it into subsections (calculation, location coverage, degradation, narration) improves readability.
- **One-shot pattern (event_output) is a good teaching example:** The pattern of "print text, then nil the field" is elegant and worth documenting as a DATA pattern alternative to callbacks. Content authors can use this for first-time flavor text without writing Lua functions.
- **Precision in file paths matters:** When documentation lists implementation locations, keep them current as code reorganizes. The effect.pipeline.md example of armor shows how important it is to reference actual, working code paths.

### Session: Bedroom Objects Design Docs — Matchbox Documentation (2026-07-24T10:15Z)
**Status:** ✅ COMPLETED
**Outcome:** Created comprehensive design documentation for matchbox object (only bedroom object lacking docs)**Files Created:**
1. `docs/objects/matchbox.md`
   - Description and material (cardboard)
   - Location & puzzle role (primary fire source, limited supply)
   - Containment structure (holds 7 matches in closed/open states)
   - FSM states: closed (inaccessible) ↔ open (accessible)
   - Sensory descriptions (all 4 senses for both states)
   - Transitions (closed→open via `open`, open→closed via `close`)
   - Container capacity and weight properties
   - Special properties: `has_striker=true` for compound interactions
   - Keywords and aliases (matchbox, match box, tinderbox, lucifers, etc.)
   - Integration with Match system (7-tick total burn economy)
   - Puzzle dependencies (nightstand → matchbox → matches → fire interactions)**Status Check:**
- ✅ Nightstand: doc exists (`nightstand.md`)
- ✅ Matchbox: NEW doc created (`matchbox.md`)
- ✅ Wardrobe: doc exists (`wardrobe.md`)
- ✅ Bed: doc exists (`bed.md`)
- ✅ Rug: doc exists (`rug.md`)
- ✅ Trap Door: doc exists (`trap-door.md`)**Key Learnings:**
- Matchbox is a critical puzzle junction: container + striker tool + limited consumable resource
- Container accessibility pattern: `accessible=false` (closed) prevents contents access; mutation to `matchbox-open` sets `accessible=true`
- Fire economy: 7 matches × 3-tick burn time = 21 total ticks. Scarcity drives player decision-making
- Compound verbs require `has_striker=true` metadata on matchbox (not just conceptual)
- All bedroom objects now fully documented with design directives, sensory properties, and puzzle roles
