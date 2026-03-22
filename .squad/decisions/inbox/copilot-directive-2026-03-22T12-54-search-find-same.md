### 2026-03-22T12:54: User directive — Search vs Find is NOT the distinction
**By:** Wayne (Effe) Berry (via Copilot)
**What:** The words "search" and "find" are interchangeable. The real distinction is:
- TARGETED mode: "search for XYZ" = "find XYZ" (stop when found)
- SWEEP mode: "search the room" = "find everything in the room" (visit all)
The presence of a target noun determines mode, NOT the verb word.
"Search for matchbox" and "Find matchbox" are identical operations.
"Search the room" and "Find everything" are identical operations.
**Why:** Clarification — the engine should NOT have separate code paths for search vs find. One engine, two modes (targeted vs sweep), determined by whether a target noun is present.
