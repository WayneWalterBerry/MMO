# Orchestration Log — Bart Spawn (2026-03-22 Playtest Fixes)

## Spawn Details
- **Agent:** Bart (background, claude-sonnet-4.5)
- **Task:** Fix 4 play test bugs from Wayne's testing session
- **Status:** ✅ COMPLETED
- **Commit:** a6dc7b0

## Outcome

Identified and fixed all 4 reported playtest bugs:

### Bug #1: "drawer" keyword not recognized
- **Root Cause:** Nightstand had surface zone `surfaces.inside` but no keyword alias
- **Fix:** Added "drawer" keyword alias to `src/meta/objects/nightstand.lua`
- **Pattern:** Surface zones get keyword aliases on parent object, not engine-level resolution

### Bug #2: "what's inside" not understood
- **Root Cause:** Contextual query not recognized by parser
- **Fix:** NLP preprocessing in `src/engine/loop/init.lua` maps "what's inside" to `look` command
- **Note:** Full context tracking (last-examined object) deferred; this is minimal fix for now

### Bug #3: Matchbox contents visible when closed
- **Root Cause:** No `accessible` field check for containers in verb layer
- **Fix:** 
  - Added `accessible = false` to closed matchbox definition
  - Created `src/meta/objects/matchbox-open.lua` (open state variant)
  - Added accessible field check in `src/engine/verbs/init.lua` find_visible()
  - Pattern: File-per-state for container open/closed transitions

### Bug #4: Typos in verb entry cause silent failure
- **Root Cause:** Tier 2 parser only does exact/similarity matching; no typo correction
- **Fix:** 
  - Implemented Levenshtein edit-distance typo correction in `src/engine/parser/embedding_matcher.lua`
  - Placed in Tier 2 preprocessing (not Tier 1) to preserve predictability
  - Edit distance ≤ 2 with length guard to prevent false corrections
  - Known verbs extracted from phrase index at runtime

## Files Changed
- `src/meta/objects/nightstand.lua` — added "drawer" keyword
- `src/meta/objects/matchbox.lua` — added accessible=false, open mutation
- `src/meta/objects/matchbox-open.lua` — **NEW** (open state container)
- `src/engine/verbs/init.lua` — accessible check in find_visible
- `src/engine/loop/init.lua` — NLP preprocessing for "what's inside"
- `src/engine/parser/embedding_matcher.lua` — Levenshtein typo correction

## Decision Logged
- **File:** `.squad/decisions/inbox/bart-playtest-fixes.md`
- **Decision:** Play Test Bug Fix Patterns (4 architectural patterns established)

## Cross-Agent Context
- **To Comic Book Guy:** New state file `matchbox-open.lua` validates FSM approach; confirms file-per-state pattern works
- **From Comic Book Guy:** FSM design complete; ready for Bart to implement FSM engine

## Notes
- All fixes tested during playtesting session
- Matchbox pattern (file-per-state) aligns with FSM design; good sign
- Parser typo correction now part of standard pipeline for improved UX
