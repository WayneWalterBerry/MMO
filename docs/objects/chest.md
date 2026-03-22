# Chest — Object Design (Planned)

> Design document for a heavy container object. Not yet implemented in code.

## Description
A substantial wooden storage chest requiring two hands to carry. Opens and closes to control access to contents.

**Type:** Container with weight constraint
**Material:** `oak` or `pine`
**Status:** Design doc only — implementation pending

## Container Mechanics

The chest inherits from the **Container** template with additional constraints:

### Two-Handed Carry Requirement
- **Portable:** `true`
- **Two-handed:** `true` — Requires both player hands to carry
- Cannot be carried while holding other items or weapons
- Cannot be equipped in weapon slots

### Capacity
- **Volume:** 8 item slots (large chest)
- **Weight limit:** 30 units (can hold substantial items)

## Open/Closed States

Chest supports open and closed states (via Container's sensory rules):

- **Closed:** Contents NOT accessible. Cannot look, feel, search, or examine items inside.
- **Open:** Contents fully accessible. All senses work on interior contents.

### FSM States (Planned)

```
closed ↔ open
```

- **closed** — Default. Lid closed, contents hidden and inaccessible.
- **open** — Lid propped open, inside surface accessible.

## Surfaces

- **inside:** Accessible only when chest is open. Capacity 8, max item size 3.

## Properties

- **Size:** 5 (large)
- **Weight:** 20 (base, empty)
- **Weight capacity:** 30 (contents)
- **Portable:** Yes (with two-handed constraint)
- **Categories:** `container`, `furniture`, `wooden`
- **Keywords:** chest, trunk, storage chest, wooden chest, treasure chest

## Design Rationale

### Why Two Hands?
The two-handed requirement reflects the chest's weight and awkwardness:
- Makes it a strategic choice — players sacrifice combat readiness or dual-wielding to transport
- Prevents trivial use (can't be a quick loot container in combat)
- Creates moment of vulnerability when moving heavy loot

### Why Not a Furniture?
Unlike fixed furniture, chests are portable — players can move them between rooms. This supports treasure hunting and base-building gameplay loops.

## Implementation Plan

1. **Extend Container template** with `two_handed = true` flag
2. **Add carry validation** — Prevent picking up if hands are occupied
3. **Define FSM transitions** — OPEN/CLOSE verbs with state mutations
4. **Add inside surface** — Only render when `open`
5. **Test sensory access** — Verify contents hidden when closed, accessible when open

## See Also

- [Container Template](../templates/container.md) — Base inheritance and open/closed sensory rules
- [Two-Handed Items](../design/two-handed-items.md) — Constraint pattern (if it exists)
- [Nightstand](./nightstand.md) — Another composite object example

---

**Created:** 2026-12-XX
**Status:** Pending implementation
