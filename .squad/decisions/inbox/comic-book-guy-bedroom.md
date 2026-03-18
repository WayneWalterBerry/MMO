# Decision: Bedroom Design Patterns

**Author:** Comic Book Guy (Game Designer)
**Date:** 2026-03-20
**Status:** Proposed
**Impact:** Object model, engine requirements

## Decisions Made

### 1. Multi-Surface Containment Model
Objects with multiple interaction zones use `surfaces` instead of flat `contents`. Each surface has `capacity`, `max_item_size`, and `contents`. Examples: bed (top, underneath), nightstand (top, inside), vanity (top, inside, mirror_shelf), rug (underneath).

**Engine requirement:** The engine must resolve nested containment — items inside surfaces of objects inside rooms. LOOK IN, LOOK ON, LOOK UNDER commands must target specific surfaces.

### 2. Composite Mutation Matrix (Vanity Pattern)
When an object has N independent toggleable properties, it requires 2^N mutation files. The vanity has 2 axes (drawer open/closed, mirror intact/broken) = 4 files. Each is a complete standalone object definition. All state transitions are explicit.

**Trade-off:** File count grows exponentially with independent states. For most objects (1 axis), this is fine. For 3+ axes, consider whether some states can be collapsed.

### 3. Template Inheritance for Object Families
Objects that share a base type use `template = "sheet"` to inherit default properties from `src/meta/templates/sheet.lua`. Instance overrides win. Used for: bed-sheets, curtains.

**Engine requirement:** Template merging must happen at load time. Instance fields override template fields. Nested tables (mutations, categories) should be replaced wholesale, not deep-merged.

### 4. Hidden Object Discovery Pattern
Objects can contain hidden items (rug → brass-key underneath). The `on_look` function should hint at hidden content without revealing it. Separate verbs (LOOK UNDER, SEARCH) should expose hidden contents.

**Design rule:** Never hide critical-path items without a hint. The rug description says "one corner is slightly raised." This is fair play. Hiding items with zero hints is an anti-pattern (see game-design-foundations.md Anti-Patterns).

### 5. Room Object Hierarchy
Room `contents` lists top-level furniture. Portable items live inside furniture surfaces, not directly in the room. This creates a natural discovery hierarchy: enter room → see furniture → examine furniture → find items.

### 6. Bedroom as Start Room
The player now starts in a bedroom instead of a study. This is more natural for a "waking up" narrative opening and provides immediate interactive objects (bed to get out of, curtains to open, wardrobe to explore, key to find).

## Objects Created
- vanity.lua, vanity-open.lua, vanity-mirror-broken.lua, vanity-open-mirror-broken.lua
- bed.lua, pillow.lua, bed-sheets.lua, blanket.lua
- nightstand.lua, nightstand-open.lua, candle.lua, candle-lit.lua
- wardrobe.lua, wardrobe-open.lua, wool-cloak.lua
- rug.lua, brass-key.lua
- curtains.lua, curtains-open.lua, window.lua, window-open.lua
- chamber-pot.lua

## Objects Removed
- desk.lua, desk-open.lua (replaced by vanity)
- mirror.lua, shattered-mirror.lua (mirror integrated into vanity)
