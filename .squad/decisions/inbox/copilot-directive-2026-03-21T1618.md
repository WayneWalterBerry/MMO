### 2026-03-21T16:18: User directive — Loading status messages
**By:** Wayne Berry (via Copilot)
**What:** The web game must show one-line status messages during loading, in light gray, as each resource loads:
- `Loading Bootstrapper...` (from JavaScript, before Fengari starts)
- `Decompressing XYZ...` (from bootstrapper, if using compressed files)
- `Loading Level 1...` (from JIT loader)
- `Loading Room Bedroom...` (from JIT loader)
- `Loading Bed...` (from JIT loader, per object)
Each message is one line, appended to the terminal area. Light gray color so it's visible but not distracting. Useful for debugging and gives the player a sense of progress.
**Why:** User UX + debugging requirement — visible loading sequence helps diagnose issues and gives feedback during initialization.
