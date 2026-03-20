# Frink — History Archive (2026-03-18 to 2026-03-20T22:40Z)

## Agent Summary
**Role:** Technical Researcher — architectural guidance, feasibility studies, competitive analysis.
Frink delivered foundational research on text adventure architecture, Lua language selection, multiverse MMO design, self-modifying code safety, parser pipeline/sandbox security, local SLM feasibility, model distillation, PWA/Wasmoon prototype, CYOA branching analysis, MUD verb research, and competitive landscape analysis (16 competitors, $1.85B market).

## Date Range
2026-03-18 to 2026-03-20T22:40Z

## Major Themes
- Engine architecture research (text adventure patterns, Lua, multiverse)
- Self-modifying code & sandbox security (6 layers, 8 threat classes)
- Parser research (hybrid rule-based + SLM, embedding distillation, three-tier architecture)
- PWA/Wasmoon browser deployment feasibility
- CYOA branching pattern analysis (13 books, 6 patterns)
- Competitive landscape (16 competitors, mobile IF market)
- MUD verb research (5-10× more verbs than single-player IF)

## Key Deliverables

### Text Adventure Architecture
- Report: resources/research/architecture/text-adventure-architecture.md
- Parent-child containment tree as proven standard (Zork, Inform 7, TADS)
- Rooms as graph nodes, exits as edges, standard verb-noun pipeline

### Lua Language Recommendation
- Report: resources/research/architecture/modern-text-adventure-data-structures.md
- Homoiconicity (code IS data), prototype inheritance, production pedigree (200+ games)
- Small runtime (~200KB), live reload, C embedding API

### Multiverse Architecture
- Report: resources/research/architecture/multiverse-mmo-architecture.md (52KB)
- Per-universe Lua VMs, event sourcing, copy-on-write snapshots
- Infinite scalability, per-player narrative pacing, Git-compatible DAG history

### Self-Modifying Code & Sandbox Security
- Report: resources/research/architecture/self-modifying-game-languages.md (45KB)
- Report: resources/research/architecture/parser-pipeline-and-sandbox-security.md (54KB)
- 6 sandbox layers: capability API, AST validation, sandboxed env, instruction limiting, transaction semantics, invariant validation
- 8 threat classes mitigated: infinite loops, memory exhaustion, state corruption, universe contamination, privilege escalation, cross-universe access, filesystem breaches, DoS on merge

### Local SLM Parser Research
- Report: resources/research/architecture/local-slm-parser.md
- Browser SLMs viable: Qwen2.5-0.5B (Q4, ~350MB), 200-500ms, WebGPU
- Hybrid parser: rule-based (~85%, <1ms) + SLM fallback (~15%)
- 350MB download is main obstacle; rule-based must be baseline
- Decision 17 satisfied (zero per-player token cost)

### Model Distillation Research
- Report: resources/research/architecture/parser-distillation.md
- Embedding-based (GTE-tiny ~5MB ONNX, 92-95% accuracy, 10-30ms) beats generative distillation (350MB, ~3% more)
- Three-tier hybrid: Tier 1 rule-based, Tier 2 embedding, Tier 3 optional SLM
- Re-distillation trivial: add verb = 100 phrases ($0.05) + 5s encode = ~35s total
- Annual cost: ~$65

### PWA + Wasmoon Feasibility
- Report: .squad/agents/frink/research-pwa-wasmoon.md
- Wasmoon highly viable: Lua 5.4 to WASM, ~90% code runs unmodified
- Three adaptations: io.popen → manifest, blocking REPL → event-driven, print → DOM
- Performance: ~168KB gzipped, <5ms per command, ~100-200ms cold start
- Prototype: 5-7 hours total
- Decision D-43 filed

### CYOA Branching Analysis
- Report: resources/research/choose-your-own-adventure/ (14 files)
- 6 patterns: Time Cave, Branch-and-Bottleneck, Parallel Tracks, Hub-and-Spoke, Loop/Cycle, Hidden/Unreachable
- Inside UFO 54-40's unreachable ending most applicable to our project
- Underground Kingdom (#18) closest structural analogue
- Recommendation: bottleneck/diamond branching + hidden content

### Competitive Analysis
- Report: resources/research/competitors/ (16 files + overview)
- 16 competitors: Frotz, Hadean Lands, A Dark Room, Choice of Games, Sorcery!, 80 Days, Lifeline, AI Dungeon, Magium, MUD clients, etc.
- Mobile IF market: $1.85B (2024), 13.2% CAGR
- Parser input is #1 barrier on mobile
- "Starts in darkness" commercially validated (A Dark Room hit #1 iOS)
- Multiplayer text adventure on mobile is whitespace
- Premium one-time purchase preferred

### MUD Verb Research
- Report: resources/research/competitors/mud-clients/verbs.md (27KB)
- MUDs have 5-10× more verbs than single-player IF (170-500+ vs 20-40)
- Social verbs drive retention (200+ predefined emotes in Discworld)
- Abbreviations mandatory (n/s/e/w/u/d, i, l)
- Multiplayer verbs structurally distinct (party, guild, PvP, economy)
- Verb aliases enable power-user customization

### Competitor Research Reorganization
- Reorganized 16 files into per-competitor subfolders
- Each competitor: subfolder + overview.md
- Scalable architecture for future per-competitor deep dives

## Cross-Agent Updates
- Bart: FSM engine validated Frink's research on Lua table-driven approaches
- CBG: FSM lifecycle design aligned with research findings

## Decisions Filed
- D-43: PWA + Wasmoon Prototype Feasibility
- Hybrid Parser Architecture (Rule-Based + Local SLM) — proposed

## Recommendations Summary
- Build rule-based parser now (Phase 1), add local SLM post-MVP (Phase 2)
- Embedding-primary hybrid (5.5MB) replaces most of 350MB SLM's job
- Proceed with Wasmoon prototype (high confidence, low risk)
- Use bottleneck/diamond branching for narrative structure
- Build tap-to-suggest UI for mobile, implement async multiplayer first
- 50-100 predefined socials for MVP (retention drivers)
