# Decision: Injury Template Canonical Format

**Agent:** Flanders  
**Date:** 2026-07-22  
**Type:** Architecture — Injury Template Specification  
**Status:** Proposed  
**Requested by:** Wayne Berry

---

## Context

Wayne directed that injuries are first-class entities following the same patterns as objects: GUID identity, FSM states/transitions/timers, JIT loading, template→instance separation. The engine must stay generic (Principle 8). We needed a canonical `.lua` format that injury authors can follow.

## Decision

Created `docs/architecture/player/injury-template-example.md` as the authoritative reference for injury `.lua` template files. The format mirrors the object template pattern exactly:

### Key Design Choices

1. **Same FSM format as objects** — `states{}`, `transitions{}`, `timed_events`, `mutate{}`, `terminal` markers. The FSM engine processes injuries identically to objects. No injury-specific engine code.

2. **GUID identity** — Each injury type gets a Windows GUID in `{...}` format, consistent with the object metadata identity system.

3. **Three damage types as configuration** — `one_time`, `over_time`, `degenerative` are declared in the template's `damage_type` field. The engine applies the appropriate formula. No type-specific branches.

4. **Template vs. Instance separation** — Template on disk defines FSM blueprint. Instance at runtime adds: `id` (unique), `_state`, `source`, `inflicted_at`, `turns_active`, `damage`, `damage_per_tick`, `severity`, `_timer`. Template tables (`states`, `transitions`, `healing_interactions`) are NOT copied into the instance — engine looks them up.

5. **Dual-side healing validation** — Object declares `cures = "bleeding"`, injury declares `healing_interactions["bandage"]`. Both must agree. Prevents spoofing, enforces intentional design.

6. **JIT loading** — Injury definitions cached on first reference. Same sandboxed loader as objects. In production, fetched from CDN alongside object files.

7. **Files live in `src/meta/injuries/`** — Peer directory to `src/meta/objects/`. Same build pipeline, same loader, same sandbox.

8. **Capability restrictions per state** — `restricts = { climb = true }` in state definitions. Engine checks these before allowing player actions.

## Artifacts

- `docs/architecture/player/injury-template-example.md` — Full canonical reference with annotated `bleeding.lua` example, instance vs. template comparison, healing object cross-reference patterns, JIT loading explanation, required fields table, and quick-start guide.

## Rationale

Following Principle 8 ("The Engine Executes Metadata; Objects Declare Behavior") and the Dwarf Fortress property-bag architecture directive, injuries must be pure metadata declarations. The canonical example demonstrates this by showing a complete injury template with zero engine-specific knowledge — just data tables that the generic FSM engine reads and executes.

## Cross-References

- `docs/architecture/player/injuries.md` — Full system architecture (Bart)
- `docs/design/injuries/README.md` — Design workflow (CBG)
- `docs/architecture/objects/core-principles.md` — Object pattern reference
