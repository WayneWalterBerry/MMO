# Open Design Questions

**Last updated:** 2026-03-21  
**Audience:** Architecture & Design Team  
**Purpose:** Track exploratory design questions that Wayne is investigating but hasn't decided on yet.

---

## Verbs as Meta-Code

**Status:** OPEN QUESTION — Wayne exploring, not directing yet (2026-03-19T130100Z)

**Question:** Should verbs be defined in `src/meta/verbs/` (as Lua data files) rather than hardcoded in `src/engine/verbs/init.lua`?

**Rationale:**
- If verbs are part of the world definition, each verb = a `.lua` file returning a table with handler, aliases, prerequisites
- Engine just loads and dispatches verbs; doesn't know their internals
- Verbs become mutable — a cursed room could change how LOOK works
- New verbs = new files; no engine changes
- Aligns with "code IS the world" philosophy

**Implications if adopted:**
- Room-specific verbs (this room has a TASTE verb that others don't)
- Cursed interactions (LOOK returns nonsense)
- Per-universe verb sets (magic realm has different verbs than mundane realm)
- Dynamic verb creation (new tools unlock new verbs)

**Next Steps:** Requires Bart (Architect) analysis and decision.

---

## See Also

- **Design Directives:** `design-directives.md` (locked design decisions)
- **Verb System:** `verb-system.md` (current verb reference)
- **Architecture Decisions:** `../../.squad/decisions.md`
