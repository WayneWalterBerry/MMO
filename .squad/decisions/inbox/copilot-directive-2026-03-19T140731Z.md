### 2026-03-19T140731Z: Architecture directive — GUIDs as primary reference, not names
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The engine should use GUIDs (not string names) as the primary way to reference base classes. When a room loads and encounters `base_guid = "xxx"`, the engine:
1. Checks: do I have this GUID in my base class cache?
2. YES → resolve instance against cached base
3. NO → fetch/download the base class by GUID (future — stub for now)

This means:
- `base_guid` is the authoritative reference in instance definitions (not `base = "matchbox"` by name)
- The template system (`template = "small-item"`) should also use GUIDs
- Contents arrays should reference instance IDs (which resolve to base GUIDs)
- The registry indexes by GUID as the primary key
- Names are for DISPLAY only, not for resolution

**Implications for current code:**
- `loader.resolve_template(object, templates)` currently looks up by template NAME → switch to GUID
- `registry:find_by_keyword()` stays for player-facing search (TAKE candle)
- `registry:find_by_guid()` becomes the engine-internal lookup
- Instance `location` references use instance IDs (which are room-scoped)

**Why:** User request — GUIDs are the addressing system for the streaming architecture. Names are ambiguous (two rooms could have different "bed" objects). GUIDs are globally unique and network-addressable.
