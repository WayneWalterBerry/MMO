### 2026-03-21T21:15Z: User directive — Parent READMEs must reflect folder structure
**By:** Wayne Berry (via Copilot)
**What:** When creating or reorganizing doc folders, always update the parent README.md to list the new folder. The docs/ README should list both objects/ and injuries/ as siblings. Any folder that contains subfolders should have a README that maps what's inside. This prevents folders from being "lost" — if it's not in the parent README, it doesn't exist.
**Why:** Documentation discoverability. The README chain (docs/ → docs/injuries/ → individual files) is the navigation system.
