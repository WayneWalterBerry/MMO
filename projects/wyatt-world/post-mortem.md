# Wyatt's World Post-Mortem

**Author:** Kirk (Project Manager)  
**Date:** 2026-03-30  
**Requested by:** Wayne Berry  
**Status:** 97 open bugs, 0 closed. World shipped but unplayable.

---

## 1. Timeline

All times PDT, 2026-03-29. Wayne left for a party after commit `03791e1` (4:59 PM).

| Time | Commit | Event |
|------|--------|-------|
| 4:04 PM | `e2a8a7a` | Design doc: Mr. Beast world concept (CBG) |
| 4:42 PM | `b18b1fe` | Implementation plan v2.0 (Bart) |
| 4:56 PM | `ddf2573` | Plan v2.1 — fixed 3 blockers + 12 concerns |
| 4:59 PM | `03791e1` | Scribe merge — 8 decisions + orchestration logs |
| **5:28 PM** | `177e8c8` | **Folder restructure — manor isolation** |
| **5:42 PM** | `7e0753b` | **WAVE-0: Multi-world engine + E-rating (Bart)** |
| **5:47 PM** | `b491041` | **WAVE-0: TDD test suite (Nelson)** |
| **5:55 PM** | `460bd96` | **WAVE-1c: 7 puzzle specs (Sideshow Bob)** |
| **5:57 PM** | `aaeea74` | **WAVE-1a: 7 rooms + level definition (Moe)** |
| **6:17 PM** | `c4247b1` | **WAVE-1b: 68 objects (Flanders)** |
| **6:24 PM** | `d30c07a` | **WAVE-2a: Parser polish (Smithers)** |
| **6:28 PM** | `9b9582d` | **WAVE-2b: 140 tests, all pass (Nelson)** |
| **6:32 PM** | `03f408e` | Scribe: orchestration logs |
| **6:37 PM** | `c1d4c46` | **WAVE-3: Web deploy (Gil)** |
| **6:39 PM** | `4cc1853` | Board marked "V1.0 PLAYABLE" ← premature |
| 8:56 PM | `b9b7106` | Fix #1: world URL param not loading content |
| 8:57 PM | `fc4e5a1` | Docs: URL fix logged |
| 9:00 PM | `938ac33` | Fix #2: CI deploy gate blocked by pre-existing failures |
| 9:09 PM | `bbd710b` | **Full walkthrough: 0/7 puzzles completable** |
| 9:09 PM | `3cf438a` | Fix #3: Options module missing from engine bundle |

**Key observation:** 2 hours from plan to "V1.0 PLAYABLE" (4:42 PM → 6:39 PM). Then 2.5 hours of emergency fixes (8:56 PM → 9:09 PM) — and the world is still unplayable.

---

## 2. Issue Count & Categories

**97 open issues, 0 closed.** Filed by 12 Nelson test instances during walkthrough.

| Category | Count | Severity |
|----------|-------|----------|
| **Empty instances (no objects in rooms)** | 14 | 🔴 Critical — game unplayable |
| **Darkness (no light_level)** | 10 | 🔴 Critical — rooms are pitch black |
| **Options/hints blank** | 7 | 🟡 High — hint system silent |
| **E-rating verb leaks** | 6 | 🟡 High — combat verbs visible to kids |
| **Missing verbs (press, enter, set)** | 6 | 🟡 High — puzzles unsolvable |
| **UX: kid-unfriendly language** | 13 | 🟠 Medium — "grope", combat in help |
| **Content: complex words** | 19 | 🟢 Low — reading level violations |
| **Content: scary words** | 2 | 🟢 Low — "darkness", "dark" |
| **Parser mishandling** | 5 | 🟠 Medium — kid input misrouted |
| **Polish (positive observations)** | 5 | ✅ Info — things that work well |
| **Other bugs** | 10 | Mixed |

### The Two Critical Blockers

1. **All 7 rooms have `instances = {}`** — Flanders created 68 object `.lua` files but Moe never wired them into room `instances` arrays. Objects exist on disk but aren't placed in any room. The world has no interactive content.

2. **No `light_level` on any room** — The Manor starts at 2 AM (darkness by design). Wyatt's World is for a 10-year-old — it should never be dark. But no room declares `light_level`, so the darkness mechanic applies. Every room is pitch black.

---

## 3. Root Causes

### RC-1: Object ↔ Room Wiring Gap (Critical)

**What happened:** WAVE-1a (Moe: rooms) and WAVE-1b (Flanders: objects) ran in parallel per the plan. Moe created 7 rooms with `instances = {}`. Flanders created 68 objects. Neither agent wired objects into rooms — each assumed the other would.

**Why it happened:** The implementation plan specified parallel execution for WAVE-1a/1b but never explicitly assigned the integration step. The plan says "~70 objects" for Flanders and "7 room .lua files" for Moe, but the critical step — populating each room's `instances` array with object GUIDs — fell between two agents' scopes.

**The plan gap:** No wave or gate checks "are objects wired into rooms?" GATE-1 says "All rooms load. All objects register." — both are true (files load, GUIDs register). But "register" ≠ "placed in a room."

### RC-2: Light Level Not Set (Critical)

**What happened:** The Manor uses darkness as a core mechanic (game starts at 2 AM). Wyatt's World is an E-rated kids' game that should never be dark. But the rooms copied the Manor's implicit darkness pattern — no `light_level` field means dark-by-default.

**Why it happened:** The plan mentions E-rating enforcement for combat verbs but never addresses lighting. The design doc says "No darkness" but this wasn't translated into a specific technical requirement ("every room must have `light_level = 1`" or `allows_daylight = true`).

### RC-3: Engine Bundle Stale (High)

**What happened:** The Options system (`src/engine/options/`) was built in a prior session. When Gil ran `build-engine.ps1` for WAVE-3, the options module wasn't in the bundle manifest. The web build crashed on load.

**Why it happened:** `build-engine.ps1` doesn't auto-discover `src/engine/` subdirectories — new modules must be manually added. No one updated the build script when Options was merged. This is a systemic gap: any new engine module silently vanishes from the web build.

### RC-4: Deploy Pipeline Fragility (Medium)

**What happened:** Three separate deploy issues required manual intervention:
1. `?world=wyatt-world` URL didn't work — world content wasn't copied to Pages correctly
2. `run-before-deploy.ps1` blocked on pre-existing test failures from other modules
3. CI workflow had to be patched with `if: always()` to bypass test gate

**Why it happened:** The deploy gate was designed as a binary pass/fail — any test failure blocks everything. Pre-existing failures from unrelated modules (sound, combat) blocked Wyatt deployment. The fix (`if: always()`) swings too far the other direction — now nothing blocks deploy.

### RC-5: No Browser Verification (Medium)

**What happened:** WAVE-2b ran 140 tests — all CLI-based via `lua test/run-tests.lua --headless`. All passed. But no test ever loaded the web build in a browser. The options crash, world URL routing failure, and bundle staleness were all web-only failures invisible to CLI tests.

**Why it happened:** The plan has no "browser smoke test" gate. GATE-3 says "Web live" but there's no automated verification that the deployed URL actually loads and runs.

### RC-6: Premature "V1.0 PLAYABLE" Declaration (Process)

**What happened:** Board was marked "V1.0 PLAYABLE" at 6:39 PM. Full walkthrough at 9:09 PM found 0/7 puzzles completable. The status was set based on wave completion, not playability verification.

**Why it happened:** The autonomous execution protocol considered wave completion = success. No agent played the game end-to-end before declaring victory.

---

## 4. What the Plan Missed

| Gap | What Should Have Been There |
|-----|---------------------------|
| **Integration step** | WAVE-1 needed a WAVE-1e: "Wire objects into room instances" — owned by Moe after Flanders delivers objects |
| **Light_level requirement** | WAVE-1a spec should mandate `light_level = 1` for E-rated worlds (or engine default) |
| **GATE-1 playability check** | Gate should include: "Player can see, move, and interact with at least 1 object in each room" |
| **Browser smoke test** | GATE-3 should include: "Load URL in headless browser, verify no JS errors, verify intro text appears" |
| **Engine bundle manifest check** | Pre-deploy should verify all `src/engine/*/init.lua` modules are in the web bundle |
| **Object placement validation** | Nelson's tests should verify `#room.instances > 0` for every non-empty room |
| **Walkthrough before ship** | Plan should require an end-to-end walkthrough (CLI or browser) before marking V1.0 |

---

## 5. What Worked Well

Credit where due — the autonomous execution got a lot right:

- ✅ **Multi-world engine** — Bart's WAVE-0 work is solid. World loader, content_root, --world flag all work.
- ✅ **E-rating enforcement** — Combat verbs are properly blocked at the engine level.
- ✅ **68 well-crafted objects** — Flanders' objects have good sensory descriptions, kid-friendly tone.
- ✅ **7 rooms with good atmosphere** — Room descriptions, smell, listen all noted as "excellent" by Nelson.
- ✅ **Parser handles kid language** — Preambles, politeness, questions all handled well.
- ✅ **Hub navigation** — All 6 directions work from the central studio.
- ✅ **140 unit tests pass** — Test infrastructure is solid.
- ✅ **2 hours from plan to all waves complete** — Execution speed was impressive.

The failure mode is narrow but devastating: content exists but isn't connected.

---

## 6. Recommendations

### R1: Add "Integration Wave" to Implementation Plan Skill (Critical)

When content is created by parallel agents (rooms + objects), the plan must include an explicit integration step where objects are wired into rooms. This should be a distinct wave or sub-wave with its own agent assignment.

**Skill update:** `implementation-plan` skill, Pattern 4 (parallel waves) should add: "If Wave-N has parallel content tracks that must reference each other, add a Wave-N+0.5 integration step with a single owner."

### R2: Add "Playability Gate" to Every World Ship (Critical)

No world can be marked "V1.0 PLAYABLE" until an agent:
1. Boots the world (`lua src/main.lua --world <id> --headless`)
2. Issues `look` in every room and confirms visible objects
3. Completes at least 1 puzzle end-to-end
4. If web: loads the URL and confirms no crash

**Skill update:** `implementation-plan` skill should require a "Playability Gate" as the final gate for any world project.

### R3: Auto-Discover Engine Modules in Web Bundle (High)

`build-engine.ps1` should scan `src/engine/*/init.lua` at build time and include all modules automatically. No manual manifest. New modules should never silently disappear from the web build.

**Owner:** Gil  
**Deliverable:** Update `build-engine.ps1` to glob `src/engine/*/init.lua`

### R4: Deploy Gate Should Be "New Test Failures Only" (High)

Replace the binary pass/fail deploy gate with a differential check:
- Run tests, capture results
- Compare against known baseline failures
- Block deploy only on NEW failures
- Remove the `if: always()` workaround

**Owner:** Nelson + Gil  
**Deliverable:** Update `run-before-deploy.ps1` and `squad-deploy.yml`

### R5: E-Rated Worlds Must Default to Lit (Medium)

The engine should auto-set `light_level = 1` for any room in an E-rated world, OR the room template for E-rated worlds should include it. Darkness should never be the default experience for kid content.

**Owner:** Bart  
**Deliverable:** Engine check in world loader: if `world.rating == "E"`, enforce `light_level = 1` on all rooms

### R6: Nelson Must Verify Object Placement (Medium)

Add a standard test: for every room with `instances` defined, verify at least 1 object is present unless the room is explicitly marked as empty. The test `#room.instances > 0` would have caught the critical blocker instantly.

**Owner:** Nelson  
**Deliverable:** Add placement test to `test-wyatt-rooms.lua` (and as standard for all worlds)

### R7: Autonomous Execution Needs End-to-End Verification (Process)

The autonomous execution protocol should not declare victory after wave completion. Add a final step: "Play the game." A 10-command walkthrough would have caught both critical blockers in seconds.

**Skill update:** `autonomous-execution` protocol should add a "verification walkthrough" step after the final wave, before status is set.

---

## 7. Skill Updates Needed

| Skill | Update | Priority |
|-------|--------|----------|
| `implementation-plan` | Add integration wave for parallel content tracks | 🔴 Critical |
| `implementation-plan` | Add playability gate as mandatory final gate | 🔴 Critical |
| `implementation-plan` | E-rated worlds must specify lighting requirements | 🟡 High |
| `web-publish` / Gil workflow | Auto-discover engine modules in bundle | 🟡 High |
| `web-publish` / Gil workflow | Browser smoke test (headless load + verify) | 🟡 High |
| `autonomous-execution` | Add end-to-end walkthrough before declaring complete | 🟡 High |
| `run-before-deploy.ps1` | Differential test baseline (not binary pass/fail) | 🟠 Medium |
| `work-down-issues` | Will be needed to burn down the 97 issues | 🟠 Medium |

---

## 8. Issue Burndown Plan

97 issues need resolution. Recommended approach:

| Wave | Issues | Owner | Description |
|------|--------|-------|-------------|
| **Fix-0** | ~14 | Moe + Flanders | Wire objects into room instances (the critical fix) |
| **Fix-1** | ~10 | Bart / Moe | Add light_level to all rooms |
| **Fix-2** | ~6 | Bart / Smithers | E-rating verb leaks (hit, harm, hurt, headbutt) |
| **Fix-3** | ~6 | Smithers / Bart | Missing verbs (press, enter, set, type, turn) |
| **Fix-4** | ~13 | Smithers | UX: kid-unfriendly language ("grope", combat in help) |
| **Fix-5** | ~19 | Flanders | Content: complex/scary words |
| **Fix-6** | ~7 | Smithers | Options/hints blank output |
| **Fix-7** | ~5 | Smithers | Parser mishandling |
| **Dedup** | ~17 | Kirk | Duplicate issues across Nelson instances (consolidate) |

**Estimated effort:** 3-4 sessions if waves are parallelized.  
**Note:** ~17 issues appear to be duplicates filed by different Nelson instances hitting the same bug. Deduplication should happen first.

---

## 9. Summary

**The autonomous build was a qualified success that failed the user.** The pipeline executed flawlessly — 7 agents, 4 waves, 140 tests, 68 objects, 7 rooms, 2 hours. But it built a house with no furniture inside. The objects exist. The rooms exist. Nobody connected them.

The root cause isn't technical — it's process. Parallel content creation without an integration step is the #1 lesson. The #2 lesson: automated tests that don't test playability are testing the wrong thing. "All tests pass" and "the game is playable" are different statements.

**Top 5 fixes in priority order:**

1. Wire objects into rooms (Fix-0 — makes the world playable)
2. Add light_level to E-rated rooms (Fix-1 — makes rooms visible)
3. Update implementation-plan skill with integration wave + playability gate
4. Auto-discover engine modules in web bundle
5. Add end-to-end walkthrough to autonomous execution protocol

---

*Kirk, Project Manager — "We shipped a museum where every exhibit is in the warehouse."*
