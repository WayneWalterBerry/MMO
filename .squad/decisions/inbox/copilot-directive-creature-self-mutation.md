### 2026-03-27T00:13: User directive
**By:** Wayne Berry (via Copilot)
**What:** The engine should allow creature instances to completely change into an object instance on death. The creature .lua file would know how to rewrite itself into an object — the mutation target is declared in the creature's own metadata. Dead creature becomes food (or corpse, or loot container) via self-declared mutation. This is D-14 (code mutation IS state change) applied to the creature→object type boundary.
**Why:** User design direction — creatures declare their own death transformation, keeping object-specific logic OUT of the engine (Principle 8).
