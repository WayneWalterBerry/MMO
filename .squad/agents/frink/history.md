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
