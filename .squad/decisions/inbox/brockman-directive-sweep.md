# Brockman: Directive Sweep to Permanent Docs

**Date:** 2026-03-21T23:15Z  
**Agent:** Brockman (Documentation)  
**Task:** Consolidate all user directives from decisions.md into appropriate docs files for durable context.

---

## Summary

**Directives Processed:** 2  
**Directives Already Captured:** 2 (UD-2026-03-20T21-54Z, UD-2026-03-20T21-57Z)  
**New Docs Created:** 0  
**Docs Updated:** 2  
**Status:** ✅ Complete

---

## Directives Swept

### 1. UD-2026-03-20T21-54Z: No special-case objects; clock as 24-state FSM

**Action:** Already well-captured in existing docs. Verified and cross-referenced.

**Location:** `docs/objects/wall-clock.md` (Design Philosophy section, lines 87-101)  
**Content:** Explains 24-state FSM pattern, why no special-case engine code, extensibility benefits.  
**Status:** ✅ Complete

---

### 2. UD-2026-03-20T21-57Z: Wall clock supports misset time for puzzles

**Action:** Added NEW section to wall-clock.md + NEW requirement to design-requirements.md.

**Updates Made:**

1. **`docs/objects/wall-clock.md`** — NEW SECTION: "Instance-Level Customization: Misset Time for Puzzles"
   - Explains `time_offset` mutable metadata pattern
   - Documents `on_set_to_target` trigger mechanism for puzzle events
   - Describes SET verb interaction (future capability)
   - Design pattern explanation (generic base + customizable instances)

2. **`docs/design/00-design-requirements.md`** — NEW REQUIREMENT: REQ-054B
   - Title: "Clock Misset for Puzzles (Instance-Level Time Offset)"
   - Source: UD-2026-03-20T21-57Z
   - Status: ⏳ In Design
   - Details: full specification with Lua code examples
   - Cross-references to wall-clock.md object docs

**Status:** ✅ Complete

---

## Verification

**All 2 directives now live in permanent docs:**
- ✅ Gameplay design → `docs/design/` (REQ-054B) + `docs/objects/` (wall-clock.md)
- ✅ Object-specific details → `docs/objects/wall-clock.md`
- ✅ Cross-references maintained (design-requirements.md links to wall-clock.md)
- ✅ No duplicate content; just fills gaps
- ✅ decisions.md updated with sweep marker

---

## Process Notes

**Search Approach:**
- Identified 2 user directives in decisions.md (UD-2026-03-20T21-54Z, UD-2026-03-20T21-57Z)
- Cross-checked existing docs (wall-clock.md, design-requirements.md, etc.)
- Directive 1 already captured; verified + cross-linked
- Directive 2 partially captured (wall-clock.md had FSM states); added puzzle mechanics

**Documentation Pattern:**
- Gameplay design → `docs/design/00-design-requirements.md` (system-level requirements)
- Object-specific behavior → `docs/objects/{object}.md` (detailed design)
- Cross-references maintain consistency without duplication

---

## Next Steps for Team

**Wall Clock Implementation:**
- Implement `time_offset` mutable metadata system
- Implement `on_set_to_target` trigger mechanism
- Add SET verb handler (future phase)
- Test misset clock in puzzle context

**Documentation Maintenance:**
- decisions.md remains as working inbox for new directives
- docs/ folder is now the lasting source of truth
- Archive old directives from decisions.md when it exceeds 50 entries (currently ~40)

---

## Outcomes

✅ **Directives Durable:** All gameplay and architectural directives now live in permanent docs structure  
✅ **Cross-Team Visibility:** New team members can find design intent by reading docs/, not mining decisions.md  
✅ **Implementation Clarity:** Builders have single authoritative source for what to build (REQ-054B + wall-clock.md)  
✅ **Process Established:** Future directives will follow same sweep pattern: inbox → permanent docs

**docs/ folder is now the lasting source of truth.**
