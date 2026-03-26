### 2026-03-26T15:48Z: NPC Phase 1 — 7 open questions resolved (batch approve)
**By:** Wayne Berry (via Copilot)

**NPC Q1 — Respawning:** Permanent death in Phase 1. Killed creatures stay dead. Respawn system deferred to Phase 2 if needed.

**NPC Q2 — Multiple creatures per room:** Yes. Support N creatures per room from day one.

**NPC Q3 — Rat inventory:** Deferred to Phase 2. Rat in Phase 1 has no inventory, cannot carry or steal objects.

**NPC Q4 — Rat bite mechanics:** ALREADY RESOLVED — simple injuries.inflict() on grab, no combat FSM. (See earlier decision.)

**NPC Q5 — Sound across rooms:** Yes. Creatures with sound_range > 0 emit audible events to adjacent rooms.

**NPC Q6 — Save/load persistence:** Registry-driven. Creatures are objects in the registry; existing save/load handles them identically.

**NPC Q7 — Hear rat in darkness:** Yes — this is a FEATURE. Player hears "skittering claws" before they can see anything. Rat's on_listen provides audio-only presence in darkness.

**Why:** Wayne batch-approved all 7 NPC recommendations. Zero open questions remain across both plans.
