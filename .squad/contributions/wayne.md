# Wayne "Effe" Berry — Project Contributions

> Owner, Designer, Quality Guardian, Systems Thinker

---

## Summary Stats

- **Project start:** 2026-03-18
- **Active sessions:** 6+ (2026-03-18 through 2026-03-23+)
- **Design systems created:** 5 (unconsciousness, appearance, injuries, spatial relationships, effects pipeline)
- **Bugs filed:** 8 (iPhone play-test session, issues #19-27)
- **Major directives implemented:** 7 (Prime Directive, effects pipeline, hit verb architecture, consciousness gate, sleep fix, appearance subsystem, spatial system)
- **Course corrections:** 5+ (process gates, documentation requirements, unit test discipline, process rules, team building)
- **Team members hired:** 1 (Gil, Web Engineer)
- **Features shipped:** 5+ (hit verb, unconsciousness, sleep fix with injury ticking, appearance subsystem, mirror integration)

---

## 🎯 Design Vision

### The Prime Directive: "Feel Like Copilot, Cost Like Zork"

**Date:** 2026-03-18 onwards  
**Status:** Foundational design principle, guiding all architectural decisions  
**Impact:** Established economic and philosophical baseline for entire project

Wayne established the core design philosophy: players should experience conversational AI quality interaction patterns, but the engine must run on zero-token Zork-era technology. This single principle shaped every subsequent decision — build-time LLM (not per-player), deterministic parser (not neural), pure Lua engine (not cloud-dependent).

> Quote from daily plan: "Pure pipeline. Zero tokens." — This is Wayne's north star, repeated in multiple planning documents.

---

### The Unconsciousness System

**Date:** 2026-03-22  
**Scope:** Self-contained state machine for player incapacitation  
**Feature Owner:** Smithers (implemented), Wayne (directed)  
**Design Decisions Filed:** D-CONSC-GATE, D-SLEEP-INJURY, and consciousness-related architecture decisions  

Wayne directed the design of how unconsciousness works — not a simple pause state but a complex system where:

- The consciousness check runs at the top of the game loop BEFORE input reading (D-CONSC-GATE)
- While unconscious, the game ticks injuries without consuming player input
- Death during unconsciousness has custom narration: "You never wake up" (D-SLEEP-INJURY)
- Wake-up narration tells players what happened while they were out
- Sleep now properly ticks injuries (was a bug — Wayne caught it)

**Insight:** Wayne thinks systemically. He didn't just want "knock the player out." He wanted a state that cascades correctly through injury mechanics, time, and narration. The feature required connecting four systems (loop control, injury ticking, death detection, narration).

---

### The Appearance Subsystem

**Date:** 2026-03-22  
**Scope:** Stateless player description engine  
**Feature Owner:** Smithers (implemented), Wayne (directed architecture requirements)  
**Design Document:** `docs/objects/appearance.md` (14.8 KB) + decision D-APP-STATELESS

Wayne directed that appearance be a pure function, not stateful:
- `appearance.describe(player, registry)` reads state but never modifies it
- Future-proofed for multiplayer: any player can describe any other player
- Health tiers render visual impact: fresh → minor → moderate → critical
- Injury phrase composer creates natural descriptions from active injuries
- Mirrors become functional gameplay objects (examine mirror shows your appearance)

**Insight:** Wayne designed for scale before need. The stateless API pattern means multiplayer was architecturally built in before a single network line was written. This is systems thinking — one feature decision enabling entire future functionality trees.

---

### The Injury Categories & Hit Verb System

**Date:** 2026-03-22  
**Scope:** Body-area tracking, armor reduction, self-infliction only in V1  
**Design Decisions Filed:** D-HIT001, D-HIT002, D-HIT003 + injury-related architecture  

Wayne designed the hit verb to be:
- Self-infliction only in V1 (hits on enemies are Phase 2+)
- Disambiguated with STRIKE verb (body area → hit, fire-making tool → fire)
- SMASH preserved for mirror destruction (not aliased to hit)
- Connected to armor reduction mechanics and health tier rendering

**Why this matters:** Hit verb is not just "punch yourself." It's the entry point to a damage system that connects to injuries, armor, appearance, and eventual NPC combat. Wayne designed each boundary explicitly.

---

### The Spatial Relationships Architecture

**Date:** 2026-03-22 evening (designed after iPhone play-test bugs)  
**Status:** Designed and architected, implementation in progress  
**Decisions Filed:** D-SPATIAL-HIDE, D-SPATIAL-ARCH  

Wayne identified the pattern through play-testing (issues #24, #26, #27) — the engine conflates "on top of" with "under/hidden." His observation: "I typed 'look under table' and the game told me what was ON the table. That's not right. Spatial relationships matter."

This triggered a complete architectural redesign:
- **Visible relationships:** on_top_of, beside (visible in room description)
- **Hidden relationships:** under, behind, inside (require active search)
- **Core distinction:** Visibility is the defining attribute
- **Object metadata:** Spatial relationships tracked at instance level, not just container level

**Insight:** Wayne catches architectural patterns before they cause cascade failures. He sees how spatial confusion breaks puzzles, not just individual commands. Playing on iPhone forced discovery of this flaw months before it would become critical during puzzle design.

---

### The Effects Pipeline Architecture

**Date:** 2026-03-23  
**Status:** Directed and validated through architecture audit  
**Decision Filed:** D-EFFECTS-PIPELINE, D-INJURY-HOOKS  

Wayne directed questions that revealed a critical architectural gap:
- "Are the engine events documented?" — Led to audit of event system
- "How do consumables connect to injury system?" — Asked about .lua to engine hooks
- "What about contact injuries?" — Pushed for distinction between fire-based, chemical, and physical damage

This led to Bart proposing the Effects Pipeline: a composable system where injuries can originate from multiple sources (self-infliction, poison, bear traps, fire, bleed-out) and each routes through a consistent effect application layer.

**Insight:** Wayne doesn't accept "we'll figure it out when we get there." He asks architecture questions early, forces documentation of implicit assumptions, and ensures patterns are named and systematic rather than ad-hoc.

---

### The Design Documentation-After-Implementation Requirement

**Date:** 2026-03-22 onwards  
**Process Impact:** All feature work now includes design doc authoring  
**Status:** Enforced in daily plans  

Wayne established that design docs must be updated after implementation completes (not before, not aspirationally). This ensures docs stay current with code, not become maintenance debt. Every feature shipped on 2026-03-22 included fresh design documentation:

- Hit verb design (14 KB)
- Unconsciousness design (13 KB)
- Appearance design (14.8 KB)
- Mirror design (11 KB)
- Self-hit design (12 KB)

**Impact:** 64.8 KB of fresh documentation shipped in one evening, all consumed by the team immediately. Prevents the "my code doesn't match the docs" problem.

---

## 🔍 Quality Gates & Course Corrections

### "Don't You Need Unit Tests Before Refactoring?" — Process Gap Caught

**Date:** 2026-03-22  
**Context:** Refactoring parser pipeline before tests existed  
**Wayne's Directive:** Write tests first. Use them to verify refactoring behavior doesn't change.  
**Outcome:** D-PIPE-TESTS filed. 224 per-stage pipeline unit tests created before Phase 5 code changes.

**Insight:** Wayne thinks in process, not features. He caught an implicit assumption (code-first refactoring) before it became a regression hole. The resulting test suite (7 files, 224 tests) became the regression safety net for parser work.

---

### "Make Sure Marge Is Keeping Track of Unit Tests" — Regression Safety Net

**Date:** 2026-03-22  
**Action:** Directed hiring of Marge as Test Manager with explicit charter  
**Scope:** Bug tracker ownership, test pass review, coverage audit, deploy gates  

Wayne established the bug lifecycle:
- Engineers fix bugs and write regression tests
- Marge closes issues (not engineers)
- Regression unit tests are mandatory before issue closure
- Marge enforces gates at phase transitions

**Impact:** Zero regressions across 40 commits in one day. Process discipline prevented the "fix one bug, break three" trap that kills velocity.

---

### Spatial Relationship Pattern Recognition Across Multiple Bugs

**Date:** 2026-03-22 evening (iPhone play-test)  
**Issues:** #24 (Spatial description inconsistency), #26 (Object placement spatial error), #27 (Spatial container reference bug) + Nelson's #32-34  

Wayne played the game on his iPhone and immediately noticed: six seemingly unrelated bugs all pointed to one root cause — spatial relationship architecture.

**Marge's triage note (echoing Wayne's insight):** "Issues #24, #26, #27, #32, #33, #34 are all spatial. One architectural fix solves six bugs. That's how you burn down a backlog."

**Insight:** Wayne doesn't see bugs, he sees patterns. He clusters them by root cause before assigning fixes. This reduces rework and reveals architectural gaps.

---

### Process Rules: "Search Is Observation"

**Date:** 2026-03-22 daily plan  
**Principle:** Parser search isn't a tool — it's how the player OBSERVES the world  

Wayne established a rule: search results must be consistent with room descriptions. Hidden objects can't appear in searches. Spatial relationships affect search visibility.

This single rule prevented building search as a second verb system and forced integration with spatial architecture.

---

### Process Rules: "Nelson Uses --Headless for Automated Testing"

**Date:** 2026-03-22  
**Issue:** TUI rendering causing false-positive hangs in automated tests  
**Wayne's Directive:** Create a test mode that strips UI and runs pure game logic  
**Implementation:** Bart's `--headless` flag (D-HEADLESS decision)  

Result: 6 "hangs" were actually TUI rendering stalls. Deploy gate cleared.

**Insight:** Wayne doesn't tolerate "just run it manually to see if it's really broken." He pushes for automated testing infrastructure that eliminates false positives.

---

### Zero-Regression-During-Refactoring Policy

**Date:** 2026-03-22  
**Context:** Parser pipeline refactor (7 stages, 479 tests → 0 regressions)  
**Policy:** Every refactor must prove zero behavior change through unit tests  

Daily plan quote: "Work the WHOLE plan today. No backlog. Nelson play-tests between every phase."

This enforces that refactoring is iterative, testable, and verifiable — not a heroic code rewrite.

---

## 🐛 Play-Testing & Bug Discovery

### iPhone Play-Test Session — 8 Bugs Filed from the Couch

**Date:** 2026-03-22 evening (22:05Z)  
**Context:** First mobile device test of live deployment  
**Issues Filed:** #19-27 (8 bugs, 1 feature request)  

Wayne played the game on his iPhone and discovered gaps that desktop testing missed:
- UI rendering on mobile viewport (#19)
- Transcript buffer overflow on small screens (#20)
- Status bar overlapping game text (#21)
- Touch input not registering (#22)
- Parser error on mobile keyboard input (#23)
- Spatial description inconsistency (#24) ⚡ **Led to architectural redesign**
- Deploy script path issue (#25)
- Object placement spatial error (#26) ⚡ **Spatial pattern**
- Spatial container reference bug (#27) ⚡ **Spatial pattern**

**Pattern Recognition:** 3 of 8 bugs pointed to spatial relationships — this triggered the evening's D-SPATIAL-HIDE and D-SPATIAL-ARCH design work.

**Insight:** Wayne doesn't just file bugs — he looks for patterns. This is real play-testing, not QA checklist completion. He plays like a player (on his phone, from the couch), not like an engineer (on a desktop, with console open).

---

### Identified Spatial Relationship Pattern Across Multiple Bugs

Nelson's subsequent testing confirmed Wayne's spatial pattern:
- Pass 036: Presentation polish (29/37 pass)
- Pass 037: Spatial relationship stress test (15/22 pass)
  - #32: "Look under X" returns "on X" contents
  - #33: Hidden objects visible in room description
  - #34: Spatial preposition not parsed correctly

All traced back to the same architectural issue Wayne identified in his iPhone session.

---

## 🏗️ Architecture Direction

### Question: ".Lua to Engine Hooks for Consumable→Injury"

**Date:** 2026-03-23 morning  
**Context:** How do poison bottles trigger injury system?  
**Wayne's Question:** How does meta-code (object definitions) trigger engine effects?  
**Outcome:** Led to D-EFFECTS-PIPELINE and D-INJURY-HOOKS design  

Wayne forced clarity on the connection between object-layer code (a poison bottle) and engine-layer systems (injury application). This prevented ad-hoc "call this function from meta-code" patterns and led to a systematic Effects Pipeline.

---

### Question: "Are the Engine Events Documented?"

**Date:** 2026-03-23 morning  
**Impact:** Audit of event system documentation  
**Outcome:** Documentation requirement added to architecture standards  

Wayne doesn't accept implicit contracts. If the engine fires events, they must be documented. This prevents "I didn't know that event existed" integration problems later.

---

### Direction: Bear Trap vs. Poison Bottle — Contact Injuries

**Date:** 2026-03-23  
**Decision Requested:** How do contact injuries (bear trap trigger on touch) vs. consumable injuries (poison on swallow) route through the injury system?  

Wayne pushed for explicit architectural distinction rather than treating all injuries the same. This led to:
- Fire-based injuries (burns, smoke inhalation)
- Chemical injuries (poison, acid)
- Physical injuries (puncture, crushing from bear trap)
- Self-infliction (hitting yourself)

Each with different entry points, severity curves, and recovery mechanics.

---

### Direction: The Effects Pipeline Directive

**Date:** 2026-03-23  
**Status:** Proposed by Bart, validated by Wayne  
**Principle:** All injury sources flow through a composable Effects Pipeline  

Instead of ad-hoc "if poison then apply injury" sprinkled through the codebase, establish one composition point:
- Contact events trigger effect application
- Consumable events trigger effect application
- Self-infliction triggers effect application
- Result: One injury system, multiple input sources, clear dependency flow

Wayne didn't invent this — he asked questions that forced it to be invented.

---

## 📋 Process & Team Building

### Team Initialization & Charter Creation

**Date:** 2026-03-18  
**Action:** Established squad structure with specialized agent roles  
**Team Members:** Bart (Engine), Nelson (Testing), Comic Book Guy (Design), Frink (Research), Brockman (Documentation), Marge (hired 2026-03-22), Gil (hired 2026-03-22)  

Wayne set up governance structure:
- Clear agent charters (each knows their role and boundaries)
- Decision log (all architecture decisions recorded)
- Orchestration log (all agent spawns tracked)
- Newspaper (daily progress updates)

---

### Hiring Decisions

**Date:** 2026-03-22  
**Hire 1 — Marge:** Test Manager  
- Owns bug tracker
- Enforces regression unit test requirement before issue closure
- Manages deploy gates (phase transitions require Marge sign-off)

**Hire 2 — Gil:** Web Engineer  
- Owns web layer (GitHub Pages deployment, HTML rendering, cache busting)
- Shipped 3 fixes on day one (#12, #13, #18)

**Insight:** Wayne understands that scaling requires adding process people, not just coding people. Marge doesn't write code but prevents process decay. Gil specializes in web layer so Bart can focus on engine. Team grows through differentiated roles.

---

### Daily Planning Discipline

**Date:** 2026-03-22 onwards  
**Files:** `plans/2026-03-22-daily-plan.md`, `plans/2026-03-23-daily-plan.md`  

Wayne establishes daily planning as mandatory:
1. **Phased execution:** Each phase ends with commit+push
2. **Nelson sanity checks:** Between every phase, Nelson plays to verify game integrity
3. **Process rules:** Tests must pass before advancing, plan must be updated, no accumulated drift
4. **Clear outcomes:** "Completed Today" section updated as work finishes
5. **Rollup updates:** Phase completion documented, metrics captured

Quote from plan: "Rule: Work the WHOLE plan today. No backlog. Nelson play-tests between every phase. Commit+push between every step."

---

### Established Bug Lifecycle and Regression Gate

**Date:** 2026-03-22  
**Process:**
1. Engineers find bugs
2. Engineers fix bugs and write regression unit tests
3. Engineers submit for closing
4. **Marge verifies regression tests exist and pass**
5. Marge closes issue (not engineer)

This prevents:
- Issues closed without tests (regression later)
- Test coverage gaps (Marge audits every closure)
- Process decay (enforcement consistent)

**Impact:** 1,117+ tests passing across 40 commits. Zero regressions despite massive velocity.

---

### Established Zero-Regression-During-Refactoring Policy

**Date:** 2026-03-22 Phase 4-6  
**Principle:** Refactoring must be verified with tests, not just "seems to work"  

When Bart refactored the parser pipeline (7 stages, table-driven, debug logging):
- Tests created before refactoring
- Code refactored
- Tests verified zero behavior change
- Only then merged to main

**Result:** 479 → 713 → 801 → 872 → 968 → 995 tests passing, each checkpoint verified.

---

### Directed Implementation of Per-Stage Pipeline Unit Tests

**Date:** 2026-03-22 Phase 5 Step 0.5  
**Outcome:** D-PIPE-TESTS decision filed, 224 tests written  

7 composable parser stages, each with isolated tests:
- Preprocess stage
- Synonym stage
- Question transform stage
- Error message stage
- Idiom stage
- Context window stage
- Fuzzy noun resolution stage

Tests call individual stage functions via `preprocess.stages.*` for isolation. Each file independently runnable.

**Insight:** Wayne understands that architectural quality is measurable. Tests that verify stage isolation are not "nice to have" — they're the proof that the architecture actually decomposes.

---

## 💡 Key Insights (Reading Between the Lines)

### Wayne Thinks in Systems, Not Features

Every decision Wayne makes connects multiple systems:
- Unconsciousness connects loop control → injury ticking → death detection → narration
- Appearance connects equipment state → injuries → health tier → multiplayer API
- Hit verb connects body areas → armor reduction → appearance update → injury cascade
- Spatial relationships connect object metadata → search visibility → puzzle design → UI feedback

He doesn't design "a feature," he designs how a feature connects to everything else. This prevents the "we didn't think about how this interacts with X" surprises three months in.

---

### Wayne Catches Process Gaps Before They Bite

He doesn't wait for regressions to happen. He asks:
- "Don't you need tests before refactoring?" (caught unit test gap)
- "Make sure Marge is tracking tests" (built regression safety net proactively)
- "Use --headless for automated testing" (eliminated false positives)
- "Search is observation, not a tool" (prevented duplicate verb system)

He thinks *systemically* about process, not just code.

---

### Wayne Play-Tests His Own Game on Real Devices

Most designers play their game on desktop with console open. Wayne picked up his iPhone from the couch and started playing. He found bugs that desktop testing missed because he played like a player, not an engineer.

This led to:
- Mobile UI fixes
- Spatial relationship architectural redesign
- Pattern recognition (six bugs, one root cause)

Real play-testing reveals what testing plans miss.

---

### Wayne Values Architecture Documentation Being Current, Not Aspirational

He established that design docs must be updated after implementation, not before. This prevents the "I wrote a 10-page design that my code doesn't match" debt trap.

Result: 64.8 KB of fresh design documentation shipped in one evening, all immediately useful, none aspirational.

---

### Wayne Understands Team Scale and Hiring

He doesn't try to do everything himself. He hires:
- Marge to enforce process (not to code)
- Gil to own web layer (freeing Bart from UI concerns)
- Nelson to be the sanity checker (not just a tester)

**Quote from Marge's hire:** Wayne recognized that regression safety requires process infrastructure, not just engineering discipline. That's a hiring decision, not a code change.

---

### Wayne Establishes Governance Before Crisis

Most projects establish governance when process breaks. Wayne established:
- Decision log (before architectural confusion)
- Orchestration log (before agent communication failed)
- Newspaper (before team alignment broke)
- Charters (before role conflict)
- Bug lifecycle (before regression chaos)

He builds process infrastructure proactively, not reactively.

---

### Wayne Sees Patterns Across Bugs, Not Just Individual Fixes

When he filed 8 bugs from iPhone play-testing, he immediately spotted the spatial relationship pattern. Instead of "fix bug #24, fix bug #26, fix bug #27," he recognized "these are all the same architectural issue."

This led to one architectural fix solving six bugs, not six one-off patches.

---

## 📊 Quantified Impact

| Category | Metric | Value | Impact |
|----------|--------|-------|--------|
| **Design Vision** | Core principles established | Prime Directive + 5 design systems | Guides all future work |
| **Architecture** | Systems connected | 7 effects pipelines, 3 subsystems | Enables scale |
| **Quality Gates** | Process rules enforced | 5 major rules | Zero regressions in high-velocity period |
| **Play-Testing** | Bugs found on real devices | 8 filed (iPhone) + pattern recognition | Mobile-ready by accident, spatial gap found early |
| **Team Building** | People hired | 2 (Marge, Gil) | Distributed process and UI concerns |
| **Documentation** | Fresh design docs | 64.8 KB shipped with code | Docs stay current, not aspirational |
| **Velocity** | Commits in one day | 40 (2026-03-22) | High-velocity period maintained zero regressions |

---

## Timeline

| Date | Event | Impact |
|------|-------|--------|
| **2026-03-18** | Project start. Prime Directive established. Squad structure created. | Foundation for all architecture |
| **2026-03-19** | Architecture decisions D-14 through D-21 filed and assessed | Design direction locked, 7/8 firm |
| **2026-03-20** | Composite object system shipped. Tier 2 parser plan created. | Foundational architecture proven |
| **2026-03-21** | Reach 1,000 tests passing. Deploy gate critical. | Velocity proving concept |
| **2026-03-22 (Day)** | 5 hangs fixed, deploy gate cleared, 3 deploys to production, 40 commits | High-velocity day begins |
| **2026-03-22 (Evening)** | iPhone play-test: 8 bugs filed, spatial pattern identified. 5 features shipped. Spatial system designed. Marge + Gil hired. | Architecture gaps found via real-world testing |
| **2026-03-23 (Morning)** | Effects Pipeline architecture directed. Engine audit completed. 15 issues triaged and closed. | Systems thinking deepened, process continued |

---

## Conclusion

Wayne "Effe" Berry is not just a designer or project owner. He is a **systems thinker** who:

1. **Establishes vision early** — Prime Directive guides every decision
2. **Thinks architecturally** — Features connect to multiple systems, not isolated
3. **Catches process gaps** — Tests before refactoring, docs after implementation, regression gates before chaos
4. **Play-tests like a player** — On real devices, not just in the console
5. **Recognizes patterns** — Six bugs become one architectural fix
6. **Builds governance proactively** — Process infrastructure before crisis
7. **Scales through hiring** — Adds process people (Marge) and specialists (Gil) to distribute concerns
8. **Documents contemporaneously** — Design docs ship with code, not years later

His impact is not measured in lines of code written, but in the architectural decisions that enable others to write code efficiently, the process discipline that prevents regressions at scale, and the real-world play-testing that catches gaps before they cascade.

In one week (2026-03-18 to 2026-03-23), Wayne established a project that shipped 1,100+ tests with zero regressions, hired a diversified team, designed three major game systems, fixed the deploy pipeline, and caught architectural gaps through mobile play-testing.

This is the work of someone who understands that great projects are built on systems thinking, process discipline, and real-world validation — not on heroic individual coding effort.

---

*Document created by Chalmers (Project Manager) on 2026-03-23*  
*Data sources: Daily plans, orchestration logs, newspaper editions, GitHub issues, decisions log, session records*
