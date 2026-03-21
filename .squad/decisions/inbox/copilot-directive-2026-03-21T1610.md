### 2026-03-21T16:10: Architecture directive — Windows GUIDs on all metadata
**By:** Wayne Berry (via Copilot)
**What:** ALL metadata entities MUST have a Windows-style GUID identifier (e.g., `{550e8400-e29b-41d4-a716-446655440000}`). This applies to:
- Objects (already have GUIDs — verify they are real Windows GUIDs, not human-readable strings)
- Rooms (need GUIDs added)
- Levels (need GUIDs added)
- Templates (need GUIDs added)
- Materials (need GUIDs added when split to individual files)

The GUID is the **primary key for JIT loading** — the web loader fetches resources by GUID. File names on the static site should be GUID-based (e.g., `/play/meta/objects/{guid}.lua`).

No human-readable ID strings like `ROOM-BEDROOM-001`. Real Windows GUIDs only.
**Why:** Architecture decision — GUIDs enable JIT loading, are globally unique, and scale to MMO.
