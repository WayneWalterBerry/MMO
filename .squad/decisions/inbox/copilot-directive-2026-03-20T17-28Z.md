### 2026-03-20T17:28Z: User directive — Split-screen terminal UI
**By:** Wayne Berry (via Copilot)
**What:**
1. **Output window (top):** Scrollable, read-only to user. Engine writes all game output here. User can scroll up/down to review history.
2. **Input window (bottom):** Narrow, where user types commands. No output goes here. Has a cursor for input.
3. **Delimiter:** Visual separator between output and input windows.
4. **Status bar (top line):** Single line at very top. Some content left-justified, some right-justified. Content TBD — put placeholder text for now.
5. The input area should be separate from the output — engine output never mixes with user typing.

**Why:** User request — proper text adventure UI with separate I/O areas, scrollable history, and status display. Standard IF client layout.
