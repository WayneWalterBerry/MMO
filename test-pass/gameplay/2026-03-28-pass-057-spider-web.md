# Pass-057: Spider Web Mechanics Playtest
**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Scenario:** Spider web creation and obstacle mechanics

## Executive Summary

**Total Tests:** 24
**Pass:** 8 | **Fail:** 12 | **Warn:** 4
**Bugs Filed:** 4

The spider web mechanic is **fundamentally broken** because the web exists only as narrative flavor text (spider's `room_presence`), not as a tangible game object. The `spider-web.lua` object definition has full sensory properties, obstacle mechanics, and NPC-blocking behavior — but it is never instantiated. Additionally, spider loot drops are broken by a duplicate silk-bundle disambiguation deadlock.

| Issue # | Severity | Summary |
|---------|----------|---------|
| #296 | HIGH | Spider web is a ghost object — visible in description, not interactable |
| #300 | HIGH | Duplicate silk-bundle drops cause disambiguation deadlock |
| #302 | MEDIUM | Combat text uses "Someone" instead of "You" for player actions |
| #304 | LOW | Combat text grammar errors — plural weapons with singular verbs |

---

## Individual Tests

### T-001: `goto cellar`
**Input:** `goto cellar`
**Response:** Room description rendered. Spider and web visible: "A glistening web stretches across the corner. A spider waits at its center. A rat crouches in the shadows near the wall."
**Verdict:** ✅ PASS — Teleport works, cellar renders correctly, spider and rat present.

### T-002: `look`
**Input:** `look` (in cellar)
**Response:** Full room description with spider, rat, web narrative, exits, and time.
**Verdict:** ✅ PASS — Room description is rich and atmospheric.

### T-003: `look web`
**Input:** `look web`
**Response:** "You don't notice anything called that nearby. Try 'search around' to discover what's here."
**Verdict:** ❌ FAIL — Web is visible in room description but not findable by keyword.
**Bug:** #296

### T-004: `examine spider web`
**Input:** `examine spider web`
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — Same issue. All keywords (web, spider web, cobweb, silk) fail.
**Bug:** #296

### T-005: `feel web`
**Input:** `feel web`
**Response:** "You can't feel anything like that nearby. Try 'feel' to explore what's around you."
**Verdict:** ❌ FAIL — Web has rich `on_feel` text in spider-web.lua but is unreachable.
**Bug:** #296

### T-006: `feel around`
**Input:** `feel around` (in cellar)
**Response:** Lists: barrel, torch bracket, stairway, door, rat, spider, brazier. **No web.**
**Verdict:** ❌ FAIL — Web is not in the object registry at all.
**Bug:** #296

### T-007: `search around`
**Input:** `search around` (in cellar)
**Response:** Searches barrel, bracket, stairway, door, rat, spider, brazier. **No web found.**
**Verdict:** ❌ FAIL — Search system confirms web is not an object.
**Bug:** #296

### T-008: `smell web` / `listen web` / `taste web` / `touch web`
**Input:** All four sensory verbs with "web"
**Response:** All fail with "can't find/hear/feel anything like that"
**Verdict:** ❌ FAIL — All sensory verbs fail on the ghost web.
**Bug:** #296

### T-009: `look spider`
**Input:** `look spider`
**Response:** "A palm-sized brown spider with thick, bristled legs and a bulbous abdomen marked with pale chevrons. It sits motionless at the center of a glistening web."
**Verdict:** ✅ PASS — Spider has excellent visual description. Note: web mentioned in spider desc reinforces the ghost-web illusion.

### T-010: `feel spider`
**Input:** `feel spider`
**Response:** "You brush sticky silk. Something large moves nearby. Hard, bristled legs scramble across your hand."
**Verdict:** ✅ PASS — Great tactile description. Works in darkness.

### T-011: `smell spider` / `listen spider`
**Input:** `smell spider`, `listen spider`
**Response:** "A faint, musty odor — old silk and dry insect husks." / "Faint scratching, like tiny claws on stone."
**Verdict:** ✅ PASS — All spider sensory channels work perfectly.

### T-012: `taste spider`
**Input:** `taste spider`
**Response:** "Bitter chitin and a sharp, chemical sting on your tongue."
**Verdict:** ✅ PASS — Flavorful. Pun intended.

### T-013: `wait` (3x) — spider web creation
**Input:** `wait`, `wait`, `wait`
**Response:** "Time passes." (x3). No web creation narration.
**Verdict:** ⚠️ WARN — Spider's `creates_object` behavior has 30-minute cooldown. Cannot practically test dynamic web spawning in headless mode. The creates_object action scoring may also never win priority during simple wait ticks.

### T-014: `take web`
**Input:** `take web`
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — Cannot take a non-existent object.
**Bug:** #296

### T-015: `burn web`
**Input:** `burn web`
**Response:** "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — Cannot burn a non-existent object.
**Bug:** #296

### T-016: `destroy web` / `break web` / `tear web` / `cut web`
**Input:** All four destruction verbs
**Response:** "destroy web" → "I'm not sure what you mean." Others → "You don't notice anything called that nearby."
**Verdict:** ❌ FAIL — No destruction path for web. Even if web existed, "destroy" is not a recognized verb.
**Bug:** #296

### T-017: `hit spider` — combat
**Input:** `hit spider`
**Response:** Full combat sequence. Spider fights back with venom bites. Spider dies in 2-6 rounds. Player receives multiple venom effects.
**Verdict:** ✅ PASS — Combat initiates and resolves. Spider drops silk and sometimes fang.

### T-018: Combat text — player reference
**Input:** (observed during T-017 combat)
**Response:** "Someone punches a large brown spider's cephalothorax", "Someone kicks a large brown spider's abdomen"
**Verdict:** ❌ FAIL — Player referred to as "Someone" instead of "You".
**Bug:** #302

### T-019: Combat text — grammar
**Input:** (observed during T-017 combat)
**Response:** "the fangs glances off", "The fangs bites at someone's shoulder", "into toward someone's thigh"
**Verdict:** ⚠️ WARN — Multiple grammar issues in combat text generation.
**Bug:** #304

### T-020: `take silk` / `take silk bundle` — after spider kill
**Input:** `take silk`, `take silk bundle`, `take bundle`
**Response:** "Which do you mean: a bundle of spider silk or a bundle of spider silk?"
**Verdict:** ❌ FAIL — Two identical silk bundles dropped; disambiguation deadlock prevents taking either.
**Bug:** #300

### T-021: `take dead spider`
**Input:** `take dead spider`
**Response:** "You take a dead spider."
**Verdict:** ✅ PASS — Dead spider becomes portable. Shows in inventory correctly.

### T-022: Post-death room description
**Input:** `look` (after killing spider)
**Response:** "A dead spider lies curled beneath a sagging web." — Web narrative shifts from alive-idle to dead state.
**Verdict:** ✅ PASS — Spider death state changes room_presence text appropriately.

### T-023: Venom lethality
**Input:** (observed across all combat runs)
**Response:** Player consistently dies from spider venom within 3-5 turns after combat. "The numbness creeps past your knee..." → "Your injuries have overwhelmed you. YOU HAVE DIED."
**Verdict:** ⚠️ WARN — Spider venom is extremely lethal with no antidote available at this game stage. Player wins combat but dies from venom before collecting loot. Design-intentional but punishing.

### T-024: Rat/NPC movement through web
**Input:** (cannot be directly tested — web object doesn't exist)
**Response:** N/A — The `obstacle.blocks_npc_movement` property on spider-web.lua is unreachable because the web is never instantiated.
**Verdict:** ⚠️ WARN — Untestable. The rat exists in the cellar and flees after spider death, but there is no web object to block its movement.

---

## Q3 Verification: Feel Web in Darkness, See Web in Light

**Cannot be verified.** Since the spider web is not an actual object (#296), neither `feel web` (darkness) nor `look web` (light) works. The narrative web text from the spider's `room_presence` appears regardless of light conditions, which is technically incorrect — `room_presence` text should follow the same light rules as `look` but currently renders unconditionally.

---

## Architecture Analysis

The spider-web mechanic has a **design-implementation gap**:

| Layer | Status | Notes |
|-------|--------|-------|
| Object definition (`spider-web.lua`) | ✅ Complete | Full sensory, obstacle, material properties |
| Spider behavior (`creates_object`) | ✅ Coded | 30-min cooldown, max 2 webs, condition checks |
| Engine action (`create_object`) | ✅ Coded | Registry registration, room.contents insertion |
| Room wiring (cellar instances) | ❌ Missing | No spider-web in cellar.lua instances array |
| Initial web spawn | ❌ Missing | Spider starts with web narrative but no web object |
| Dynamic spawn trigger | ❓ Untested | Requires sustained game ticks; cooldown may prevent ever firing |

The spider's `room_presence` text creates the illusion of a web, but the real spider-web objects are only created by the `creates_object` action — which has a 30-minute cooldown and requires the creature tick system to score it as the winning action. In practice, the web never materializes as an interactable object.

---

## Recommendations

1. **Pre-spawn a spider-web instance** in cellar.lua alongside the spider creature. The spider should start WITH a web, not create one after 30 minutes.
2. **Deduplicate silk-bundle drops** — either merge loot+byproduct into 1 bundle, or give bundles ordinal names.
3. **Fix combat pronoun** — replace "Someone" with "You" for player attacks.
4. **Grammar pass on combat text** — fix subject-verb agreement for plural weapon names.

---

*Nelson — Tester*
*Every bug you find now is a bug the player never sees.*
