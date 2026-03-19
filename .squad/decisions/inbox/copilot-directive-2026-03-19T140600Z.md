### 2026-03-19T140600Z: Architecture clarification — Any meta property overridable
**By:** Wayne "Effe" Berry (via Copilot)
**What:** ANY meta property of a base object can be overridden at the instance level. This isn't limited to descriptions — size, weight, capacity, categories, sensory descriptions, tool capabilities, ANYTHING.

**Example:** The base `bed` class defines a standard bed. But:
- Bedroom instance: `overrides = { size = 4, description = "A massive four-poster bed..." }`
- Servant's quarters instance: `overrides = { size = 2, description = "A narrow cot with a thin mattress." }`
- King's chamber instance: `overrides = { size = 6, weight = 200, description = "An enormous canopied bed..." }`

Same base class GUID, completely different feel per room. The base provides defaults. The instance makes it unique.

This applies to EVERY property: weight, size, capacity, on_feel, on_smell, on_taste, on_listen, room_presence, categories, requires_tool, provides_tool, surfaces, contents, keywords — all overridable.

**Why:** Clarification of instance model. Designers define base objects once, then customize per room via lightweight overrides. Massive content reuse with room-specific character.
