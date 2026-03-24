### 2026-03-24T20:35Z: User directive — Mirror design
**By:** Wayne Berry (via Copilot)
**What:** The mirror on the vanity is a separate instance object placed on_top of the vanity, based on a "hand mirror" base class. The vanity itself is NOT a mirror — remove `is_mirror = true` from vanity.lua. The mirror needs its own object definition with keywords like "mirror", "looking glass", sensory properties (on_feel, etc.), and should support "look in mirror" for appearance.
**Why:** User design correction — the vanity was incorrectly marked as a mirror. Objects should be composites (Principle 4), not flag-decorated.
