# Nelson — Pass 004 Bug Report

**Date:** 2026-03-20  
**Pass:** test-pass/2026-03-20-pass-004.md

## New Bugs

### BUG-023: UI status bar Unicode encoding issue
- **Severity:** Cosmetic
- **Input:** `lua src/main.lua` (UI mode)
- **Expected:** Candle icon should render as proper Unicode symbol
- **Actual:** Candle icon renders as `Γùï` (Windows terminal encoding issue)
- **Note:** May need to set UTF-8 codepage or use ASCII fallback for Windows.

### BUG-024: "Put sack on head" equips to shoulder instead of head (REGRESSION)
- **Severity:** Minor
- **Input:** `put sack on head`
- **Expected:** Sack goes on head, blocks vision (as confirmed working in pass-003)
- **Actual:** "You sling a burlap sack over your shoulder. It makes a serviceable, if ugly, backpack." — no vision blocking, "on head" instruction ignored
- **Note:** This is a regression. In pass-003, sack-on-head worked correctly with vision blocking.

### BUG-025: Wearing cloak blocks sack on different body slot
- **Severity:** Minor
- **Input:** `wear cloak` then `put sack on head`
- **Expected:** Cloak (back slot) and sack (head slot) should coexist on different body parts
- **Actual:** "You're already wearing a moth-eaten wool cloak. Remove it first." — system allows only one worn item total
- **Note:** May be intentional single-slot design. If so, close as wontfix. If multi-slot was intended, needs fix.

## Previous Bugs Verified Fixed (10/10)

- BUG-009: Parser debug leaks → ✅ FIXED
- BUG-010: Nightstand internal IDs → ✅ FIXED  
- BUG-012: Spent match priority → ✅ FIXED
- BUG-015: Wardrobe internal IDs → ✅ FIXED
- BUG-016: "put X on head" routing → ✅ FIXED (routes to wear)
- BUG-017: Drawer replace destroys surface → ✅✅ FIXED (critical fix confirmed)
- BUG-019: FSM state labels leak → ✅ FIXED
- BUG-021: Parser startup debug line → ✅ FIXED

## Not Tested This Pass
- Blood/writing system
- `sleep until dawn` / `sleep until morning` variants
- Candle burn-out during sleep
- Poison death re-verification
- `sleep until morning` with curtains open (daylight wake)
