### 2026-03-19T135750Z: Architecture directive — GUIDs for Streaming
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Every room and object (including base templates) must have a unique GUID. This prepares for a streaming/download architecture where the phone app can request objects it doesn't have cached by GUID. 

**Rules:**
- Every .lua object file gets a `guid` field (UUID v4)
- Every room gets a `guid` field
- Base templates get GUIDs too
- GUIDs are stable — once assigned, never change (even if object is mutated)
- The engine loader should read and register GUIDs
- NO download/streaming code yet — just assign the IDs

**Future architecture (don't build yet):**
- Engine checks local cache for GUID → if miss, downloads from server
- Enables expansion packs: new rooms/objects are just new GUIDs the phone doesn't have yet
- Enables live content updates without app store releases
- Universe state = set of GUIDs + mutations applied to them

**Why:** User request — forward-looking architecture. GUIDs are cheap to add now and enable the streaming model later. Every object becomes addressable across the network.
