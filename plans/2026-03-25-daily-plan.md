# Daily Plan — 2026-03-25

**Owner:** Wayne "Effe" Berry
**Focus:** 🔴 P0 — Engine Refactoring + Meta Compiler (Completed Early — Remaining Work Below)
**Created:** 2026-03-24
**Status:** Most of this plan was executed early during the March 24 session. See March 24 daily plan for full "March 25 Work Shipped Early" section.

---

## ⚠️ Plan Status: 95% COMPLETE (Shipped During March 24 Session)

The following work was scheduled for March 25 but completed during the March 24 evening session:
- ✅ **P0-A:** Engine Code Review (Bart + Nelson review, refactoring sequencing decided)
- ✅ **P0-B:** Meta-Check V1 (research + design + implementation, 19 rules, zero false positives)
- ✅ **P0-C:** Meta-Check V2 (expanded to 160 rules, full meta-type coverage, PASS WITH NOTES)
- ✅ **#160:** event-hooks.md documentation
- ✅ **#161:** effects-pipeline.md v3.0 documentation
- ✅ **#158:** Deploy to live site
- ✅ **#163:** Material audit CI gate
- ✅ **Playtest bug cluster:** 7 issues filed and fixed same evening (#167–173)

**Result:** 40+ issues closed, 3,342 tests passing, engine refactored, meta-check shipped.

---

## 🔴 Remaining Work (3 Items — Tomorrow's Fresh Planning)

### #106 — Prime Directive Tiers 1-5 (Parser Architecture & Implementation)

**Owner:** Smithers (Parser)  
**Category:** Parser Expansion  
**Status:** Blocked, awaiting design clarity

**Description:** Implement Tiers 1-5 of the Prime Directive parser pipeline (Tier 1 = exact alias lookup, Tier 2 = embedding-based matching, Tier 3 = GOAP planning, Tier 4 = context window, Tier 5 = fuzzy resolution).

**Prerequisite:** Define formal Tier specs, success criteria, and dependency sequencing.

---

### #126 — Room 3 Design & Implementation

**Owner:** Moe (World Design)  
**Category:** World Expansion  
**Status:** Blocked, awaiting design review

**Description:** Design and implement Room 3 (next area in Level 1). Define topology, fixtures, objects, exits. Add tests and narrative hooks.

**Prerequisite:** Room 2 completion + Wayne approval of Room 3 layout.

---

### #162 — Design: Injury-Causing Objects for Unconsciousness

**Owner:** Comic Book Guy (Game Design)  
**Category:** Design  
**Status:** Hold, awaiting Wayne clarification

**Description:** Determine which objects should trigger `unconscious` injury on player contact/use/wear. Scope: poison gas canister? Sleeping dust? Blunt melee? Electricity? Links to self-infliction puzzle design (D-13).

**Prerequisite:** Wayne clarification: which injury types trigger unconsciousness? Scope of self-infliction mechanics?

**Note:** This is a **design** task; implementation will follow after specs are locked.

---

## Session Statistics (March 24–25 Combined)

| Metric | Value |
|--------|-------|
| **Issues Closed** | 40+ |
| **Tests Added (Pre-Refactor Baseline)** | 172 |
| **Total Assertions (Post-Refactor)** | 2,670 |
| **Test Pass Rate** | 100% (3,342 tests) |
| **Objects Validated by Meta-Check** | 83 |
| **Rooms Validated by Meta-Check** | 7 |
| **Levels Validated by Meta-Check** | 5 |
| **Injuries Validated by Meta-Check** | 7 |
| **Templates Validated by Meta-Check** | 5 |
| **Meta-Check V1 Rules Implemented** | 19/144 |
| **Meta-Check V2 Rules Implemented** | 159/160 |
| **Bug Fixes (Playtest Cluster)** | 7 (#167–173) |

### Key Outcomes

✅ **Engine Code Review Complete** — All files >500 lines reviewed; erbs/init.lua split into 12 focused modules  
✅ **Meta-Check V1 Shipped** — 19 validation rules, zero false positives on 90+ meta files  
✅ **Meta-Check V2 Shipped** — Full meta-type coverage (objects, rooms, levels, injuries, templates)  
✅ **Documentation Updated** — event-hooks.md and effects-pipeline.md v3.0 complete  
✅ **Deployment Complete** — March 24 features live on web server  
✅ **Playtest Bugs Fixed** — 7 issues identified and resolved same evening  

---

## Carry-Over Notes

All major P0 work and carry-over documentation shipped during the March 24 session. See the March 24 daily plan for "March 25 Work Shipped Early" section for complete details.

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
