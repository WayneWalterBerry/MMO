# Phase 2 PARSER & VERB Plan Review — Smithers Assessment

**Reviewer:** Smithers (Parser/Verb Specialist)  
**Plan:** `plans/npc-combat-implementation-phase2.md`  
**Scope:** NPC + Combat Phase 2 (WAVE-0 through WAVE-5)  
**Date Reviewed:** 2026-03-26  

---

## Review Summary

**Waves requiring Smithers work:**
- **WAVE-3:** Combat witness narration (Track 3C)
- **WAVE-5:** Eat/drink verb extensions (Track 5B)

**Total files under Smithers ownership:** 2 modified  
**Estimated LOC:** ~80–120 (narration + verbs)

---

## Detailed Findings

### ✅ **Verb Extensions — Eat/Drink/Cook**

**Status:** ✅ **WELL-DEFINED** (WAVE-5, Track 5B)

**Coverage:**

| Verb | Status | Plan Details |
|------|--------|--------------|
| `eat` | ✅ | Check `food.edible`, verify `restricts` flags (disease blocks), consume item, apply `nutrition`, emit sensory feedback |
| `drink` | ✅ | Same pattern, `restricts.drink` (rabies blocks), check liquid container state |
| `cook` | ❌ | **NOT INCLUDED** — Hard boundary D-R5: *"no cooking, recipes, or spoilage-driven creature behavior"* |
| `feed` | ⚠️ | **NOT MENTIONED** — No `feed` verb planned; food used only as bait mechanic (creature consumes autonomously) |

**Aliases specified:**
- `eat`/`consume`/`devour` ✅
- `drink`/`sip`/`quaff` ✅

**Implementation location:** `src/engine/verbs/survival.lua` (CREATE), `src/engine/verbs/init.lua` (MODIFY — register aliases)

**Tests:** `test/food/test-eat-drink.lua` (~15 tests) covers keyword disambiguation, dark-mode eat, rejection of non-food, rabies block on drink, spoilage warnings.

**Finding:** Plan is **complete for eat/drink scope**. Cook scope intentionally deferred (Phase 2.5+). Feed verb **absent but acceptable**—bait system uses creature drives, not explicit player `feed` command.

---

### ⚠️ **Combat Witness Narration — Light-Dependent**

**Status:** ⚠️ **SPECIFIED BUT IMPLEMENTATION DETAILS SPARSE** (WAVE-3, Track 3C)

**Coverage:**

| Condition | Narration Type | Details |
|-----------|---|---------|
| **Same room + light** | ✅ Visual | Full third-person framing via `narration.describe_exchange()` |
| **Same room + dark** | ✅ Audio-only | Severity-keyed: GRAZE→scuffle, HIT→yelps, CRITICAL→death |
| **Adjacent room** | ✅ Distant audio | 1 line max |
| **Out of range** | ✅ Silence | Nothing emitted |

**Line cap enforcement:** ≤2 lines/exchange (same room), 1 line (adjacent), ≤6 lines/round (aggregate)

**Implementation location:** `src/engine/combat/narration.lua` (MODIFY)

**Context from Phase 1:** Combat narration engine exists (146 LOC, `src/engine/combat/narration.lua`). Spec assumes **existing infrastructure**—no mention of creating `narration.lua` from scratch.

**Missing details:**
- ⚠️ No code pseudocode for light detection in narration path
- ⚠️ No specification for "audio-only" severity tier (which injury class maps to which sound?)
- ⚠️ No guidance on NPC-vs-NPC narration message authoring (are messages generic template-driven or creature-specific?)

**Finding:** Narration system is **architecturally sound** but **implementation details deferred to gate validation**. Light-dependency is clear; audio-tier mapping needs clarification during implementation.

---

### ⚠️ **New Nouns — Creature Keywords & Embedding Updates**

**Status:** ⚠️ **KEYWORDS SPECIFIED, EMBEDDING INDEX UPDATES NOT MENTIONED**

**Creature keywords defined:**
- Cat: `{"cat", "feline"}`
- Wolf: `{"wolf"}`
- Spider: `{"spider"}`
- Bat: `{"bat"}`
- Rat (existing, phase 1): `{"rat", "rodent"}`

**Food keywords defined:**
- Cheese: `{"cheese", "wedge", "food"}`
- Bread: `{"bread", "crust", "food"}`
- Spider-web: `{"web", "spider web", "cobweb", "silk"}`

**Parser implications:**

| Tier | Coverage | Status |
|------|----------|--------|
| **Tier 1 (Exact alias)** | Creature IDs map to keywords | ✅ Keywords listed in creature `.lua` |
| **Tier 2 (Embedding)** | `assets/parser/embedding-index.json` | ⚠️ **NOT MENTIONED** — no update directive |
| **Tier 3–5 (GOAP, Context, Fuzzy)** | Fallback resolution | ✅ Existing tiers apply |

**Multi-target disambiguation scenario:**
- Room with cat, rat, spider, bat (4+ creatures)
- Player types: `attack cat` vs `attack rat`

**Plan coverage:** ✅ **Tier 1 exact match handles this** — creature keywords unique, no collision. BUT:
- ⚠️ No embedding index entries = Tier 2 matching bypassed
- ⚠️ No fuzzy matching (Tier 5) defined for creature name typos (e.g., `attack ca` → should suggest `cat`)

**Finding:** Plan **assumes existing embedding infrastructure**. No explicit directive to update `embedding-index.json` with new creature/food embeddings. **Risk:** Tier 2 semantic matching (e.g., "living thing", "animal", "food scent") will miss new nouns until index is rebuilt.

**Recommendation:** Clarify whether Tier 2 embedding rebuild is Nelson's responsibility (WAVE-1 gate check) or deferred post-Phase 2.

---

### ✅ **Multi-Target Disambiguation**

**Status:** ✅ **WELL-HANDLED BY EXISTING PARSER**

**Scenario:** `attack cat` with cat, rat, spider, bat in room

**Resolution:**
1. **Tier 1 (exact alias):** `"cat"` matches creature keyword `"cat"` → direct lookup, no ambiguity ✅
2. Creature uniqueness enforced by `context.registry` (GUID-indexed, unique IDs per instance)
3. Ambiguity case (`attack animal` with multiple creatures): **Deferred to Tier 5 fuzzy** — plan shows `test-fuzzy-noun.lua` tests exist (Phase 1)

**Context window tracking:** ✅ Tier 4 context remembers recent targets, so `attack rat` then `attack` alone → recycles rat target

**Finding:** Plan **correctly relies on existing disambiguation infrastructure**. No new parser logic required. Creature keywords are intentionally unique (small, medium, tiny sizes help distinguish at a glance).

---

### ✅ **Headless Mode Support**

**Status:** ✅ **COMPREHENSIVELY SPECIFIED**

**Coverage:**

| Feature | Headless Support | Details |
|---------|---|---------|
| **Narration** | ✅ | Audio-only tier triggers in dark rooms; text output to stdout, no TUI prompts |
| **Eat/drink** | ✅ | Tested via `echo` + pipe; no UI interaction required |
| **Bait mechanic** | ✅ | Creature movement + consumption logged as narration; fully deterministic with seed |
| **Disease progression** | ✅ | FSM tick-based; seeded `math.randomseed(42)` for reproducibility |
| **Combat** | ✅ (Phase 1 baseline) | Existing combat works in headless; NPC-vs-NPC adds no UI dependencies |

**Testing methodology:**

```bash
echo "command1\ncommand2\n..." | lua src/main.lua --headless
```

**LLM scenarios documented:**
- P1-A: Creatures load (static checks)
- P2-D: Combat narration (lit visual) ✅ Headless
- P2-E: Combat in dark (audio-only) ✅ Headless
- P2-P1: Rabies + disease progression ✅ Headless (seeded)
- P2-P3: Bait + food ✅ Headless
- P2-P4: End-to-end integration ✅ Headless

**Determinism rule:** `math.randomseed(42)` in headless mode; if test fails, retry with 43, 44 (max 3 seeds per scenario).

**Finding:** Plan is **exemplary**. All new features have headless-compatible LLM walkthroughs. **No additional work required from Smithers** — verbs inherit headless support from existing engine.

---

### ✅ **Error Messages — Standardization**

**Status:** ✅ **CONSISTENT PATTERN**

**Standardized error strings:**

| Context | Message Pattern | Example |
|---------|---|---------|
| Object not found | `err_not_found(context, noun)` | *"You don't see that."* |
| Can't eat non-food | *"You can't eat that."* | Line 573 |
| Spoiled food warning | Warning message (not specified) | Line 573 — implementation detail |
| Rabies blocks drink | `restricts.drink` active | Verb checks `restricts` table before action |
| Food consumed | Item removed from inventory + registry | Line 571 |

**Error handling location:** `src/engine/verbs/survival.lua` (Smithers responsibility)

**Consistency with existing verbs:** ✅ Error patterns match existing verb handlers (look, take, attack, etc.) — use `err_*` functions from verb module.

**New message required:**
- *"The cheese smells rotten."* (spoiled food warning) — specify in `survival.lua`

**Finding:** Plan is **well-standardized**. Error strings follow existing conventions. **Single new message** (spoiled warning) must be added with clear, diegetic flavor consistent with existing tone.

---

### ✅ **File Ownership — Smithers Waves**

**Status:** ✅ **CLEAR SCOPE DEFINITION**

**WAVE-3 (Combat Witness Narration):**

| File | Action | Lines | Owner |
|------|--------|-------|-------|
| `src/engine/combat/narration.lua` | MODIFY | ~40–50 new | Smithers |

**Responsibility:**
- Extend `narration.describe_exchange()` with light-awareness
- Add audio-tier severity mapping
- Enforce line cap (≤6 lines/round aggregate)
- Emit witness narration for NPC-vs-NPC and player-witness scenarios

**Dependencies:** Depends on GATE-2 (Creature Generalization). Bart completes creature `attack` action entry; Smithers adds witness output.

**WAVE-5 (Eat/Drink Verbs):**

| File | Action | Lines | Owner |
|------|--------|-------|-------|
| `src/engine/verbs/survival.lua` | MODIFY | ~60–80 | Smithers |
| `src/engine/verbs/init.lua` | MODIFY | ~5–10 | Smithers |

**Responsibility:**
- Implement `eat` verb: find, validate `food.edible`, check `restricts`, consume, emit sensory
- Implement `drink` verb: similar, check for `restricts.drink` (rabies block)
- Register aliases in `init.lua`

**Dependencies:** Depends on GATE-4 (Disease System). Rabies `restricts.drink` must exist before verb checks it.

**Cross-wave file map confirms:** No file modified by two agents in same wave. Smithers doesn't conflict with Bart, Flanders, or Nelson.

**Finding:** Scope is **clearly delineated**. Two waves, two files, ~100–150 LOC total. **No scope creep identified.**

---

### ⚠️ **Missing or Deferred Items**

| Item | Status | Reason | Impact |
|------|--------|--------|--------|
| Cooking verbs | ❌ | Design decision D-R5 (hard boundary) | None — explicitly out of scope |
| `feed` verb | ❌ | Bait system autonomous; no player verb needed | None — design choice |
| Embedding index rebuild | ⚠️ | Not assigned; possible Nelson task | Minor — existing fallback tiers work |
| Audio tier sound effects | ⚠️ | Message templates specified, voices undefined | None — text-based game; narration is text |
| Spoilage-driven NPC behavior | ❌ | D-R5 boundary | None — creatures hunt fresh food only |
| Creature-specific narration templates | ⚠️ | Generic templates assumed | Minor — implementation detail, design pattern documented |

---

## Recommendations for Smithers

1. **WAVE-3 implementation:** Clarify audio-tier mapping at gate review:
   - GRAZE → what text? (`"A faint scuffle."` ?)
   - HIT → what text? (`"Sharp yelp."` ?)
   - CRITICAL → what text? (`"Death cry."` ?)

2. **WAVE-5 implementation:** Reserve ~20 LOC for spoilage message variants:
   - Fresh: (normal description)
   - Stale: *"The cheese is hard and dusty."*
   - Spoiled: *"The cheese smells rotten."*

3. **Parser integration check:** After WAVE-1, confirm embedding index update status with Nelson. If deferred, document impact on Tier 2 matching for new nouns.

4. **Test-first protocol:** Implement `test/food/test-eat-drink.lua` **before** modifying `survival.lua`. Nelson provides test spec; Smithers writes implementation to pass tests.

---

## Sign-Off

**Reviewed by:** Smithers (Parser/Verb Specialist)  
**Status:** ✅ **APPROVED FOR EXECUTION**

**Confidence level:** 🟢 High — plan is architecturally sound, scope is clear, dependencies are documented, headless support is comprehensive.

**Ready for:** WAVE-3 (after GATE-2) and WAVE-5 (after GATE-4)

---

## Appendix: Key Reference Files

- `plans/npc-combat-implementation-phase2.md` (WAVE-3, 3C: lines 433–442; WAVE-5, 5B: lines 567–576)
- `src/engine/combat/narration.lua` (existing baseline, 146 LOC)
- `src/engine/verbs/init.lua` (verb registration module)
- `.squad/decisions.md` (D-HEADLESS, D-VERBS-REFACTOR-2026-03-24)
