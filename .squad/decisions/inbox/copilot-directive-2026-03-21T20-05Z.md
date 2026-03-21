### 2026-03-21T20:05Z: User directives — Injury accumulation and targeted treatment
**By:** Wayne Berry (via Copilot)

**Directive 1 — Injuries are accumulative:**
Multiple injuries stack. If a player has two stab wounds each draining 2 health/turn, they lose 4 health/turn total. Health = max_health - sum(all_injury_damage). This is implicit in the derived health model but needs to be explicit in the design docs.

**Directive 2 — Targeted treatment:**
Players apply cures to SPECIFIC injuries, not generic health. "Apply bandage to left arm stab wound" targets a specific injury instance. If there's only one injury, "apply bandage" should work without specifying the target (same context-resolution pattern as objects).

**Directive 3 — Consumable treatments (salve):**
Salve is a consumable — the instance is destroyed after application. One use, gone. Same pattern as spent match (terminal + consumable).

**Directive 4 — Reusable treatments (bandage):**
Bandages are NOT consumable — they're persistent instances that attach to an injury:
- A bandage applied to a cut accelerates healing
- Once the cut heals, the bandage can be REMOVED and applied to another injury
- A single bandage instance can only be on ONE injury at a time
- This makes bandages a reusable resource the player manages

**Directive 5 — Treatment items are object instances with state:**
- Bandage states: clean → applied (to injury X) → dirty (after removal) → clean (if washed?)
- Salve states: sealed → applied (consumed, instance destroyed)
- The bandage's FSM tracks which injury it's attached to
- The injury's FSM knows it has a bandage accelerating its healing

**Why:** This creates rich resource management gameplay — bandages are strategic (which wound gets the bandage?), salves are one-shot (use wisely), and multiple injuries create pressure to prioritize treatment.
