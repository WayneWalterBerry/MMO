### 2026-03-20T22:10Z: User directive — Separate "design" (gameplay) from "architecture" (technical)
**By:** Wayne Berry (via Copilot)
**What:** The docs need reorganization based on a clear distinction:

- **Design** = gameplay design. How objects operate from the player's perspective. What happens when you light a candle, how the clock works, puzzle mechanics, object interactions. This is the GAME DESIGN.
- **Architecture** = technical implementation. FSM engine, .lua metadata format, how the engine reads .lua files, GOAP planner internals, parser layers. This is HOW we build it.

Current `docs/design/` mixes both concerns. Reorganize:
- `docs/design/` → gameplay design docs (object behaviors, puzzle design, player interactions, wearable rules, spatial relationships from a gameplay perspective)
- `docs/architecture/` → technical docs (FSM engine, .lua format, parser architecture, GOAP internals, engine layers, data flow)

The existing files need to be sorted into the correct folder based on whether they describe gameplay or technical implementation.

**Why:** User request — clarity of purpose. When Wayne says "design" he means gameplay. The team should never confuse game design discussions with architecture discussions.
