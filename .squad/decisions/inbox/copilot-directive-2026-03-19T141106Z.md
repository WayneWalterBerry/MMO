### 2026-03-19T141106Z: Architecture directive — Human-readable names in instance definitions
**By:** Wayne "Effe" Berry (via Copilot)
**What:** When listing instances in a room definition, include a `name` field next to `id` and `base_guid` for human readability. GUIDs are for the engine, names are for humans reading the code.

**Example:**
```lua
instances = {
  {
    id = "matchbox-1",
    name = "Matchbox",
    base_guid = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
    location = "nightstand-1.inside",
    contents = {"match-1", "match-2", "match-3"}
  },
  {
    id = "poison-bottle-1",
    name = "Poison Bottle",
    base_guid = "f6e5d4c3-b2a1-4987-6543-210fedcba987",
    location = "nightstand-1.top",
    overrides = {
      description = "A small glass bottle with a faded label..."
    }
  },
}
```

The `name` is a convenience field — the engine resolves by GUID, but a developer/designer reading the room file can instantly see what each instance IS without looking up the GUID.

**Why:** User request — code readability. GUIDs are opaque. Names make room files scannable by humans.
