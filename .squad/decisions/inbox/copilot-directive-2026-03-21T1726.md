### 2026-03-21T17:26: User directive — In-game bug reporting
**By:** Wayne Berry (via Copilot)
**What:** Add a `report bug` verb to the game. When typed, it captures the session transcript (last N commands + responses) and opens a pre-filled GitHub issue URL in a new browser tab at https://github.com/WayneWalterBerry/MMO/issues/new. The issue title auto-fills with `[Bug Report] {room name} - {timestamp}` and the body contains the session transcript. Works with private repo since the tester's own GitHub auth handles permissions.
**Why:** Beta testing feature — lets players report bugs directly from the game with full context.
