### 2026-03-21T17:18: User directive — Timestamp-based versioning
**By:** Wayne Berry (via Copilot)
**What:** Use the build/deploy timestamp as the version displayed to the user — NOT semantic version numbers. The bootstrapper shows its deploy timestamp, the engine shows its build timestamp. No manual version tracking needed. The timestamp IS the version.
Example: `Loading Bootstrapper (2026-03-21 16:45)...` and `Loading Engine (2026-03-21 16:45)...`
**Why:** Eliminates version number maintenance. The deploy timestamp is always accurate and requires zero manual tracking.
