# Squad Decisions

**Last Updated:** 2026-03-25T18:21:05Z  
**Last Deep Clean:** 2026-03-25T18:21:05Z  
**Scribe:** Session Logger & Memory Manager

## How to Use This File

**Agents:** Scan the Decision Index first. Active decisions have full details below. Archived decisions are in `decisions-archive.md`.

**To add a new decision:** Create `inbox/{agent-name}-{slug}.md`, Scribe will merge it here.

---

## Decision Index

Quick-reference table of ALL decisions (active + archived). 

| ID | Category | Status | One-Line Summary | Location |
|----|----------|--------|------------------|----------|
| D-14: True Code Mutation (Objects Rewritten, Not Flagged) | Architecture | 🟢 Active | Foundational | Active |
| D-INANIMATE: Objects Are Inanimate (Creatures Are Future) | Architecture | 🟢 Active | See full entry | Active |
| D-ENGINE-REFACTORING-REVIEW | General | 🟢 Active | See full entry | Active |
| D-HIRING-DEPT: All New Hires Must Have Department Assignment | General | 🟢 Active | See full entry | Active |
| D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive | General | 🟢 Active | See full entry | Active |
| D-VERBS-REFACTOR-2026-03-24 | General | 🟢 Active | See full entry | Active |
| D-LARK-GRAMMAR: Lark-Based Lua Object Parser | Parser | 🟢 Active | See full entry | Active |
| D-META-CHECK-BUILD-2026-03-24 | Parser | 🟢 Active | See full entry | Active |
| D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z) | Process | 🟢 Active | See full entry | Active |
| D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z) | Process | 🟢 Active | See full entry | Active |
| D-HEADLESS: Headless Testing Mode | Testing | 🟢 Active | See full entry | Active |
| D-TESTFIRST: Test-First Directive for Bug Fixes | Testing | 🟢 Active | See full entry | Active |
| D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete | Testing | 🟢 Active | See full entry | Active |
| D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression T | Testing | 🟢 Active | See full entry | Active |
| Architecture Notes | Architecture | 📦 Archived | See full entry | Archive |
| D-104: PLAYER-CANONICAL-STATE (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-105: OBJECT-INSTANCING-FACTORY (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-123: MATERIAL-MIGRATION (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-167: P0C-META-CHECK-V2 (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-168: COMPOUND-COMMAND-SPLITTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-169: AUTO-IGNITE-PATTERN (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-170: DOOR-FSM-ERROR-ROUTING (Wave 9 — Burndown) | Architecture | 📦 Archived | See full entry | Archive |
| D-3: Engine Conventions from Pass-002 Bugfixes (2026-03-22) | Architecture | 📦 Archived | See full entry | Archive |
| D-42: Movement Handler Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-45: FSM Tick Scope | Architecture | 📦 Archived | See full entry | Archive |
| D-ALREADY-LIT: FSM State Detection for Already-Lit Objects | Architecture | 📦 Archived | See full entry | Archive |
| D-APP-STATELESS: Appearance subsystem is stateless | Architecture | 📦 Archived | See full entry | Archive |
| D-APP001: Appearance is an Engine Subsystem | Architecture | 📦 Archived | See full entry | Archive |
| D-BRASS-BOWL-KEYWORD-REMOVAL | Architecture | 📦 Archived | See full entry | Archive |
| D-BROCKMAN001: Design vs Architecture Documentation Separation | Architecture | 📦 Archived | See full entry | Archive |
| D-BUG017: Save containment before FSM cleanup | Architecture | 📦 Archived | See full entry | Archive |
| D-CONDITIONAL: Conditional Clauses Detected in Loop, Not Parser | Architecture | 📦 Archived | See full entry | Archive |
| D-CONSC-GATE: Consciousness gate before input reading | Architecture | 📦 Archived | See full entry | Archive |
| D-CONTAINER-SENSORY-GATING | Architecture | 📦 Archived | See full entry | Archive |
| D-ENGINE-HOOKS-USE-EAT-DRINK | Architecture | 📦 Archived | See full entry | Archive |
| D-FIRE-PROPAGATION-ARCHITECTURE | Architecture | 📦 Archived | See full entry | Archive |
| D-GOAP-NARRATE: GOAP Steps Narrate via Verb-Keyed Table | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT001: Hit verb is self-only in V1 | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT002: Strike disambiguates body areas vs fire-making | Architecture | 📦 Archived | See full entry | Archive |
| D-HIT003: Smash NOT aliased to hit | Architecture | 📦 Archived | See full entry | Archive |
| D-MATCH-TERMINAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-MODSTRIP: Noun Modifier Stripping is a Separate Pipeline Stage | Architecture | 📦 Archived | See full entry | Archive |
| D-MUTATE-PROPOSAL: Generic `mutate` Field on FSM Transitions | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJ004: Wall clock uses 24-state cyclic FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-OBJECT-INSTANCING-FACTORY | Architecture | 📦 Archived | See full entry | Archive |
| D-P1-PARSER-CLUSTER | Architecture | 📦 Archived | See full entry | Archive |
| D-PEEK: Read-Only Search Peek for Containers | Architecture | 📦 Archived | See full entry | Archive |
| D-PLAYER-CANONICAL-STATE | Architecture | 📦 Archived | See full entry | Archive |
| D-PUSH-LIFT-SLIDE-VERBS | Architecture | 📦 Archived | See full entry | Archive |
| D-SEARCH-OPENS: Search Opens Containers (supersedes #24) | Architecture | 📦 Archived | See full entry | Archive |
| D-SLEEP-INJURY: Sleep now ticks injuries (bug fix) | Architecture | 📦 Archived | See full entry | Archive |
| D-SPATIAL-ARCH: Spatial Relationships — Engine Architecture | Architecture | 📦 Archived | See full entry | Archive |
| D-TIMER001: Timed Events Engine — FSM Timer Tracking and Lifecycl | Architecture | 📦 Archived | See full entry | Archive |
| D-UI-1 to D-UI-5: Split-Screen Terminal UI Architecture (2026-07- | Architecture | 📦 Archived | See full entry | Archive |
| D-WASH-VERB-FSM | Architecture | 📦 Archived | See full entry | Archive |
| D-WEB-BUG13: Bug Report Transcript in Web Bridge Layer | Architecture | 📦 Archived | See full entry | Archive |
| D-WINDOW-FSM: Window & Wardrobe FSM Consolidation (2026-03-20) | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: Core Principles Are Inviolable | Architecture | 📦 Archived | See full entry | Archive |
| DIRECTIVE: User Reference — Dwarf Fortress Architecture Model | Architecture | 📦 Archived | See full entry | Archive |
| UD-2026-03-20T21-54Z: No special-case objects; clock as 24-state  | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge wardrobe into single FSM file (2026-03-20T2 | Architecture | 📦 Archived | See full entry | Archive |
| USER-DIRECTIVE: Merge window into single FSM file (2026-03-20T21- | Architecture | 📦 Archived | See full entry | Archive |
| Affected Team Members | General | 📦 Archived | See full entry | Archive |
| D-17: Universe Templates (Build-Time LLM + Procedural Variation) | General | 📦 Archived | See full entry | Archive |
| D-37 to D-41: Sensory Verb Convention & Tool Resolution | General | 📦 Archived | See full entry | Archive |
| D-43: Multi-Room Loading at Startup | General | 📦 Archived | See full entry | Archive |
| D-44: Per-Room Contents, Shared Registry | General | 📦 Archived | See full entry | Archive |
| D-46: Cellar as Room 2 | General | 📦 Archived | See full entry | Archive |
| D-47: Exit Display Name Convention | General | 📦 Archived | See full entry | Archive |
| D-5: Spatial Relationships Implementation (2026-03-26) | General | 📦 Archived | See full entry | Archive |
| D-APP002: Layered Head-to-Toe Rendering | General | 📦 Archived | See full entry | Archive |
| D-APP003: Nil Layers Silently Skipped | General | 📦 Archived | See full entry | Archive |
| D-APP004: Appearance Generic Over Player State | General | 📦 Archived | See full entry | Archive |
| D-APP005: Injury Phrases via 4-Stage Pipeline | General | 📦 Archived | See full entry | Archive |
| ... | ... | ... | +87 more archived decisions | Archive |


**Legend:** 🟢 Active | 🔄 In Progress | ✅ Implemented | 📦 Archived

---

## Active Decisions

These are decisions agents need to know about RIGHT NOW.


### D-14: True Code Mutation (Objects Rewritten, Not Flagged)

**Status:** Foundational

---

### D-INANIMATE: Objects Are Inanimate (Creatures Are Future)

**Author:** Wayne "Effe" Berry + Flanders (Object Engineer)

---

### D-ENGINE-REFACTORING-REVIEW

**Author:** Bart (Architect)

---

### D-HIRING-DEPT: All New Hires Must Have Department Assignment

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-NO-NEWSPAPER-PENDING: Newspaper Hold Directive



---

### D-VERBS-REFACTOR-2026-03-24

**Author:** Bart (Architect)

---

### D-LARK-GRAMMAR: Lark-Based Lua Object Parser



---

### D-META-CHECK-BUILD-2026-03-24

**Author:** Smithers (UI/Parser)

---

### D-WAYNE-BATCH-2026-03-24: Design Decisions Batch (Wayne)

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-WAYNE-CODE-REVIEW-DIRECTIVE (2026-03-24T07-28-58Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-COMMIT-CHECK: Check Commits Before Push (Quality Gate)

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-CONTRIBUTIONS: Track Wayne Contributions Continuously

**Author:** Wayne "Effe" Berry (User Directive)

---

### D-WAYNE-META-CHECK-SCOPE-EXPANSION (2026-03-24T17-40-46Z)

**Author:** Wayne Berry (via Copilot)

---

### D-WAYNE-TDD-REFACTORING-DIRECTIVE (2026-03-24T07-34-02Z)

**Author:** Wayne Berry (via Copilot)

---

### D-HEADLESS: Headless Testing Mode

**Author:** Bart (Architect)

---

### D-TESTFIRST: Test-First Directive for Bug Fixes

**Author:** Wayne "Effe" Berry (via Copilot)

---

### D-V2-ACCEPTANCE-CRITERIA: P0-C V2 Acceptance Criteria Complete

**Author:** Lisa (Object Testing Specialist)

---

### D-WAYNE-REGRESSION-TESTS: Every Bug Fix Must Include Regression Test

**Author:** Wayne "Effe" Berry (User Directive)

---
