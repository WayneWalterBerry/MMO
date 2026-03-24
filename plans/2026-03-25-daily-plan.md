# Daily Plan — 2026-03-25

**Owner:** Wayne "Effe" Berry
**Focus:** 🔴 P0 — Custom Meta Compiler (Lisa's validation tool)
**Created:** 2026-03-24

---

## 🔴 P0-A: Engine Code Review — BEFORE EVERYTHING

> **Wayne's directive:** "Before everything, we need to think about the engine .lua files. In several subfolders they are getting very large. Should they be broken down? Are there logical divides? Would this help or hurt the LLM when writing them? Do we have test opportunities for individual files? Become a highly capable senior engineer and code review. This is common on long-running projects to review for refactors."

### Current State (file sizes, March 24)

| File | Lines | Status |
|------|-------|--------|
| `verbs/init.lua` | **5,817** | 🔴 Critical — 31+ verb handlers in one file |
| `parser/preprocess.lua` | 1,036 | 🟡 Large but pipeline is modular |
| `search/traverse.lua` | 871 | 🟡 Getting chunky |
| `parser/goal_planner.lua` | 848 | 🟡 Self-contained |
| `loop/init.lua` | 585 | 🟢 Reasonable |
| Everything else | <500 | 🟢 Fine |

### Review Questions

1. **`verbs/init.lua` (5,817 lines):** Should each verb be its own file? (e.g., `verbs/look.lua`, `verbs/take.lua`, `verbs/search.lua`). What are the shared utilities between verbs? Would splitting help LLMs work on one verb without loading 5K lines of context?

2. **Logical divides:** Within each large file, are there natural seams? (e.g., verbs could split by category: movement, combat, inventory, sensory, interaction)

3. **LLM impact:** Smaller files = less context needed per edit = fewer LLM mistakes. But too many tiny files = more cross-file coordination. What's the sweet spot?

4. **Test opportunities:** Which functions inside large files have no unit tests? Splitting creates natural test boundaries.

5. **Dependency analysis:** If we split verbs/init.lua, what's the shared state? Do verbs share helper functions? Is there a verb registry pattern that would make splitting clean?

### Deliverables

- [x] **Bart:** Senior code review of ALL engine files >500 lines. For each: recommend split/keep, identify logical seams, estimate LOC per split file, flag shared utilities that would become a `verbs/helpers.lua`. Produce `docs/architecture/engine/refactoring-review.md`. ✅ Produced review, split verbs/init.lua (5,884 lines) → 12 modules.
- [x] **Nelson:** BEFORE any refactoring begins — audit test coverage for every function that would move. Write missing tests to cover existing behavior. The test suite is the safety net; refactoring without it is forbidden. ✅ 172 pre-refactor tests, 2,670 assertions post-refactor, 0 regressions.
- [x] **Chalmers:** Review Bart's proposal and decide: do we refactor now (before meta-compiler) or after? Sequencing matters — refactoring changes file paths the meta-compiler would validate. ✅ Decided: refactor FIRST, meta-compiler second.

### ⚠️ Wayne's Directive: TDD-First Refactoring

**Sequence is non-negotiable:**
1. Bart reviews and proposes splits
2. Nelson writes tests covering ALL existing behavior in the code being split
3. Nelson verifies tests pass on CURRENT code (green baseline)
4. THEN and only then: execute the refactor
5. Nelson re-runs tests — must stay green
6. Any red = refactor broke something, revert and fix

---

## 🔴 P0-B: Custom Meta Compiler ("meta-check") — Ship Today

### Step -1: Research Before Docs — Fill the Gaps

Frink's research (76 KB, 5 docs in `resources/research/meta-compiler/`) covers compiler techniques, language choice, and Lua subset analysis. But before writing authoritative design docs, we need answers to:

1. **Actual bug catalog** — Frink: scan git history for every LLM-introduced .lua bug. Classify by type (missing field, wrong type, invalid reference, structural, semantic). This determines which rules matter most and what meta-check catches first.

2. **Lark grammar prototype** — Bart: write a minimal Lark grammar that can parse 5 real object files. Prove the Lua subset is parseable. If Lark chokes on something, we need to know before documenting the architecture.

3. **Lisa's wishlist** — Lisa: what checks does she actually want? She's the user. Her acceptance criteria ARE the rules catalog. Don't guess — ask the tester.

4. **Cross-reference inventory** — Frink: how many cross-references exist today? Count: material references, template references, GUID links, exit targets, keyword overlaps. This scopes the reference-checking module.

5. **Existing validation** — Bart: what validation does the engine already do at load time? If `loader/init.lua` already checks some fields, meta-check shouldn't duplicate — it should catch what the loader DOESN'T.

**Sequence:** Research (30 min) → Docs (1 hr) → Build (2-3 hr) → Lisa validates (30 min)

> **Wayne's directive:** Before writing a single line of code, create `docs/meta-check/` with design docs. The docs define what we're building, then the code follows.

**Deliverables (Brockman + Bart):**

Create `docs/meta-check/` with:

1. **`overview.md`** — What meta-check is, why it exists, the problem it solves. Goals: catch LLM-authored .lua bugs at CI time, not runtime. Both a compiler (semantic analysis) and a linter (style enforcement). Lisa's primary quality gate tool.

2. **`architecture.md`** — The pipeline: lexer → parser → AST → semantic analysis → lint rules → error reporter. How each stage works. What the Lua subset looks like. How schemas per template type drive validation.

3. **`usage.md`** — How Lisa (and CI) runs it:
   - `python scripts/meta-check/check.py src/meta/objects/candle.lua` — single file
   - `python scripts/meta-check/check.py src/meta/objects/` — directory scan
   - `python scripts/meta-check/check.py src/meta/` — full meta validation
   - Exit codes: 0 = pass, 1 = errors, 2 = warnings only
   - Output format: file, line, severity, rule, message, suggestion

4. **`rules.md`** — Complete catalog of validation rules organized by category:
   - **Structural:** required fields per template, field types, GUID format
   - **References:** material exists in registry, template exists, exit targets exist
   - **FSM:** states referenced in transitions exist, initial_state is valid
   - **Nesting:** on_top/contents/nested/underneath only in rooms, depth limits
   - **Lint:** naming conventions, field ordering, on_feel required, sensory completeness
   - **Cross-file:** GUID uniqueness across all objects, keyword uniqueness

5. **`schemas.md`** — Schema definitions per template type (small-item, container, furniture, room, sheet). What fields are required, optional, their types and valid values. This is the contract meta-check enforces.

> **Wayne's directive:** This is P0. Must ship before the project grows. It's a tool Lisa uses to validate .lua object/room structure. Without it, every new object is a potential runtime bug that only surfaces during play-testing.

## Research + Build: Meta Object Validation & Compile-Time Safety

### The Problem

Lua is a script language with no compile-time type checking. Every object, room, and level in `src/meta/` is a `.lua` file — valid Lua, but potentially an invalid *object*. An LLM (or human) can write a file that:
- Parses as Lua but is missing required fields (`on_feel`, `material`, `guid`)
- Has a `material` value that doesn't exist in the registry
- Declares FSM `transitions` referencing states that don't exist
- Uses `on_top` nesting in an object file instead of a room file
- Has type mismatches (`weight = "heavy"` instead of `weight = 3`)

Today this is caught only at **runtime** — when a player triggers the broken code path. At 74 objects this is manageable. At 500 objects across 50 rooms, it's a ticking bomb.

### Wayne's Framing

> "We could write configuration-style tests that cheaply parse the text to determine correctness, or a better option might be to write a compiler specifically for the objects, rooms, and other meta objects that has a parser, tokenizer, etc. to verify the object is a correct object — not just correct Lua but a correct room/object. Think deeply about this problem space. The easiest answer might not be the best answer. Consider we might have 100s of objects and 100s of rooms. Also think about the best language — it might not be Lua."

### Direction: Custom Meta Compiler (Wayne's Decision)

Wayne has narrowed this to ONE approach: **a custom meta compiler** that uses compiler-style techniques (lexer → parser → semantic analysis) to validate .lua meta files. This is NOT:
- ❌ Config-style tests (too shallow)
- ❌ A different language for objects (engine still consumes .lua)
- ❌ A linter or regex-based checker (not rigorous enough)
- ❌ Compilation to native code (not the point)

**What it IS:** A front-end compiler that reads `.lua` object/room/level files and validates them against what the game engine expects. It produces validation results (errors, warnings), not machine code. The engine still `require()`s the `.lua` at runtime — the compiler runs before that, in CI or pre-commit.

**The compiler may be written in a different language than Lua** — choose the best language for building parsers/tokenizers (Python, TypeScript, Rust, Go, etc.).

### Research Questions (Frink + Bart)

1. **What are the categories of meta bugs we've actually seen?** Audit git history — what errors have LLMs introduced in `.lua` meta files? Classify by type (missing field, wrong type, invalid reference, structural error, semantic error).

2. **Compiler architecture:** What does the pipeline look like?
   - **Lexer:** Tokenize `.lua` table literals (we only need to parse the subset of Lua that objects use — `return { ... }` table constructors)
   - **Parser:** Build an AST of the object definition (fields, nested tables, values)
   - **Semantic analysis:** Validate against schemas per template type:
     - Object: required fields (id, name, keywords, material, on_feel), valid material references, GUID format
     - Room: required fields, valid deep nesting syntax (on_top, contents, nested, underneath), exit targets exist
     - FSM: declared states match transitions, no orphan states
     - Cross-references: material exists in registry, template exists, GUIDs unique
   - **Output:** Error list with file, line, field, expected vs actual

3. **Language choice for the compiler:** Evaluate:
   - **Python** — rich parsing ecosystem (lark, pyparsing, PLY), fast to build, already in scripts/
   - **TypeScript/Node** — could share tooling with web build, good AST libraries
   - **Rust** — fast, excellent parser combinator libraries (nom, pest), overkill?
   - **Go** — simple, fast, good for CLI tools
   - **Lua itself** — dogfooding, but limited parsing libraries
   - Criteria: ease of building a Lua-subset parser, CI integration, team familiarity

4. **What subset of Lua do we actually need to parse?** Objects are `return { key = value, ... }` — nested table literals, strings, numbers, booleans, nil. No function calls, no control flow, no metatables in the data layer. How small is this subset?

5. **Scale analysis:** At 100 objects, 100 rooms, 20 levels — how many cross-references? What's the validation time budget? (Should be <5 seconds for full repo scan.)

### Deliverables

- [x] **Frink:** Research report — how do other game engines validate data-as-code? Dwarf Fortress RAW validators, Factorio prototype checking, modding community tools. Focus on compiler-style approaches. ✅ 38 bugs cataloged, 103 GUIDs verified, system GREEN.
- [x] **Bart:** Architecture proposal — design the compiler pipeline (lexer → parser → semantic analysis → output). Recommend implementation language. Define the schema format for each template type. Estimate LOC and build time. ✅ Lark grammar proven on 83/83 objects.
- [x] **Chalmers:** ~~Scope and prioritize~~ → **DECIDED: P0.** Wayne says ship it tomorrow. Plan the build phases (research AM → prototype PM → Lisa validates end of day). ✅ Shipped.
- [x] **Lisa:** Define acceptance criteria — what does "valid object" mean? List every check she wants the compiler to perform. This is HER tool. ✅ 144 acceptance checks across 15 categories.
- [x] **Smithers or Bart:** Build the compiler after Bart's architecture proposal. Target: CLI tool that Lisa runs on any .lua file and gets pass/fail with error messages. ✅ Smithers built `scripts/meta-check/check.py` — Python+Lark, 19/144 rules, 0 false positives.

---

## 🔴 P0-C: Meta-Check V2 — Full Meta Type Coverage

Meta-check v1 **shipped today** (March 25) and validates objects and rooms. But it skips 3 critical meta types entirely. This P0-C expands coverage.

### What V1 Covers (Shipped Today) ✅

- **Objects** (83 files in `src/meta/objects/`):
  - Required fields: `guid`, `id`, `name`, `on_feel`, `template`
  - GUID uniqueness and format validation
  - Material references (exists in registry)
  - FSM consistency (states/transitions/initial_state)
  - Template references
  - Cross-file checks (keyword collisions)
  - Sensory completeness (`on_feel`, `on_smell`, `on_listen`, `on_taste` coverage)

- **Rooms** (7 files in `src/meta/world/`):
  - GUID, id, name, description, exits structure
  - Instance references (template lookup)
  - Exit target validation (target room exists)
  - Nesting hierarchy validation (`on_top`, `contents`, `nested`, `underneath`)

### What V1 Skips (The Gap) ⚠️

Meta-check **detects** these types but has **no validation rules**:

- **Levels** (`src/meta/levels/`) — defined but not validated
  - Example: `src/meta/levels/level-01.lua` contains level metadata (progression, objectives)
  - Needs: required fields, transitions, object/room references

- **Injuries** (`src/meta/injuries/`) — defined but not validated
  - Example: `src/meta/injuries/bleeding.lua` defines damage types, effects, recovery
  - Needs: required fields, effect/state consistency, material interactions

- **Templates** (`src/meta/templates/`) — base definitions exist but unchecked
  - Example: `src/meta/templates/small-item.lua` defines schema for all small items
  - Needs: field inheritance chains, required vs optional field declarations, type contracts

### Deliverables

1. **Lisa** (Test/QA):
   - Define acceptance criteria for level, injury, and template validation
   - List every field that must exist, allowed values, cross-reference rules
   - Document what constitutes "valid level/injury/template"
   - **Target:** Complete before Smithers builds

2. **Smithers** (Parser/Tools):
   - Implement validation rules for all 3 types in `scripts/meta-check/check.py`
   - Add schema definitions for level, injury, template to `docs/meta-check/schemas.md`
   - Update `docs/meta-check/rules.md` with new rule categories
   - Ensure exit codes remain: 0=pass, 1=errors, 2=warnings
   - **Target:** Full coverage; zero false positives on existing 5 levels, 7 injuries, 5 templates

3. **Lisa** (Validation):
   - Run expanded tool against all meta files in repository
   - Document any false positives or ambiguous edge cases
   - Approve rules before merge to CI gate
   - **Target:** Green pass on entire `src/meta/` tree

4. **Bonus:** Implement more of Lisa's 144 acceptance criteria
   - V1 covers 19/144 = 13% ✓
   - V2 should expand coverage significantly with level/injury/template validation

### Dependencies

- **Depends on:** P0-B shipped (done ✓)
- **Lisa's criteria must come before Smithers builds**
- **Blockers:** None (v1 shipped successfully)
- **Merge gate:** All rules defined + Lisa approves before merge to main

---

## Carry-Over from 2026-03-24

### What SHIPPED Today (March 24) ✅

- ✅ **Armor System** — Material-derived protection mechanics (all 7 phases: A1-A7)
- ✅ **Equipment Event Hooks** — `on_wear` and `on_remove_worn` handlers for gear state transitions
- ✅ **Event_Output One-Shot System** — Flavor text framework for singular narrative moments
- ✅ **P1 Parser Bug Cluster** — 7 critical issues fixed (#137–145, #156)
- ✅ **Hit Synonym Cluster** — Resolves ambiguity on melee verb surface area (#141, #142, #143, #146, #157)
- ✅ **Decorative Prepositional Suffix Stripping** — Cleans player input (e.g., "examine at the pot" → "pot") (#154)
- ✅ **Search Drawer Accessible to Get** — Containment rules loosened for small objects (#149)
- ✅ **Ceramic Pot Degradation** — Multi-phase breakage FSM now works correctly (#155)
- ✅ **Tear Cloak to Hands** — Fabric destruction now deposits torn pieces in player hands (#134)
- ✅ **Brass Bowl Keyword Collision Fix** — Resolved semantic ambiguity with spittoon
- ✅ **BUG-050 Duplicate Display + on_open/on_close Hooks** — Event hooks fire correctly; no duplicate text (#125, #103)
- ✅ **On_Drop Fragility Tests** — Nelson's suite verifies breakage on impact (Pass 040)
- ✅ **Event_Output + Helmet Swap Tests** — Equipment event system validated

### What Did NOT Ship Today — Carry-Over (6 Items)

| Issue | Title | Owner | Category | Why Deferred |
|-------|-------|-------|----------|--------------|
| **#158** | Deploy March 24 Work to Live | Gil | Deployment | Not yet automated; manual gate pending approval |
| **#159** | Evening Newspaper (Edition 2) | Flanders | Content | Wayne directive D-NO-NEWSPAPER-PENDING — hold until P0s done |
| **#160** | Update Docs: event-hooks.md | Brockman | Documentation | Deferred pending on_wear/on_remove_worn final APIs |
| **#161** | Update Docs: effects-pipeline.md (v3.0 armor) | Brockman | Documentation | Deferred pending armor design doc completion |
| **#162** | Design: Injury-Causing Objects for Unconsciousness | Comic Book Guy | Design | Puzzle dependency; deferred until P0s ship |
| **#163** | Test: Material Audit CI Test | Nelson | CI/QA | Depends on meta-compiler rules (P0-B); write after compiler ships |

---

## Process Rules (Wayne's TDD-First Directives)

### Before Any Code Change

1. **Plan First:** If the change is >2 hours, write it to `plans/` or file a design doc.
2. **Test Coverage:** Before refactoring, ensure tests cover ALL existing behavior. Red → green → refactor → green.
3. **Commit Between Phases:** Each logical phase gets its own commit with a clear message. Include squad member credit if applicable.
4. **Deploy Gate:** Before merging to main, run `lua test/run-tests.lua` — all 1,088+ tests must pass.

### Refactoring Safety (for P0-A Engine Review)

**Sequence is non-negotiable (D-REFACTOR):**
1. Code review + proposal (Bart recommends splits)
2. Nelson writes tests covering ALL functions being moved
3. Baseline verification: tests pass on CURRENT code
4. EXECUTE refactor
5. Nelson re-runs tests: must stay green
6. Red test = revert and debug

### Decision Protocol

- After **any decision affecting multiple team members**, file:
  ```
  .squad/decisions/inbox/chalmers-DECISION-SLUG.md
  ```
- Scribe merges into `.squad/decisions.md` end of day
- Blocked decisions get logged and escalated to Wayne

---

## 🔴 P1: Carry-Over Fixes & Documentation (Ship Today if Time Permits)

### P1.1: #160 — Update `docs/event-hooks.md`

**Owner:** Brockman (Documentation)
**Depends on:** P0-B design validation
**Deliverable:** Extend event-hooks.md with:
- `on_wear` / `on_remove_worn` specifications
- Equipment event lifecycle (put → wear → remove_worn → drop)
- Examples: armor, rings, helms (how state transitions fire events)
- Test references: Pass 040 test suite

**Acceptance Criteria:**
- [x] `on_wear` / `on_remove_worn` documented with trigger conditions ✅
- [x] Lifecycle diagram added (state machine visualization) ✅
- [x] 2–3 worked examples from real objects (helm, cloak, armor) ✅
- [x] Test cross-references added ✅

---

### P1.2: #161 — Update `docs/effects-pipeline.md` (v3.0 Armor)

**Owner:** Brockman (Documentation)
**Depends on:** P0-B design validation
**Deliverable:** Extend effects-pipeline.md with armor interceptor (v3.0):
- How armor intercepts injury effects before they apply
- Damage reduction formula: `actual_damage = max(1, floor(incoming - protection))`
- Material-based protection lookup (e.g., leather → 2, plate → 4)
- Interaction with state-based degradation

**Acceptance Criteria:**
- [x] Armor interceptor stage documented in pipeline flow ✅
- [x] Damage calculation examples shown ✅
- [x] Material protection table linked from `src/engine/materials/` ✅

---

### P1.3: #158 — Deploy March 24 Work to Live Site

**Owner:** Gil (Web Build)
**Dependencies:** All March 24 features must be on main (already merged)
**Task:** Deploy compiled site to live web server

**Acceptance Criteria:**
- [x] Web build runs without errors: `npm run build` ✅
- [x] Lua code bundled via Fengari ✅
- [x] Live site passes smoke test (homepage loads, game starts) ✅
- [x] Deployment logged in `web/DEPLOY-LOG.txt` ✅

---

## 🔶 P2: Design & Backlog Triage

### P2.1: #162 — Design Injury-Causing Objects for Unconsciousness

**Owner:** Comic Book Guy (Game Design)
**Status:** Puzzle dependency; **hold until P0s ship**
**Question:** Which objects should trigger `unconscious` injury on player contact/use?
- Poison gas canister? Sleeping dust? Blunt melee? Electricity?
- Does this couple to self-infliction puzzle? (Wayne's design question D-13)

**Recommended Sequence:**
1. Wayne clarifies scope: which injury types trigger unconsciousness?
2. Design lists candidate objects and mechanics
3. Smithers implements verb handlers for each

---

### P2.2: Backlog Triage (21 Open Issues, #105–131)

**Owner:** Chalmers (Priority Review)
**Task:** Sort remaining backlog by impact and effort. Issues currently tracked:
- **Parser patterns:** #106 Prime Directive Tiers 1–5, #107–110 (tier-specific work)
- **Object/room design:** #111–120 (missing items for expanded map)
- **Verb expansion:** #121–125 (combat, self-infliction, perception verbs)
- **Test infrastructure:** #126–131 (test suite expansion, CI gates)

**Action:** This will be triaged after P0s land. No action required today.

---

## Dependencies Graph

```
P0-A: Engine Code Review
├─ Bart: Review + propose splits
├─ Nelson: Write tests for functions being moved
├─ Decision: Sequencing (refactor before or after P0-B?)
└─ Chalmers: Approve refactoring plan

P0-B: Custom Meta Compiler ("meta-check")
├─ Step -1: Research (30 min)
│   ├─ Frink: Git history audit → bug catalog
│   ├─ Bart: Lark grammar prototype on 5 real files
│   ├─ Lisa: Define acceptance criteria
│   └─ Bart: Validation that engine already does (avoid duplication)
├─ Step 0: Design Docs (1 hr)
│   ├─ Brockman + Bart create `docs/meta-check/` with:
│   │   ├─ overview.md
│   │   ├─ architecture.md
│   │   ├─ usage.md
│   │   ├─ rules.md
│   │   └─ schemas.md
│   └─ Lisa reviews + approves
├─ Step 1: Build (2–3 hr)
│   ├─ Bart or Smithers: Implement meta-check CLI tool (language: TBD, likely Python + Lark)
│   ├─ Ensure exit codes: 0=pass, 1=errors, 2=warnings
│   └─ Output: file, line, rule, message, suggestion
└─ Step 2: Validation (30 min)
    ├─ Lisa: Run on existing 74+ objects, 7 rooms
    ├─ Verify no false positives
    └─ Merge to CI gate

P0-C: Meta-Check V2 — Full Meta Type Coverage (depends on: P0-B ✓)
├─ Lisa: Define acceptance criteria for levels, injuries, templates
│   └─ Deliverable: Level/injury/template validation spec
├─ Smithers: Implement validation rules in check.py
│   ├─ Add schemas for 3 types to docs/meta-check/schemas.md
│   ├─ Add rules to docs/meta-check/rules.md
│   └─ Target: 5 levels + 7 injuries + 5 templates, zero false positives
└─ Lisa: Validate expanded tool on full src/meta/ tree
    ├─ Green pass on all objects, rooms, levels, injuries, templates
    └─ Merge to main

P1 (Carry-Over):
├─ #158: Deploy (depends on: main green, test suite pass)
├─ #160: event-hooks.md (depends on: P0-B review complete)
├─ #161: effects-pipeline.md (depends on: P0-B review complete)
└─ Conditional: #159 (Evening newspaper, on hold per D-NO-NEWSPAPER-PENDING)

P2 (Design):
└─ #162: Injury-causing objects (depends on: P0s shipped, Wayne clarification on self-infliction)

BLOCKERS:
- P0-A sequencing → Chalmers decision (before or after meta-compiler?)
- P0-B: Python + Lark tool naming + location → Wayne decision (RESOLVED: Python + Lark, scripts/meta-check/)
- Deploy: Manual approval → Wayne/Gil decision
```

---

## Open Questions for Wayne (Resolve Before End of Day)

1. **P0-A Sequencing:** Should we refactor `verbs/init.lua` (and other large files) BEFORE or AFTER meta-compiler ships?
   - Refactor first: Cleaner code, easier for meta-check to validate → +3 hr work
   - Meta-check first: Validate current sprawling code, then refactor with safety net → +0 hr today (risk: harder to refactor later)

2. **P0-B Tool Details:**
   - Confirmed language: Python + Lark parser? Or different?
   - Tool naming: `meta-check` script location? (`scripts/meta-check/` or `src/meta-check/`?)
   - Build-time integration: Should CI run meta-check as a gate?

3. **Deploy Timing:** Should we deploy #158 (March 24 work) before starting refactoring work?

4. **#159 (Newspaper):** Confirm hold until P0s complete? (Currently blocked by D-NO-NEWSPAPER-PENDING)

---

---
