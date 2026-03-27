# Nelson — WAVE-0 Parallel Decisions

**Date:** 2026-07-26
**Agent:** Nelson (QA Engineer)
**Context:** WAVE-0 Parallel execution — lint fixes #249, #250 + portal TDD #203, #204

## D-ORPHAN-ALLOWLIST: Orphan Object Allowlist in Lint Config

**Category:** Testing/Tooling
**Status:** 🟢 Active

Added `orphan_allowlist` support to the meta-lint config system. The `.meta-check.json` file now supports a `"orphan_allowlist"` dictionary mapping object IDs to reason strings. Objects in the allowlist are skipped by the GUID-02 rule.

**Impact:** Bart (config.py + lint.py modified), all agents (new `.meta-check.json` config file)

**Files changed:**
- `scripts/meta-lint/config.py` — added `orphan_allowlist` field to `CheckConfig`, parsing in `parse_config()`
- `scripts/meta-lint/lint.py` — GUID-02 check now calls `_active_config.is_orphan_allowed()`
- `.meta-check.json` — new config file with 28 categorized orphan suppressions

## D-EXIT01-LINT-GAP: EXIT-01 Does Not Validate Portal Targets Against Room IDs

**Category:** Testing/Tooling
**Status:** ⚠️ Needs Bart's Attention

The EXIT-01 lint rule has a gap: it checks that `portal.target` is a non-nil string, but does NOT verify that the target room actually exists in `room_ids`. The Phase 2 inline EXIT-01 check was bypassed by the portal migration (rooms use `portal` references instead of inline `target` fields).

**Recommended fix:** Add a Phase 4 check that validates `portal.target` against `room_ids` for portal objects (excluding boundary portals where `bidirectional_id = nil`).

## D-KITCHEN-DOOR-TRAVERSAL: courtyard-kitchen-door Boundary Portal Gating

**Category:** Architecture
**Status:** ✅ Implemented

The `courtyard-kitchen-door.lua` portal had `traversable = true` in its `open` and `broken` states, targeting non-existent `manor-kitchen` room. This would cause a runtime crash if a player opened the door and tried to walk through. Fixed by setting `traversable = false` with `blocked_message` in both states (collapsed masonry narrative). When `manor-kitchen` is created for Level 2, these states should be restored to `traversable = true`.

**Impact:** Moe (room creation), Flanders (object updates when Level 2 is ready)
