### 2026-03-20T19:05Z: User directive — Timed event objects (timers, clocks, time bombs)
**By:** Wayne Berry (via Copilot)
**What:**
1. **Timed event objects:** Some objects run on timers embedded in their .lua metadata. Two patterns:
   - **One-shot timer** (time bomb): after N time units, something happens once (explosion, door unlocks, etc.)
   - **Recurring timer** (clock): every N time units, something happens repeatedly (chime, tick, drip, etc.)
2. **Room-level event tracking:** When a room loads an object instance, the engine tracks its time events and triggers them automatically in the output window.
3. **First implementation: Wall clock in bedroom.** Chimes at the top of every in-game hour. Output: "The clock chimed three times." (for 3 o'clock). The chime count matches the hour.
4. **Metadata-driven:** The timer schedule lives in the object's .lua file, not in the engine. The engine just reads and executes the schedule. This keeps it extensible — any object can have timed events.
5. **Output integration:** Timed events emit text to the output window regardless of what the player is doing. They're ambient — the clock chimes whether you're looking at it or not.

**Why:** User request — ambient world events create atmosphere and time awareness. Enables puzzle mechanics (time bombs, timed doors) and world immersion (clock chimes, dripping water, creaking floorboards).
