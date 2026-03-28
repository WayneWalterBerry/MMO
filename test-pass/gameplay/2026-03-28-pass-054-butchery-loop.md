# Pass-054: Butchery System — Kill Wolf, Butcher Corpse, Cook Meat

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** `lua src/main.lua --headless`
**Method:** Headless pipe-based testing (Pattern 1 from SKILL.md)
**Scope:** Full butchery loop — kill wolf → butcher corpse → verify products → cook meat → error paths

## Executive Summary

**Total tests: 18 | ✅ PASS: 6 | ❌ FAIL: 7 | ⚠️ WARN: 3 | 🚫 BLOCKED: 2**

The butchery system is **completely untestable through normal gameplay** due to two blocking issues:

1. The **butcher-knife** (the only tool with "butchering" capability) is **not placed in any room**. It exists as an object definition (`src/meta/objects/butcher-knife.lua`) but is never instantiated in any room's `instances` table. No other tool in the game provides the "butchering" capability.

2. **Wolf combat is consistently fatal** to the player. Across 7 test runs with varying weapons (bare fists, small knife, silver dagger, iron crowbar, dual-wield), the player died in every single engagement cycle. The wolf's damage output (bite force 8, claw force 4) overwhelms the unarmored player's 100 HP in a single combat cycle.

Additionally, a **logic bug** in `butchery.lua` allows the player to attempt butchering a **living** creature — the `death_state` field on the living wolf template bypasses the alive check.

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-188 | **CRITICAL** | Butcher-knife not placed in any room — butchery system completely inaccessible |
| BUG-189 | **HIGH** | Living creature passes alive check in butchery.lua — `death_state` on living wolf bypasses guard |
| BUG-190 | **HIGH** | Wolf combat consistently fatal — player dies in every engagement cycle regardless of weapon |
| BUG-191 | **MEDIUM** | "You need a knife" error when player holds a knife — message doesn't distinguish knife types |
| BUG-192 | **MEDIUM** | Rat corpse spoilage FSM jumps to "bones" state immediately after death instead of "fresh" |
| BUG-193 | **LOW** | "dissect" and "gut" not recognized as butchery verb aliases |

## Test Runs

Seven game sessions were executed across 8 test runs:
- **Runs 1–6:** Wolf combat with various weapons (bare fists, knife, dagger, crowbar, dual-wield) — all resulted in player death
- **Run 7:** Butchery error path testing on living wolf and non-creature objects
- **Run 8:** Rat kill + butchery attempt in cellar (to verify "no products" path)

## Individual Tests

### T-001: `butcher` with no noun
**Input:** `butcher`
**Response:** `Butcher what?`
**Verdict:** ✅ PASS — correct empty noun handling

### T-002: `butcher wolf` on living wolf (wolf present)
**Input:** `butcher wolf` (after `goto hallway`, wolf present in room)
**Response:** `You need a knife to butcher this.`
**Verdict:** ❌ FAIL
**Bug:** BUG-189 — Should say "You can't butcher a living creature" or similar. The butchery code's alive check (`target.alive ~= false and not target.death_state`) fails because the living wolf's template includes a `death_state` field (the template for what happens when it dies). The condition evaluates: `true AND false = false`, so the alive guard is bypassed. The code then finds `death_state.butchery_products` (from the living wolf's template) and proceeds to the tool check. If the player HAD a butcher-knife, they could butcher a living wolf.

**Code analysis (butchery.lua lines 41–43):**
```lua
if target.alive ~= false and not target.death_state then
    print("You can't butcher that.")
    return
end
```
The fix should check `target.alive ~= false` independently, OR check `target._state == "dead"`.

### T-003: `butcher wolf` — tool check with wrong knife
**Input:** `butcher wolf` (player holding a small knife, wolf present)
**Response:** `You need a knife to butcher this.`
**Verdict:** ❌ FAIL
**Bug:** BUG-191 — Player IS holding a knife. The regular knife provides `{"cutting_edge", "injury_source"}` but not `"butchering"`. The error message "You need a knife" is misleading when the player already has one. Should say "You need a heavier blade for butchering" or "Your small knife isn't suitable for butchering a creature this large."

### T-004: `skin wolf` alias (wolf present)
**Input:** `skin wolf`
**Response:** `You need a knife to butcher this.`
**Verdict:** ✅ PASS — alias correctly routes to butcher handler (same bug as T-002/T-003 applies)

### T-005: `carve wolf` alias (wolf NOT present — had fled)
**Input:** `carve wolf` (wolf had scurried away on previous tick)
**Response:** `You don't notice anything called that nearby.`
**Verdict:** ✅ PASS — wolf legitimately not in room due to movement tick. The `carve` alias is correctly registered.

### T-006: `fillet wolf` alias (wolf NOT present)
**Input:** `fillet wolf`
**Response:** `You don't notice anything called that nearby.`
**Verdict:** ✅ PASS — alias registered correctly; wolf not present due to movement timing.

### T-007: `butcher table` (non-creature object)
**Input:** `butcher table`
**Response:** `You can't butcher that.`
**Verdict:** ✅ PASS — correct rejection of non-creature object.

### T-008: `butcher side table`
**Input:** `butcher side table`
**Response:** `You can't butcher that.`
**Verdict:** ✅ PASS — correct rejection.

### T-009: `dissect wolf`
**Input:** `dissect wolf`
**Response:** `I'm not sure what you mean.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-193 — "dissect" is a reasonable synonym for butchery that players may try. Not currently aliased.

### T-010: `gut wolf`
**Input:** `gut wolf`
**Response:** `I'm not sure what you mean.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-193 — "gut" is a common butchery synonym. Not currently aliased.

### T-011: `butcher door` (disambiguation collision)
**Input:** `butcher door`
**Response:** `Which do you mean: a heavy oak door, a heavy oak door, or a lighter oak door?`
**Verdict:** ⚠️ WARN — Two identical "a heavy oak door" options in disambiguation. Pre-existing issue (not butchery-specific).

### T-012: Kill wolf with silver dagger — player survival
**Input:** `goto crypt` → `search around` → `take dagger` → `goto hallway` → `attack wolf` ×13
**Response:** Wolf killed on 2nd engagement cycle. Player died immediately after:
```
a grey wolf is dead!

Your injuries have overwhelmed you.
YOU HAVE DIED.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-190 — Player and wolf die simultaneously. The wolf's damage output in a single combat cycle (~80–120 HP of injuries) exceeds the player's 100 HP. This makes post-combat butchery impossible.

### T-013: Kill wolf with iron crowbar — player survival
**Input:** `goto storage-cellar` → `take crowbar` → `goto hallway` → `attack wolf` ×15
**Response:** Combat ended in stalemate. Player collapsed from wounds:
```
You collapse from your wounds!
The wolf snarls and lunges, fangs bared!
A grey wolf scurries down.

Your injuries have overwhelmed you.
YOU HAVE DIED.
```
**Verdict:** ❌ FAIL
**Bug:** BUG-190 — Same result with blunt weapon.

### T-014: Kill wolf with bare fists (20 attacks) — player survival
**Input:** `goto hallway` → `attack wolf` ×20
**Response:** Single combat cycle, stalemate reached at 20 rounds. Player collapsed mid-combat:
```
You collapse from your wounds!
```
**Verdict:** ❌ FAIL
**Bug:** BUG-190 — Even bare-fist combat (lower per-hit damage) deals fatal cumulative damage in one cycle.

### T-015: Kill wolf with dual-wield (crowbar + dagger)
**Input:** Crowbar in left hand, silver dagger in right → `attack wolf`
**Response:** Combat used only the left-hand weapon (crowbar). Player died.
**Verdict:** ❌ FAIL
**Bug:** BUG-190 — Additionally, dual-wielding doesn't use both weapons — only the left hand.

### T-016: Butcher dead rat (no butchery products)
**Input:** `goto cellar` → `attack rat` → rat dies → `butcher rat`
**Response:** `There's nothing useful to carve from this corpse.`
**Verdict:** ✅ PASS — Correct message for a corpse without butchery_products.

### T-017: Butcher dead rat — spoilage state check
**Input:** `look` after killing rat
**Response:** `A small pile of rat bones sits on the floor.`
**Verdict:** ❌ FAIL
**Bug:** BUG-192 — The rat's spoilage FSM should start at "fresh" state (`room_presence: "A dead rat lies crumpled on the floor."`), but it immediately shows the terminal "bones" state (`room_presence: "A small pile of rat bones sits on the floor."`). All intermediate states (fresh → bloated → rotten) were skipped.

### T-018: Butcher-knife accessibility
**Input:** Code review of all room files (`src/meta/rooms/*.lua`) and level file (`src/meta/levels/level-01.lua`)
**Response:** The butcher-knife (GUID `{9e8ab074-0888-42ab-b871-af7e39e59598}`) is **not referenced in any room or level definition**. It exists only as an orphan object file at `src/meta/objects/butcher-knife.lua`.
**Verdict:** ❌ FAIL
**Bug:** BUG-188 — The butcher-knife is the ONLY item in the game with `provides_tool = {"butchering", ...}`. Without it being placed in a room, the entire butchery system is unreachable. No other tool provides the required "butchering" capability:
- Small knife: `provides_tool = {"cutting_edge", "injury_source"}`
- Silver dagger: `provides_tool = {"cutting_edge", "injury_source", "ritual_blade"}`
- Crowbar: `provides_tool = {"prying_tool", "blunt_weapon", "leverage"}`

## 🚫 BLOCKED Tests

The following tests could not be executed due to BUG-188 (no butcher-knife) and BUG-190 (wolf combat fatal):

| Test | Description | Blocker |
|------|-------------|---------|
| Butcher dead wolf → verify products spawn | Kill wolf, butcher with knife, check wolf-meat/wolf-bone/wolf-hide appear | BUG-188 + BUG-190 |
| Cook wolf-meat over fire | Take wolf-meat, find fire source, cook it | BUG-188 + BUG-190 |

## Analysis

### What works
- Butchery verb is registered and responds to input
- Aliases (`carve`, `skin`, `fillet`) are correctly registered
- Empty noun handling ("Butcher what?") works
- Non-creature rejection ("You can't butcher that.") works
- No-products corpse message ("There's nothing useful to carve from this corpse.") works
- Tool capability check correctly rejects tools without "butchering" capability

### What's broken
1. **System inaccessible:** The butcher-knife isn't placed in the game world. Butchery is dead on arrival.
2. **Logic bug:** Living creatures with `death_state` bypass the alive check. A player with the butcher-knife could butcher a living wolf.
3. **Wolf combat balance:** The wolf is too lethal for the unarmored early-game player. No amount of weapon choice or tactical play allows survival.
4. **Misleading error:** "You need a knife" when the player has a knife is confusing. The error should name the specific tool type required.
5. **Spoilage FSM:** Rat corpse skips all spoilage states and jumps directly to "bones" — the timed_events system may not be initializing correctly on death reshape.

### Recommended fixes (priority order)
1. **Place butcher-knife in a room** — storage-cellar or hallway kitchen area (behind the east door) would be thematically appropriate
2. **Fix alive check in butchery.lua** — check `target.alive ~= false` as a standalone condition, OR check `target._state == "dead"`, not relying on `death_state` absence
3. **Investigate wolf combat balance** — either reduce wolf damage, add early-game armor, or allow combat flee in headless mode
4. **Improve tool error messages** — differentiate between "no tool at all" and "wrong type of tool"
5. **Investigate spoilage FSM initialization** — ensure timed_events start correctly after death reshape

---

**Signed:** Nelson, Tester
**Pass complete:** 2026-03-28
