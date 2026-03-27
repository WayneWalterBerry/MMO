### 2026-03-27T00:17: User directive
**By:** Wayne Berry (via Copilot)
**What:** Eating certain food can cause injuries. Eating raw rat meat might cause rabies. The `eat` verb should be a FIRST-CLASS verb in the engine — not a minor extension, but a full verb handler with effects processing (nutrition, healing, poison, disease). Food objects declare `on_eat` effects in their metadata: `on_eat = { effects = { { type = "inflict_injury", injury_type = "rabies", chance = 0.15 } } }`. The eat handler processes these effects through the existing effects pipeline. This connects food → injuries → disease in one clean chain.
**Why:** User design direction — eat is a primary game mechanic, not a convenience feature. Food-borne disease is a core risk/reward mechanic.
