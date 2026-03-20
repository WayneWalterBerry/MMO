# Decision Memo: Player Skills System + Gap Fixes

**Author:** Bart (Architect)  
**Date:** 2026-03-26  
**Status:** Implemented  
**Affects:** Verb system, object model, player state, crafting pipeline

---

## Decisions Made

### D-SKILL-01: Skills as Simple Table Lookup
Player skills stored as `player.skills = {}` with binary entries (`player.skills.sewing = true`). No proficiency levels, no XP. Gate check is one line: `if not ctx.player.skills[skill_name] then`. First skill: sewing.

### D-SKILL-02: Skill Discovery via Readable Objects
Objects with `grants_skill` field teach skills when READ. The READ verb handler checks this field before falling through to examine. Pattern: create a readable object, set `grants_skill = "skill_name"`, `skill_message`, `already_learned_message`.

### D-SKILL-03: SEW Verb as Crafting Template
SEW verb implements the crafting pattern: skill gate → parse material/tool → find tool in inventory → find sewing_material (thread) → consume materials per recipe → spawn product. Recipe lives on the material object (`cloth.crafting.sew`). Future crafting verbs (BREW, FORGE) follow this pattern.

### D-SKILL-04: Sack Wearable with Alternate Slots
Objects can declare `wear_alternate = { slot_name = { config } }`. WEAR handler parses "wear X on Y" for slot selection. Default wear slot chosen when no "on Y" specified. Original wear config saved as `obj._base_wear` and restored on REMOVE.

### D-SKILL-05: Wardrobe Refactored to Inline FSM
Wardrobe converted from mutation-based (wardrobe.lua ↔ wardrobe-open.lua swap) to inline FSM (single file, states: closed/open, transitions with messages). Surfaces preserve contents across state transitions via FSM engine's `apply_state`. wardrobe-open.lua retained but unused.

### D-SKILL-06: Blood State Persistence (Tick-Down)
`player.state.bleed_ticks` set on injury (8 for prick, 10 for cut). Decremented each tick in `on_tick`. At tick 2: "Your wound is still bleeding, but it's slowing." At tick 0: `bloody = false`, "The bleeding has stopped." Blood writing only works while `bloody == true`.

### D-SKILL-07: Curtains Daylight Already Wired
Curtains FSM was already correctly implemented with `allows_daylight` (open state) and `filters_daylight` (closed state). Light system already checks these flags during daytime hours. No code changes needed — confirmed working.

### D-SKILL-08: Surface-Based Container Access in TAKE
"Take X from Y" handler expanded to search `surfaces` (not just `container + contents`). Wardrobe and similar furniture with surface zones now work with "take X from wardrobe" syntax.

---

## Team Impact

- **Content creators:** New objects can grant skills by setting `grants_skill` field. Crafting recipes go in material objects' `crafting` table.
- **QA:** Test skill gating with "sew cloth" before reading manual (should block). Test wear slot alternates ("wear sack on head" vs "wear sack").
- **Game Design:** Sewing manual placed in sack (inside wardrobe). Discovery flow: open wardrobe → take sack → read manual → learn sewing.
