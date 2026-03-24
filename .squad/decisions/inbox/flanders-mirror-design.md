# Decision: Mirror is a Separate Object from Vanity

**Author:** Flanders
**Date:** 2026-07-28
**Issue:** #173
**Affects:** Bart (engine — `is_mirror` flag routing), Nelson (tests updated), Smithers (parser keyword resolution), Moe (room placement)

## Decision

The mirror is now a **separate instance object** (`src/meta/objects/mirror.lua`) placed `on_top` of the vanity in `start-room.lua`. The vanity itself is no longer tagged as a mirror.

## What Changed

1. **New object:** `mirror.lua` with `is_mirror = true`, own FSM (intact/cracked/broken), glass material
2. **Vanity:** `is_mirror` flag removed; mirror-specific keywords ("mirror", "looking glass", "reflection", "my reflection", "vanity mirror") moved to mirror object
3. **start-room.lua:** Mirror placed in vanity's `on_top` array
4. **Tests:** Updated to verify `is_mirror` on mirror object, not vanity

## Impact

- **Parser:** "mirror", "reflection", "looking glass" now resolve to the mirror object, not the vanity. No disambiguation conflict.
- **Engine:** Any code checking `is_mirror` will find it on the mirror object. The vanity no longer has this flag.
- **Vanity broken states:** The vanity still has `closed_broken`/`open_broken` FSM states describing its appearance when the mirror frame is broken. These may need future alignment with the mirror object's own broken state — but that's a separate task.
- **Break verb routing:** "break mirror" should now target the mirror object (which has break transitions). The vanity's break transitions still exist but would require the player to say "break vanity" explicitly.
