# Level 1 Tutorial Coverage Analysis

**Author:** Comic Book Guy (Creative Director / Design Lead)  
**Date:** 2026-07-22  
**Status:** ANALYSIS COMPLETE  
**Purpose:** Determine whether Level 1 ("The Awakening") teaches the player every interaction they need for Level 2+.

---

## Executive Summary

Level 1 is **remarkably strong** as a tutorial. Across 14 puzzles, it covers the vast majority of the engine's interaction vocabulary and all major interaction patterns. However, there are **5 meaningful gaps** where the player will encounter verbs or patterns in Level 2+ that Level 1 never introduced. Three of these are addressable through minor tweaks to existing puzzles; two may need new content or can be left as intuitive.

**Verdict:** Level 1 is ~85% complete as a tutorial. The gaps are fixable without adding new puzzles — mostly through ensuring existing optional content explicitly requires the missing verbs.

---

## 1. Verb Coverage Matrix

### Engine Verb Inventory (from `src/engine/verbs/init.lua`)

The engine implements **35 primary verb handlers** plus **28 aliases**. Below is the full matrix.

| # | Primary Verb | Aliases | Level 1 Puzzle(s) That Teach It | Gap Status |
|---|---|---|---|---|
| 1 | **look** | — | 001 (room view), 005 (all rooms), 006, 007, 009, 012, 014 | ✅ Covered |
| 2 | **examine** | x, find, check, inspect | 001 (nightstand), 009 (crates), 012 (altar), 014 (effigies) | ✅ Covered |
| 3 | **read** | — | 003 (write on paper), 005 (sewing manual), 012 (scroll), 014 (tome, inscriptions) | ✅ Covered |
| 4 | **search** | — | 009 (grain sack) | ✅ Covered |
| 5 | **feel** | touch, grope | 001 (darkness navigation), 002 (bottle), 005 (all rooms), 006, 007, 009, 014 | ✅ Covered (HEAVILY — foundational) |
| 6 | **smell** | sniff | 002 (poison), 010 (oil vs wine bottles), 012 (incense) | ✅ Covered |
| 7 | **taste** | lick | 002 (poison — death trap) | ✅ Covered (as warning) |
| 8 | **listen** | hear | 005 (ambient sounds), 009 (rats), 011 (stairway ascent), 014 (crypt silence) | ✅ Covered |
| 9 | **take** | get, grab | 001 (matchbox, match), 005 (everything), 007 (brass key), 009 (crowbar, iron key), 014 (tome, dagger) | ✅ Covered (HEAVILY) |
| 10 | **pick** | — | Alias for take — implicit | ✅ Covered |
| 11 | **drop** | — | 004 (hand management) | ✅ Covered |
| 12 | **pull** | yank, tug, extract | 005/007 (pull rug), 005 (pull cork/drawer) | ✅ Covered |
| 13 | **push** | shove | 007 (push bed), 014 (push sarcophagus lid) | ✅ Covered |
| 14 | **move** | shift, slide | 007 (move rug, move bed) | ✅ Covered |
| 15 | **lift** | — | 014 (lift sarcophagus lid) | ✅ Covered |
| 16 | **uncork** | unstop, unseal | 005 (poison bottle cork) | ✅ Covered |
| 17 | **open** | — | 001 (drawer, matchbox), 005 (wardrobe, curtains), 006 (iron door), 007 (trap door), 008 (window), 009 (crate, grain sack) | ✅ Covered (HEAVILY) |
| 18 | **close** | shut | 005 (wardrobe, curtains) | ✅ Covered |
| 19 | **unlock** | — | 006 (iron door with brass key), 007 (trap door), 008 (window latch), 012 (crypt door) | ✅ Covered |
| 20 | **break** | smash, shatter | 005 (mirror), 008 (window) | ✅ Covered |
| 21 | **tear** | rip | 008 (bedsheet for rope) | ✅ Covered |
| 22 | **inventory** | i | 004 (hand management) | ✅ Covered |
| 23 | **light** | ignite, relight | 001 (candle with match), 010 (lantern), 012 (incense burner, candle stubs), 014 (candle stubs) | ✅ Covered (HEAVILY) |
| 24 | **extinguish** | snuff | **NOT REQUIRED by any puzzle** | ⚠️ GAP |
| 25 | **write** | inscribe | 003 (write on paper with pen or blood) | ✅ Covered |
| 26 | **cut** | slash | 003 (cut self for blood) | ✅ Covered |
| 27 | **prick** | — | 003 (prick self with pin) | ✅ Covered |
| 28 | **sew** | stitch, mend | 005 (sewing optional path) | ✅ Covered (optional) |
| 29 | **put** | place | 004 (put in sack), 012 (put candle in bowl) | ✅ Covered |
| 30 | **strike** | — | 001 (strike match on matchbox) | ✅ Covered |
| 31 | **wear** | don | 005 (cloak, sack-on-head comedy) | ✅ Covered |
| 32 | **remove** | doff | 005 (take off worn items) | ✅ Covered |
| 33 | **eat** | consume, devour | **NOT REQUIRED by any puzzle** | ⚠️ GAP |
| 34 | **drink** | quaff, sip | **NOT REQUIRED by any puzzle** (taste ≠ drink) | ⚠️ GAP |
| 35 | **pour** | spill, dump | 010 (pour oil into lantern) | ✅ Covered |
| 36 | **burn** | — | **NOT REQUIRED by any puzzle** (light ≠ burn) | ⚠️ GAP |
| 37 | **time** | — | 005 (time awareness for dawn mechanic) | ✅ Covered (implicit) |
| 38 | **sleep** | rest, nap | 005 (sleep until dawn alt path) | ✅ Covered (optional) |
| 39 | **set** | adjust | **NOT ENCOUNTERED — clock objects are future content** | 🔵 No Level 1 object uses this |
| 40 | **movement** | n/s/e/w/u/d, go, walk, enter, descend, ascend, climb | 005→006 (down), 006→009 (north), 009→011 (through), 011 (up/ascend), 008/013 (climb) | ✅ Covered |
| 41 | **help** | — | Always available | ✅ Covered |
| 42 | **pry** | — | 009 (pry crate with crowbar; alias for open) | ✅ Covered |

### Gap Summary

| Gap Verb | Severity | Reason |
|---|---|---|
| **extinguish** | 🟡 Medium | Engine supports it, candle has the transition, but no puzzle REQUIRES it. Player may never discover this verb exists. |
| **eat** | 🟢 Low | No food objects in Level 1. Intuitive verb — players know what "eat" means. |
| **drink** | 🟡 Medium | Poison bottle uses TASTE (death), not DRINK. Wine bottles exist in Storage Cellar but drinking isn't a puzzle mechanic. Player may confuse taste/drink. |
| **burn** | 🟢 Low | LIGHT is taught; BURN is a synonym that redirects to light. Edge case: burning paper/cloth as destruction isn't taught. |
| **set** | 🔵 N/A | Only applies to wall-clock object (hallway). No Level 1 clock. Not a gap — it's a Level 2 introduction. |

---

## 2. Interaction Pattern Coverage

### Patterns the Engine Supports vs. What Level 1 Teaches

| # | Interaction Pattern | Level 1 Coverage | Puzzles | Notes |
|---|---|---|---|---|
| 1 | **Darkness navigation (sensory-first)** | ✅ Core | 001, 002, 005 | FEEL as primary sense in darkness. Foundational. |
| 2 | **Container hierarchy (nested)** | ✅ Core | 001 (drawer→matchbox→match), 009 (crate→sack→key) | Taught twice at different scales. Excellent scaffolding. |
| 3 | **Compound tool actions (A + B → result)** | ✅ Core | 001 (strike match ON matchbox), 003 (cut self WITH knife) | Foundation of the tool system. |
| 4 | **Capability matching (tool provides X)** | ✅ Core | 001 (fire_source → candle), 009 (prying_tool → crate), 006 (key → lock) | Three distinct capability types taught. |
| 5 | **FSM state transitions (object mutation)** | ✅ Core | 001 (unlit→lit→spent), 005 (sealed→open wardrobe), 009 (sealed→open crate) | Multiple FSM examples. |
| 6 | **Lock-and-key (direct)** | ✅ Core | 006 (brass key → iron door), 007 (brass key → trap door), 012 (silver key → crypt) | Taught three times with escalating context. |
| 7 | **Spatial layering (ON/UNDER/BEHIND)** | ✅ Core | 007 (rug covers trap door, bed on rug) | Foundational spatial discovery. |
| 8 | **Movable furniture** | ✅ Core | 007 (push bed, move rug) | Core spatial manipulation. |
| 9 | **Consumable resources** | ✅ Core | 001 (7 matches, candle burn time), 010 (lantern oil) | Resource scarcity is recurring theme. |
| 10 | **Wearable equipment** | ✅ Optional | 005 (cloak, sack-on-head) | Taught via comedy and optional paths. |
| 11 | **Composite objects (detachable parts)** | ✅ Core | 005 (poison bottle cork, nightstand drawer) | Pull-to-detach pattern established. |
| 12 | **Skill acquisition (read-to-learn)** | ✅ Optional | 005 (sewing manual → sewing skill) | Optional but present. |
| 13 | **Crafting (combine materials)** | ✅ Optional | 005 (sew cloth with needle and thread) | Sewing is the V1 crafting demo. |
| 14 | **Trap/hazard (lethal consequence)** | ✅ Core | 002 (poison = death), 008 (jump = death) | Death as teacher — two distinct instances. |
| 15 | **Environmental storytelling (read-to-understand)** | ✅ Core | 012 (scroll reveals ritual), 014 (tome, inscriptions, effigies) | Narrative as puzzle. |
| 16 | **Boolean-AND trigger (multiple conditions)** | ✅ Core | 012 (incense burning AND flame offered) | First multi-condition puzzle. |
| 17 | **Deduction from observation** | ✅ Optional | 014 (effigies predict contents) | Obra Dinn-style inference. |
| 18 | **Pour/fill (liquid transfer)** | ✅ Optional | 010 (pour oil into lantern) | Liquid mechanics introduced. |
| 19 | **Vertical navigation (up/down)** | ✅ Core | 005→006 (descend), 011 (ascend) | U-shaped level architecture. |
| 20 | **Two-handed carry constraint** | ✅ Core | 004 (hands full → can't strike match) | Physical inventory taught via failure. |
| 21 | **Extinguish/relight cycle** | ⚠️ Gap | NOT taught | Candle can be extinguished/relit, but no puzzle requires it. |
| 22 | **Eat/drink (consumable ingestion)** | ⚠️ Gap | NOT taught | No food/water in Level 1. |
| 23 | **Burn-as-destruction** | ⚠️ Gap | NOT taught | LIGHT teaches fire-as-tool; BURN-as-destruction is different. |
| 24 | **Surface zones (put X ON Y)** | ✅ Core | 012 (put candle in/on offering bowl), 004 (put items in sack) | ON and IN both demonstrated. |

### Pattern Gap Summary

Three interaction patterns are NOT taught in Level 1:

1. **Extinguish/relight** — The candle FSM supports extinguish→relight, but no puzzle forces the player to blow out and relight a candle. If Level 2 has wind-gusting-out-candle scenarios or stealth-darkness moments, players won't know they can SNUFF and RELIGHT.

2. **Eat/drink** — No food or potable liquid exists in Level 1. If Level 2 introduces hunger, thirst, or potions, the player has zero practice.

3. **Burn-as-destruction** — LIGHT teaches "ignite to create light." BURN teaches "set on fire to destroy." If Level 2 has "burn the rope holding the drawbridge" puzzles, the player hasn't been taught that fire can destroy objects, only illuminate them.

---

## 3. Object Type Coverage

### Object Categories in the Engine vs. Level 1 Representatives

| Object Category | Level 1 Examples | Coverage |
|---|---|---|
| **Light sources** | Candle, match, oil lantern, candle stubs | ✅ Excellent (4 types) |
| **Containers (openable)** | Matchbox, nightstand drawer, wardrobe, sack, large crate, small crate, grain sack | ✅ Excellent |
| **Containers (sealed/tool-gated)** | Large crate (requires prying_tool) | ✅ Covered |
| **Furniture (immovable)** | Nightstand, wardrobe, bed, stone altar, wine rack | ✅ Covered |
| **Furniture (movable)** | Bed, rug | ✅ Covered |
| **Keys** | Brass key, iron key, silver key | ✅ Covered (3 keys) |
| **Tools (fire)** | Match, matchbox (striker), candle (fire_source) | ✅ Covered |
| **Tools (leverage)** | Crowbar | ✅ Covered |
| **Tools (cutting)** | Knife, pin, silver dagger | ✅ Covered |
| **Tools (sewing)** | Needle, thread | ✅ Covered |
| **Tools (writing)** | Pen, blood | ✅ Covered |
| **Wearables** | Cloak, sack (comedy), chamber pot (comedy) | ✅ Covered |
| **Readables** | Sewing manual, tattered scroll, tome, wall inscriptions | ✅ Covered |
| **Hazards** | Poison bottle | ✅ Covered |
| **Composite objects** | Poison bottle (with cork part), nightstand (with drawer part) | ✅ Covered |
| **Liquids** | Poison, oil, wine | ✅ Covered |
| **Breakables** | Mirror, window | ✅ Covered |
| **Tearables** | Bedsheet | ✅ Covered |
| **Climbables** | Ivy (Puzzle 013) | ✅ Covered (optional) |
| **Treasure/valuables** | Burial jewelry, burial coins | ✅ Covered (optional) |
| **Rope/tether** | Rope coil | ✅ Covered |
| **Food/potable drink** | **NONE** | ⚠️ Gap |
| **Edible objects** | **NONE** | ⚠️ Gap |
| **Burnable/destructible by fire** | **NONE explicitly** (paper exists but isn't burned) | ⚠️ Gap |

---

## 4. Gap Analysis (Prioritized)

### Priority 1: EXTINGUISH verb (Medium Impact)

**The Problem:** The candle has a full FSM with `lit → extinguished → lit` (relight) transitions. The engine supports `extinguish`, `snuff`, `blow out`, and `put out` as verbs. But no Level 1 puzzle REQUIRES the player to extinguish anything. The player learns to LIGHT but never learns to UN-LIGHT.

**Why It Matters:**
- Level 2+ may have stealth/darkness mechanics ("blow out the candle before the guard sees you")
- Wind/draft mechanics in deeper dungeons may extinguish flames; the player needs to know RELIGHT exists
- The extinguish→relight cycle is a core candle FSM feature that goes completely untested

**Level 2 Impact:** HIGH if stealth or wind mechanics exist.

**Recommendation:** Low-effort tweak. Add a moment in Puzzle 012 (Altar Puzzle) where the player must extinguish their candle before placing it in the offering bowl — the ritual requires an UNLIT candle that is then RELIT by the incense. Or: add a draft in the Deep Cellar stairway (Puzzle 011) that blows out the candle, forcing the player to RELIGHT it. Either option is narratively natural.

### Priority 2: DRINK verb (Medium Impact)

**The Problem:** The poison bottle teaches TASTE (lethal), not DRINK. Wine bottles exist in the Storage Cellar but are flavor objects. The player never successfully drinks anything. DRINK and TASTE are different verbs in the engine — TASTE is sensory investigation, DRINK is consumption.

**Why It Matters:**
- Level 2+ may have potions, water sources, or healing drinks
- Players may conflate TASTE (safe investigation in most cases) with DRINK (consumption)
- The poison bottle teaches TASTE = death, which may make players afraid to DRINK anything later

**Level 2 Impact:** MEDIUM if potions or water exist.

**Recommendation:** Add a safe DRINK interaction to the rain barrel in the Courtyard (Puzzle 013) or the well-bucket. "You cup your hands and drink. The water is cold and clean. You feel refreshed." This teaches DRINK as distinct from TASTE, and establishes that not all liquids are poison. Alternatively, make one of the wine bottles in the Storage Cellar (Puzzle 010) drinkable — "Sour, but harmless. You've had worse."

### Priority 3: EAT verb (Low Impact)

**The Problem:** No food exists in Level 1. The EAT verb handler exists in the engine but is never exercised.

**Why It Matters:**
- If Level 2 introduces hunger mechanics or edible objects, the player has no prior experience
- EAT is extremely intuitive — most players will try it without tutorial

**Level 2 Impact:** LOW. Eating is self-explanatory.

**Recommendation:** No action needed for V1. If food becomes important in Level 2, consider adding a stale bread crust or dried fruit in the Storage Cellar as flavor/health content. But this is genuinely low priority — nobody needs to be taught what "eat" means.

### Priority 4: BURN-as-destruction (Low Impact)

**The Problem:** LIGHT teaches fire as an enabling tool (create light). BURN exists as a verb that can set flammable objects on fire for destruction. No Level 1 puzzle uses fire destructively.

**Why It Matters:**
- Level 2+ may have "burn the [obstacle]" puzzles
- Players who only learned "light candle" may not think to "burn rope" or "burn barricade"

**Level 2 Impact:** LOW-MEDIUM, depending on Level 2 puzzle design.

**Recommendation:** If Level 2 has fire-destruction puzzles, consider adding a flavor interaction in the Bedroom where the player can BURN paper with the candle flame. "The paper catches fire and curls to ash." This teaches fire-as-destructive-force without affecting any puzzle. Alternatively, this can be taught organically when it first appears in Level 2 — the first burn puzzle should have obvious clues.

### Priority 5: SET/ADJUST verb (No Action Needed)

**The Problem:** The SET verb only applies to the wall-clock object, which exists in the Hallway (Level 2 transition space). No Level 1 object uses SET.

**Why It Matters:** Minimally. SET is a specialized verb for a specific object type.

**Recommendation:** No action needed. The wall-clock puzzle is self-contained and the clock's description should hint at adjustability. SET is naturally introduced when the object appears.

---

## 5. Recommendations Summary

### Must-Do (Before Level 2 Design Finalizes)

| # | Action | Effort | Puzzle Affected | What It Fixes |
|---|---|---|---|---|
| 1 | **Add extinguish/relight moment** | Small tweak | 011 (stairway draft) or 012 (altar ritual variant) | Teaches EXTINGUISH + RELIGHT verbs |
| 2 | **Add safe DRINK interaction** | Small addition | 010 (wine bottle) or 013 (rain barrel/well) | Teaches DRINK as distinct from TASTE |

### Should-Do (Quality Improvement)

| # | Action | Effort | Puzzle Affected | What It Fixes |
|---|---|---|---|---|
| 3 | **Add burn-paper flavor** | Tiny addition | 005 (bedroom, paper + candle) | Teaches fire-as-destruction concept |

### Won't-Do (Acceptable Gaps)

| # | Gap | Reason |
|---|---|---|
| 4 | EAT verb not taught | Universally intuitive. No tutorial needed. |
| 5 | SET verb not taught | Object-specific (clock). Naturally introduced in Level 2. |

---

## 6. What Level 1 Does Brilliantly

This analysis is mostly about gaps, but the coverage deserves recognition:

1. **Scaffolding progression (Witness-style):** Drawer→matchbox→match (small) THEN crate→sack→key (large). Same pattern, bigger scale. Textbook progressive complexity.

2. **Multi-sensory as core mechanic:** FEEL in darkness (001), SMELL for hazard detection (002), SMELL for object identification (010), LISTEN for atmosphere (011, 014). All five senses are used meaningfully.

3. **Death as teacher, not punishment:** Poison (002) and jumping (008) teach lethal consequences early. The game establishes stakes without being cruel — both deaths are player-initiated, not surprise gotchas.

4. **Optional depth without required breadth:** Sewing, blood-writing, and the crypt chain are deep optional content. Players who rush get the critical path; explorers get rich systems training.

5. **Every verb taught through necessity:** Almost no verb is taught by exposition — the player discovers each one because a puzzle demands it. FEEL because it's dark. STRIKE because the match needs a surface. PUSH because the bed blocks the rug. This is show-don't-tell game design at its best.

6. **GOAP boundary respected:** Simple chains are GOAP-resolvable; knowledge gates are human-only. The tutorial teaches both kinds of problem-solving.

---

## Appendix: Verb-to-Puzzle Quick Reference

For puzzle designers working on Level 2, here's where each verb was first introduced:

| Verb First Taught | Puzzle | Context |
|---|---|---|
| feel | 001 | Darkness navigation (first input) |
| open | 001 | Nightstand drawer |
| take | 001 | Matchbox from drawer |
| strike | 001 | Match on matchbox |
| light | 001 | Candle with lit match |
| look | 001 | Room view after light |
| smell | 002 | Poison bottle investigation |
| taste | 002 | Poison bottle (death) |
| read | 005 | Sewing manual |
| wear | 005 | Cloak / sack comedy |
| remove | 005 | Take off worn item |
| pull | 005 | Cork from bottle / drawer from nightstand |
| uncork | 005 | Poison bottle |
| close | 005 | Wardrobe doors |
| sew | 005 | Cloth with needle (optional) |
| write | 003 | Paper with pen/blood |
| cut | 003 | Cut self for blood |
| prick | 003 | Prick self with pin |
| drop | 004 | Free hands for compound action |
| put | 004/012 | Items in sack / candle in bowl |
| push | 007 | Push bed off rug |
| move | 007 | Move rug to reveal trap door |
| unlock | 006 | Iron door with brass key |
| break | 005/008 | Mirror / window |
| tear | 008 | Bedsheet for rope |
| listen | 005 | Ambient sound (bedroom) |
| search | 009 | Grain sack |
| examine | 009/014 | Crate details / effigies |
| pry | 009 | Crate with crowbar |
| lift | 014 | Sarcophagus lid |
| pour | 010 | Oil into lantern |
| sleep | 005 | Sleep until dawn |
| climb | 008/011/013 | Rope / stairs / ivy |
| inventory | 004 | Check what you're carrying |
| time | 005 | Check game time |
| help | Always | System command |
| **extinguish** | **NEVER** | **⚠️ Not taught** |
| **eat** | **NEVER** | **⚠️ Not taught** |
| **drink** | **NEVER** | **⚠️ Not taught** |
| **burn** | **NEVER** | **⚠️ Not taught** |
| **set** | **NEVER** | **Level 2 introduction (clock)** |

---

*"A tutorial level that teaches 31 of 35 verbs through pure puzzle necessity — no exposition, no hand-holding, no 'Press X to open' prompts — is a remarkable achievement. The gaps are real but small. Fix extinguish, fix drink, and Level 1 is as close to a perfect tutorial as I've seen in text adventure design." — Comic Book Guy*
