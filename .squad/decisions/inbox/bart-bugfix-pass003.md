# Bart — Bug Fix Decisions (Pass-003)

**Date:** 2026-03-20
**Author:** Bart (Architect)
**Scope:** 8 bugs from Nelson's test-pass-003

## Decisions Made

### D-BUG017: Save containment before FSM cleanup
**Context:** `reattach_part` in verbs/init.lua wiped surfaces before saving contents, destroying nightstand surface objects on drawer reattachment.
**Decision:** Surface contents must be saved BEFORE any state-key cleanup phase, not during the apply phase. The inline transition in `reattach_part` now mirrors the save-first pattern used by `fsm.apply_state`.
**Rule:** Any code that does manual FSM state transitions must save containment data first.

### D-BUG018: No fuzzy correction on short words
**Context:** Levenshtein typo correction matched "kick" → "lick" (1 edit, 25% of word).
**Decision:** Words ≤4 characters skip fuzzy correction entirely — exact match only. Longer words still use the existing distance < 3 threshold.
**Rule:** Fuzzy matching thresholds must account for word length.

### D-BUG019: No internal state in display names
**Context:** Nightstand FSM states had names like "a small nightstand (drawer open)" which leaked into player-facing messages.
**Decision:** Object `name` fields must be clean display names. Internal state is tracked by `_state` and expressed through `description`, `room_presence`, and `on_look` — never through the name.
**Rule:** State metadata never goes in the `name` field.

### D-BUG020: Containment messages are specific and capitalized
**Context:** "there is not enough room" was lowercase and generic.
**Decision:** Containment rejection messages include the container name and follow sentence capitalization: "There is not enough room on {name}."
**Rule:** All player-facing messages use sentence case and reference the relevant object.

### D-BUG021: Debug output gated at construction
**Context:** Parser startup message printed regardless of --debug flag because the diagnostic flag was set after construction.
**Decision:** Debug flags must be passed through the full init chain (main → parser.init → matcher.new). Default is off. Constructor-time output respects the flag.
**Rule:** Any module that prints diagnostics during construction must accept a debug parameter.

### D-BUG022: No false affordances
**Context:** "Play again? (y/n)" prompted but never actually restarted — just exited.
**Decision:** Replaced with honest "Game over. Thanks for playing." message. When restart is implemented later, the prompt can return.
**Rule:** Never ship UI that promises functionality that doesn't exist.

## Files Changed
- `src/engine/verbs/init.lua` — BUG-017 (save surfaces before cleanup), BUG-016 (body-part routing to wear)
- `src/meta/objects/wardrobe-open.lua` — BUG-015 (registry param for display names)
- `src/meta/objects/nightstand.lua` — BUG-019 (clean state names)
- `src/engine/parser/embedding_matcher.lua` — BUG-018 (short word exact match), BUG-021 (debug gating)
- `src/engine/parser/init.lua` — BUG-021 (pass debug flag through)
- `src/main.lua` — BUG-021 (pass debug_mode to parser.init)
- `src/engine/containment/init.lua` — BUG-020 (capitalized, specific message)
- `src/engine/loop/init.lua` — BUG-022 (honest game-over message)
