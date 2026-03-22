# Bug Triage Decision — Issue Review Complete

**Date:** 2026-03-22 (Day 1 Final)  
**Requestor:** Wayne "Effe" Berry  
**Authority:** Marge (Test Manager)

## Summary

Reviewed all 5 remaining open GitHub Issues against canonical bug tracker (`bugs/bug-tracker.md`). **Deploy gate is clear.**

## Findings

| Issue | Bug ID | Severity | Status | Regression Test | Recommendation |
|-------|--------|----------|--------|-----------------|-----------------|
| #1 | BUG-069 | MEDIUM | ✅ FIXED | ✅ Yes | 🟢 **Close immediately** |
| #3 | BUG-072 | LOW | 🔴 Open | ❌ No | 🟢 **Defer post-deploy** |
| #4 | BUG-104b | MEDIUM | ✅ FIXED | ✅ Yes | 🟢 **Close immediately** |
| #7 | BUG-105b | LOW | ✅ FIXED | ✅ Yes | 🟢 **Close immediately** |
| #8 | BUG-106b | LOW | ✅ FIXED | ✅ Yes | 🟢 **Close immediately** |

## Details

### Issues to Close (#1, #4, #7, #8)
All fixed by Smithers with regression test coverage:
- **#1** — Dawn sleep error message corrected
- **#4** — Politeness + idiom combo fixed (pipeline order: strip_filler → expand_idioms)
- **#7** — Bare `examine` added to no_noun_verbs
- **#8** — Unlit candle extinguish message fixed (transitions checked)

### Issue to Defer (#3)
**BUG-072: Screen flicker during progressive object discovery**
- Severity: LOW (polish/UI artifact)
- Status: Still open, root cause unknown
- Blocker: None — does not affect game logic or player progression
- Action: Assign to Smithers for investigation *after* deploy if time permits

## Decision

✅ **DEPLOY GATE APPROVED.** Wayne can proceed with deploy and feature work.  
🟢 **Close issues #1, #4, #7, #8 today** (verified with regression tests).  
🟡 **#3 can be investigated post-deploy** if backlog permits.

---

*Signed by Marge — Nothing leaves this house broken.*
