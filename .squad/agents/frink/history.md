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

## Learnings
- Embedding matching beats generative distillation for constrained domains
- Browser SLMs are real but 350MB download limits adoption
- Wasmoon enables zero-framework Lua PWA deployment
- CYOA hidden/unreachable content translates directly to unconventional verb usage
- MUD social verbs require zero mechanical reward but drive retention
- Premium one-time purchase is market-preferred for text games

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
