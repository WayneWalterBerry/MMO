# Engine UX Decisions — Bart

## D-UX001: Visited Room Tracking with Short Descriptions
**Author:** Bart (Architect)
**Date:** 2026-07-24
**Status:** Implemented

When the player re-enters a previously visited room, the engine shows only the bold room title and `short_description` (one-line summary) instead of the full room description. First visit always shows the full description. The explicit "look" command always shows the full description regardless of visit history.

**Implementation:** `ctx.visited_rooms` is a Lua table used as a set (room_id → true). Initialized in `main.lua` and `web/game-adapter.lua` with the starting room pre-marked. The `handle_movement` function in `verbs/init.lua` checks and updates this set.

**Rationale:** Standard text adventure convention. Reduces text fatigue on backtracking while preserving full exploration on first entry. "look" as override ensures players can always re-read room details.

---

## D-UX002: Bold Room Titles via Markdown Markers
**Author:** Bart (Architect)
**Date:** 2026-07-24
**Status:** Implemented

Room titles are emitted wrapped in `**double asterisks**` (markdown bold convention). The engine outputs `**The Bedroom**` instead of `The Bedroom`. This applies everywhere a room title is displayed: bare "look" (lit and dark), and movement arrival.

**Rationale:** Engine-agnostic marker that works across renderers. CLI users see the asterisks as visual emphasis. The web layer can detect `**...**` patterns and convert to `<strong>` elements. No ANSI dependency, no custom tag syntax — just markdown convention that's universally understood.

---

## D-UX003: Room short_description is Optional Metadata
**Author:** Bart (Architect)
**Date:** 2026-07-24
**Status:** Implemented

Rooms MAY have a `short_description` field (one-line summary). When present, it's shown on revisit alongside the bold title. When absent, only the bold title is shown. The room template is not changed — this is optional instance-level metadata. All 7 existing rooms have been given short descriptions.
