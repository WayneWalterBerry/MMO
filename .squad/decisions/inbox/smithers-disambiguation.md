# Decision: Room-Level Adjective-Aware Disambiguation (#182)

**Author:** Smithers (UI Engineer)
**Date:** 2025-07-24
**Scope:** Parser / find_visible search pipeline

## Decision

When `find_visible` searches room contents and multiple objects match the same keyword, the engine now **scores candidates by adjective overlap** rather than returning the first match.

### Scoring Rules
- Each input token that matches an exact keyword on the object: **+2**
- Each input token found as a word in the object's name: **+1**
- Highest score wins. Tied scores trigger a "Which do you mean?" disambiguation prompt on `ctx.disambiguation_prompt`.

### Disambiguation Behavior
- When disambiguation triggers, `find_visible` returns `nil` and sets `ctx.disambiguation_prompt`.
- The search pipeline **stops** — it does not fall through to surfaces, parts, or hands.
- Verb handlers should check `ctx.disambiguation_prompt` and display it to the player.

### dump/empty Verbs
- `dump` and `empty` are now **independent verb handlers** (not aliases of `pour`).
- Container with `obj.contents` → spill items to room floor.
- Container with `surfaces.inside.contents` (if accessible) → spill to room floor.
- Non-container → falls through to `pour` behavior for liquids.
- Both verbs are registered as **interaction verbs** (search hands first).

## Affected Agents
- **Bart:** `_try_room_scored` is a new helper in `helpers.lua` — engine-level search change.
- **Nelson:** 13 tests in `test/parser/test-disambiguation.lua` now pass.
- **Moe/Flanders:** Objects with shared keywords should include distinguishing adjectives in their `keywords` array for best disambiguation.
- **CBG:** Future design should consider whether disambiguation prompts need to be displayed in the game loop.

## Files Changed
- `src/engine/verbs/helpers.lua` — `_score_adjective_match`, `_try_room_scored`, `interaction_verbs`
- `src/engine/verbs/survival.lua` — `dump_container` handler, `empty` registration
