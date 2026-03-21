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
- **Newspaper (MMO Gazette):** In-universe daily updates; multiple editions per day; comic + op-ed sections
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
- Maintained in-universe voice with comic + op-ed sections

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
