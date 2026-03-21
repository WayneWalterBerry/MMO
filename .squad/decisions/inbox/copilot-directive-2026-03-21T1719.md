### 2026-03-21T17:19: User directive — File sizes in loading messages
**By:** Wayne Berry (via Copilot)
**What:** The loading status messages should include file sizes for debugging. Examples:
- `Loading Game Engine... (85 KB compressed)`
- `Decompressing Engine... (633 KB)`
- `Loading Room: Bedroom... (4.2 KB)`
- `Loading Object: Matchbox... (1.1 KB)`
This helps diagnose performance issues and gives a sense of how much data is being transferred.
**Why:** Debugging aid — Wayne wants to see transfer sizes in the boot log.
