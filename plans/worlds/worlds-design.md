# Worlds System Design Plan

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-08-21  
**Status:** ✅ COMPLETE (Design phase); V1 in pre-production  
**Scope:** World meta-hierarchy design (spec + examples)  
**Dependencies:** Loader, Registry, Level system (already complete)  
**Related Decision:** `D-WORLDS-CONCEPT`

---

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-08-21 | Initial design plan: hierarchy, theme system, World 1 spec, future vision | D-WORLDS-CONCEPT checkpoint + CBG design synthesis |

---

## Table of Contents

1. [Goals](#goals)
2. [Scope](#scope)
3. [Design Decisions](#design-decisions)
4. [World 1 Specification](#world-1-specification)
5. [Theme System Rationale](#theme-system-rationale)
6. [Engine Integration](#engine-integration)
7. [Future Worlds Vision](#future-worlds-vision)
8. [Rollout Plan](#rollout-plan)
9. [Open Questions](#open-questions)

---

## Goals

### Primary Goals

1. **Organize content hierarchically**: Support 100+ levels by grouping them into thematic Worlds
2. **Ensure aesthetic consistency**: Theme metadata guides designer decisions across all contained Levels
3. **Enable parallel content tracks**: Different worlds for different player preferences (dark mode, puzzle-only, etc.)
4. **Prepare for multiplayer**: World boundaries can become rift points for co-op moments (V2+)
5. **Simplify Level 2+ design**: Reuse proven World 1 theme for smooth progression

### Secondary Goals

- Provide designer documentation format for new worlds
- Enable world selection UI (future)
- Support permadeath/difficulty modes per world
- Create expansion points for new game modes

---

## Scope

### In Scope (V1 Design)

✅ **World metadata format** — Define `src/meta/worlds/world-01.lua` structure  
✅ **Theme system** — Aesthetic, mood, constraints, material palette  
✅ **World 1 ("The Manor") specification** — All 3 levels, consistent theme  
✅ **Boot sequence** — Auto-load single World at game start  
✅ **Template** — Create `src/meta/templates/world.lua`  
✅ **Design documentation** — `docs/design/worlds.md` (complete spec)  
✅ **Future vision** — Multi-world, rifts, parallel tracks (roadmap only)  

### Out of Scope (Phase 5+)

❌ **World selection UI** — Deferred to V2 (multiple worlds not ready)  
❌ **Rift mechanics** — Multiplayer co-op (future architecture)  
❌ **World-specific verbs** — e.g., "salvage" in Swamp vs. "examine" in Manor  
❌ **Permadeath/difficulty modes** — Associated with worlds, but not designed yet  
❌ **Theme enforcement linting** — Optional; designer-driven validation only  

---

## Design Decisions

### D1: World as Metadata Container (Not Gameplay Container)

**Decision:** Worlds define AESTHETIC and CONSTRAINTS, not gameplay systems.

**Rationale:**
- Worlds are too high-level to control gameplay mechanics
- Theme guidance happens at design time, not runtime
- Engine doesn't need to know "is this the Manor or the Swamp?"—only designers need to

**Examples:**
- ✅ "The Manor has no steel—use iron instead" (theme constraint)
- ❌ "The Manor has no NPCs" (this is a V1 limitation, not a world constraint)
- ✅ "The Swamp uses salvage-based resource economy" (world-specific design)
- ❌ "The Swamp has 2x creature spawn rate" (this is a parameter, not a theme)

### D2: Single World Boot (V1)

**Decision:** V1 game boots into World 1 automatically. No world selection menu.

**Rationale:**
- Only one world shipped in V1 (The Manor)
- Multi-world detection not needed yet
- Auto-boot is simplest, fastest path to launch

**Future change:** V2 detects multiple worlds and shows selection menu.

### D3: Theme is Designer Guidance, Not Engine Enforcement

**Decision:** Theme constraints are ASPIRATIONAL. Engine does not validate compliance.

**Rationale:**
- Overly strict validation blocks designer creativity
- Violations are intentional (e.g., anomalies, story beat exceptions)
- Designer reviews (code review, PR feedback) catch major theme breaks

**Example:**
```
"The Manor forbids steel" is a guideline.
If a designer uses steel for a story reason, they document it:
  -- Anomaly: Ancient iron chest has steel reinforcement from a previous owner's repair
  materials = {"iron", "steel"}  -- EXCEPTION: see design notes
```

### D4: Lazy Loading Keeps Memory Small

**Decision:** Worlds loaded at boot; Levels/Rooms loaded on demand.

**Rationale:**
- World .lua files are small (~500 bytes each)
- Level/Room files are large; load only when needed
- Boot time is O(1) in world count

**Example:**
```
Boot:     World 1 (~500 bytes)
Gameplay: Level 1 (~50 KB) + Room 1 (~30 KB) = 80 KB active
Player moves to Level 2: Level 2 (~50 KB) loaded; Level 1 can be unloaded
```

### D5: Theme Structure: 8-Field Format

**Decision:** Every World has `pitch`, `era`, `aesthetic`, `atmosphere`, `mood`, `tone`, `constraints`, `design_notes`.

**Rationale:**
- **Pitch:** 1-liner for pitching the world (e.g., to playtesters)
- **Era:** Historical/fantasy context (helps material/tech choices)
- **Aesthetic:** Concrete design guidance (materials, colors, forbidden things)
- **Atmosphere:** Sensory experience (how rooms should feel)
- **Mood:** Emotional resonance (paranoid? adventurous? melancholic?)
- **Tone:** Narrative voice (serious? comedic? tragic?)
- **Constraints:** Designer rules (what is NOT allowed)
- **Design notes:** Commentary on purpose and strategy

Together, these 8 fields fully specify a world's identity.

### D6: Starting Room vs. Level Start Room

**Decision:** `world.starting_room` (game boot) != `level.start_room` (intra-level respawn).

**Rationale:**
- **World boot** happens once; player starts in the iconic location (e.g., bedroom)
- **Level respawn** may differ (e.g., player dies in Level 1, respawns at hallway entrance, not bedroom)
- Two different purposes; separate fields avoid confusion

**Example:**
```lua
world_1.starting_room = "start-room"     -- Game boots here (bedroom)
level_1.start_room = "start-room"        -- If we ever add respawn, could be different
```

### D7: Theme Files (Lazy, Optional)

**Decision:** Optional `theme_files` table for designer-only documentation.

**Rationale:**
- Some themes are too large for one table (e.g., detailed sound design)
- Can reference external .md files without loading them at runtime
- Designers can read `theme_files` to understand world fully; engine ignores them

**Example:**
```lua
theme_files = {
    sound_design = "docs/design/worlds/themes/manor/sound.md",
    room_patterns = "docs/design/worlds/themes/manor/room-patterns.md",
}
```

---

## World 1 Specification

### The Manor

**Concept:** Gothic domestic horror, late medieval manor, 1450s. Player imprisoned and must escape through progressive revelation of the manor's secrets.

**Levels:**
- **Level 1 (The Awakening):** Bedroom + Cellars (7 rooms)
  - Player wakes in locked bedroom with no memory
  - Must navigate darkness using senses
  - Teaches fundamental systems: dark navigation, tool usage, resource scarcity
  - Key paths: escape via cellar stairs OR courtyard window
  
- **Level 2 (The Descent):** Crypt + Underground Passages (10+ rooms, FUTURE)
  - Deeper exploration reveals the manor's age
  - Introduces combat with environmental creatures
  - Puzzle chains (e.g., finding keys, solving mechanisms)
  
- **Level 3 (The Reckoning):** Manor Proper (15+ rooms, FUTURE)
  - Player emerges into the manor proper
  - Final escape or discovery of deeper mystery
  - Boss encounter or final puzzle chain

**Theme:**
- **Pitch:** "Late medieval manor (1450s). Trapped. Dark. Escaped."
- **Era:** Medieval (1400–1500). No anachronisms.
- **Aesthetic:** Stone, iron, wood, tallow, wool, leather, glass. Forbidden: steel, concrete, plastic, electrical.
- **Atmosphere:** Claustrophobic stone chambers. Scarcity of light. Organic sounds (creaking, wind, animals) and silence.
- **Mood:** Paranoid. Vulnerable. Each shadow is potential threat.
- **Tone:** Serious. Dark humor rare. Moments of beauty amid decay.
- **Constraints:**
  - No magic
  - No NPCs with dialogue (environmental creatures only)
  - Melee combat only
  - No electrical technology
  - Scarcity of light is CORE mechanic
- **Design Notes:** "The Manor is a training ground. By Level 1's end, player is competent in all V1 systems. Level 2 deepens with combat and mystery. Level 3 answers questions or opens new ones."

**Estimated Play Duration:**
- Level 1: 45–60 minutes
- Level 2: 60–90 minutes (future)
- Level 3: 90–120 minutes (future)
- **Total:** ~4 hours (future, all 3 levels)

---

## Theme System Rationale

### Why Theme Matters

**Theme prevents design drift.** As a project grows, inconsistencies emerge:

- Level 1 has tallow candles; Level 2 suddenly has electric lights
- Level 1 forbids magic; Level 2 has wizards
- Mood shifts from dark/paranoid to comedic without warning

A clear theme acts as a **guardrail**. Designers check: "Does this fit The Manor?"

### Theme vs. Mechanics

**Common confusion:** "Is theme separate from mechanics?"

**Answer:** Yes, but they're tightly coupled.

| Aspect | Mechanics | Theme |
|--------|-----------|-------|
| **Question** | "How does light work in code?" | "What does light FEEL like in this world?" |
| **Answer (Mechanics)** | Candles have `casts_light = true` property; scoping rules apply. | Candles are precious, consumable, fragile. Light is scarce. |
| **Decision Impact** | How engine handles light radius | How designers place candles in rooms |

**Theme doesn't change mechanics.** Theme changes DESIGN decisions—what gets built, where, and why.

### Theme as Onboarding

New designers can read the theme and immediately understand:
- What materials to use (stone, not steel)
- What era to imagine (medieval, not modern)
- What mood to create (paranoid, not cheerful)
- What is OUT of scope (no NPCs, no magic)

This is far more efficient than case-by-case code reviews.

---

## Engine Integration

### 1. Boot Sequence Changes

**Current (pre-Worlds):**
```lua
local level = loader.load("src/meta/levels/level-01.lua")
local room = loader.load("src/meta/rooms/start-room.lua")
context:set_room(room)
```

**New (with Worlds):**
```lua
local world = loader.load("src/meta/worlds/world-01.lua")
local level = loader.load("src/meta/levels/level-" .. world.levels[1] .. ".lua")
local room = loader.load("src/meta/rooms/" .. world.starting_room .. ".lua")
context:set_world(world)
context:set_room(room)
```

### 2. Context Object

**Add to context:**
```lua
context.current_world = world
context.current_level = level
context.current_room = room
```

### 3. Level Transitions

**Existing code (no change needed):**
```lua
if room.exits[exit_direction].target_level then
    -- Load new level, new room
end
```

**Enhanced (future, with world awareness):**
```lua
if room.exits[exit_direction].target_world then
    -- Load new world, trigger rifts/transitions
end
```

### 4. World Selection (Future)

**Not needed in V1.** When V2 adds multiple worlds:

```lua
local function select_world()
    local worlds = registry:find_all_by_template("world")
    if #worlds == 1 then
        return worlds[1]  -- Auto-boot
    else
        -- Show menu, return selected world
    end
end
```

---

## Future Worlds Vision

### V2+: The Multiverse

Once The Manor is solid (V1), we design new worlds:

| World | Era | Concept | Playability |
|-------|-----|---------|-------------|
| **The Manor** | Medieval 1450s | Gothic domestic horror, escape | V1 ✅ (3 levels) |
| **The Swamp** | Post-Apocalyptic +200Y | Flooded civilization, salvage | V2 (planned) |
| **The Palace** | Medieval-Fantasy | Courtly intrigue, NPCs | V3+ (future) |
| **The Crypt** | Timeless | Dark mode, permadeath, high difficulty | V3+ (future) |
| **The Archive** | Timeless | Puzzle-only, no combat | V3+ (future) |

### World Linking: Rifts

**Rift mechanic (V2+):** Worlds can **merge** at boundaries for co-op moments:

```lua
-- Level 3 boss: The Rifting Gate
-- Player 1 in The Manor summons Player 2 from The Swamp
-- They fight boss together, then return to solo play
```

This is **high-level architecture.** The Worlds system is necessary foundation for rifts to exist.

### Parallel Content Tracks

Players could choose worlds for different reasons:

- **Speed-runners:** "The Crypt" (permadeath, no respawn, high difficulty)
- **Puzzle lovers:** "The Archive" (combat-free, pure logic)
- **Story seekers:** "The Palace" (NPC dialogue, quests)
- **Completionists:** "The Manor" (balanced, all systems)

Each world is a **different game**, reusing the same engine.

---

## Rollout Plan

### Phase 1: Design (V1 Pre-Production) ✅

- [x] Define World format and theme structure
- [x] Write `docs/design/worlds.md` (design spec)
- [x] Document The Manor (World 1) completely
- [x] File decision `D-WORLDS-CONCEPT` in `.squad/decisions.md`

**Status:** COMPLETE

### Phase 2: Implementation (V1 Development)

- [ ] Create `src/meta/templates/world.lua` template
- [ ] Create `src/meta/worlds/world-01.lua` (The Manor)
- [ ] Update `main.lua` boot sequence to load World
- [ ] Update registry to support `find_all_by_template("world")`
- [ ] Integration test: boot game → verify World 1 loads
- [ ] Update `docs/architecture/` with World loading flowchart

**Owner:** Bart (Engine Architect)  
**Estimate:** 1–2 days  

### Phase 3: Content Creation (V1 Development)

- [ ] Finalize Level 1–3 definitions with World 1 theme in mind
- [ ] Create all Level 1 rooms using The Manor theme
- [ ] Validate all Level 1 objects against theme constraints
- [ ] Code review: ensure no anachronisms, theme violations

**Owner:** Comic Book Guy (Game Designer) + Flanders (Object Engineer)  
**Estimate:** 3–5 days  

### Phase 4: Playtest (V1 Release)

- [ ] Player feedback: "Does The Manor feel cohesive?"
- [ ] Collect theme violations or design opportunities
- [ ] Document learnings for Worlds 2–5

**Owner:** Nelson (QA)  
**Estimate:** 1–2 weeks  

### Phase 5: Multi-World Design (V2 Pre-Production)

- [ ] Design The Swamp (World 2) using The Manor as template
- [ ] Write theme spec for Swamp
- [ ] Design 2–3 Swamp levels
- [ ] Plan rift mechanics for world-linking

**Owner:** Comic Book Guy (Game Designer)  
**Estimate:** 2–4 weeks  

---

## Open Questions

### Q1: Should Theme be Versioned?

**Q:** If The Manor theme evolves, do we version it?  
**A (Draft):** No. World theme is immutable once a world ships. If we need major changes, we create a new world (e.g., "The Manor Expanded" as separate world).

### Q2: Can Levels Cross Worlds?

**Q:** Can Level 2 be in a different World than Level 1?  
**A (Draft):** No (V1). Each world owns its levels sequentially. This simplifies progression.  
**Future (V2+):** Rifts enable cross-world co-op, but that's different architecture.

### Q3: How are Worlds Discovered/Unlocked?

**Q:** Can players unlock new worlds?  
**A (Draft):** Not in V1. Single-world auto-boot.  
**Future (V2+):** Achievement-based world unlock, hidden worlds, NG+ modes.

### Q4: Should Theme Validation Be Automated?

**Q:** Should linters check "all objects use theme materials"?  
**A (Draft):** Optional. Designer-driven first (code review). Automated linting is nice-to-have.

### Q5: How Many Worlds Should We Design?

**Q:** What's the target?  
**A (Draft):** 3 concurrent worlds in V2. 5 total by end of Early Access. Then re-evaluate.

---

## Success Criteria

The Worlds system is **successful** when:

1. ✅ **Design spec is complete** — `docs/design/worlds.md` exists and is comprehensive
2. ✅ **World 1 theme is clear** — All Level 1–3 content uses The Manor theme consistently
3. ✅ **Bootup works** — `lua src/main.lua` loads world correctly
4. ✅ **No anachronisms** — Code review finds zero theme violations in shipped content
5. ✅ **Designers understand it** — New designers can read World spec and design new content correctly
6. ✅ **Playtesters notice it** — Feedback includes "The Manor feels cohesive" or "worlds feel distinct" (V2+)
7. ✅ **Foundation is solid** — V2 can add Swamp/Palace without major refactoring

---

## Appendix: Quick Reference

### Create a New World

1. **Generate GUID** (Windows, unique)
2. **Write theme** (8 fields, 500 words min)
3. **Create world .lua file** (`src/meta/worlds/world-{id}.lua`)
4. **Assign levels** (update `levels` array)
5. **Set starting_room** (must exist in level 1)
6. **Validate against theme** (code review)
7. **Document in docs/** (linked from `docs/design/worlds.md`)

### Theme Checklist

- [ ] Pitch (1-liner)
- [ ] Era (historical/fantasy context)
- [ ] Aesthetic (materials, forbidden, colors)
- [ ] Atmosphere (sensory, ambiance)
- [ ] Mood (emotional resonance)
- [ ] Tone (narrative voice)
- [ ] Constraints (design rules)
- [ ] Design notes (commentary)

---

**End of Document**
