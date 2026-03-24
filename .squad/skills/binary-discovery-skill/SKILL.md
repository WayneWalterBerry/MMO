# Binary Discovery Skill Pattern

**Category:** Gameplay System Pattern  
**Authored by:** Comic Book Guy  
**Introduced:** 2026-03-21  
**Status:** Reusable across all skills (MVP + future)

---

## What This Pattern Solves

How do you unlock advanced tool+verb combinations without creating a grinding progression system? How do you keep skills simple (binary: have/don't have) while making discovery feel organic?

**This pattern:** Skills are binary gates, discovered through gameplay, not earned through XP.

---

## The Pattern: 4-Step Loop

```
┌─────────────────────────────────────────────────┐
│ DISCOVERY: Player finds lockpicking manual      │ ← Find object in room
│                                                 │
├─────────────────────────────────────────────────┤
│ RECOGNITION: Player reads/examines manual       │ ← Action on object
│                                                 │
├─────────────────────────────────────────────────┤
│ UNDERSTANDING: Engine confirms player has read  │ ← State change
│                                                 │
├─────────────────────────────────────────────────┤
│ ENABLEMENT: Verb handlers now check skill gate  │ ← PICK LOCK now allowed
└─────────────────────────────────────────────────┘
```

### Concrete Example: Lockpicking Skill

| Step | Action | State Change | Result |
|------|--------|-------------|--------|
| 1. Discovery | Player finds "Lockpicking Manual" in library | Manual enters inventory | Manual appears in `INVENTORY` list |
| 2. Recognition | Player `READ manual` | Manual is consumed | Engine checks for "lockpicking" content → marks learned |
| 3. Understanding | Engine sets `player.skills.lockpicking = true` | Game state mutated | Player now has skill |
| 4. Enablement | Player attempts `PICK LOCK WITH pin` | Verb handler checks gate | Action allowed; lock opens |

---

## Why Binary, Not Progressive?

| Model | Complexity | Learning Curve | Replayability |
|-------|-----------|-----------------|---------------|
| **Binary** (this pattern) | Low | "I learned it!" | High (different skill order each playthrough) |
| **XP/Levels** | High | "Grind to level 2" | Low (optimal path emerges, grinds discovered) |
| **Percentage** (0–100%) | Medium | "Practice until proficient" | Medium (clear progress bar, but monotonous) |

**Binary is correct for dark IF:** Discovery-based games shouldn't require grinding. The player learns by exploring, not by iterating. When the skill "clicks," it's a eureka moment, not a progress bar.

---

## Implementation Template

### 1. Define the Skill

```lua
-- skill_definition.lua
{
  id = "lockpicking",
  name = "Lockpicking",
  description = "The ability to pick locks with small tools.",
  verbs_unlocked = { "PICK_LOCK" },
  tools_required = { "lockpick" },
  failure_consequence = "bent-pin",  -- Mutation on failed attempt
}
```

### 2. Create the Discovery Object (Manual)

```lua
-- lockpicking-manual.lua
{
  id = "lockpicking-manual",
  name = "a worn lockpicking manual",
  keywords = { "manual", "lockpicking", "book", "guide" },
  skill_teaches = "lockpicking",
  consumable = true,  -- Manual is consumed on READ
  on_read = function(self, player)
    player.skills.lockpicking = true
    return "You read the manual carefully. You understand the principles of lock picking now."
  end,
}
```

### 3. Gate the Verb Handler

```lua
-- In verb_handler.pick_lock:
local function handle_pick_lock(player, target, tool)
  -- Gate 1: Does player have skill?
  if not player.skills.lockpicking then
    return "[BLOCKED] You don't know how to pick locks."
  end
  
  -- Gate 2: Does tool provide lockpick capability?
  if not tool.provides_tool or tool.provides_tool ~= "lockpick" then
    return "[BLOCKED] That tool is not suitable for picking locks."
  end
  
  -- Check proficiency (V2): Lower failure rate at higher levels
  -- For V1, proficiency is always 1 (binary: 30% fail rate)
  local proficiency = player.skills.lockpicking.level or 1
  local fail_chance = 30 / proficiency  -- 30% at level 1, 15% at level 2, etc.
  
  if math.random() < fail_chance then
    -- Failure: consume tool
    player:remove_item(tool)
    local bent = require("meta.objects.bent-pin"):new()
    player:add_item(bent)
    return "The pin bends against the lock. Useless."
  end
  
  -- Success
  target:unlock()
  return "The lock clicks open."
end
```

### 4. Provide Alternative Paths (No Skill Required)

```lua
-- Same chest, alternative solution: brass key
-- Player finds brass key in a different room
-- Verb: UNLOCK chest WITH key
-- Requirement: None (no skill needed)

-- Result: Both paths work. Skills aren't gates, they're accelerators.
```

---

## Variations of This Pattern

### Variation A: Practice-Based Discovery

Instead of reading a manual, the player discovers the skill by using a tool:

```lua
-- After player PRICKs self 5+ times with pin:
if player.statistics.pricks >= 5 then
  player.skills.lockpicking = true
  print("After poking yourself many times with the pin, you realize: 'I could use this to pick a lock!'")
end
```

**Pros:** No manual needed; feels organic.  
**Cons:** Players might never discover it; requires design signposting.

### Variation B: NPC Teaching

An NPC teaches the skill via dialogue (requires dialogue system):

```lua
-- NPC dialogue option:
[7] "Can you teach me to pick locks?"
    → NPC: "Follow me. First, you need steady hands..."
    → player.skills.lockpicking = true
```

**Pros:** Narrative integration; character-driven.  
**Cons:** Requires dialogue system; can feel forced if not well-written.

### Variation C: Observational Discovery

Player discovers skill by finding all components together:

```lua
-- If player finds needle + thread + cloth in same room:
print("You lay out the needle, thread, and cloth. 'Aha! I know how to do this now.'")
player.skills.sewing = true
```

**Pros:** Pure discovery; rewards exploration.  
**Cons:** Unreliable; players might miss it.

---

## Design Patterns That Work With This

### Pattern: "Compound Tools"
Sewing requires BOTH needle (tool) AND thread (material). Binary skill gates the entire compound:

```lua
-- BEFORE skill:
SEW cloth WITH needle → [BLOCKED] "You don't know how to sew."

-- AFTER skill:
SEW cloth WITH needle → checks for thread → creates terrible-jacket
```

### Pattern: "Failure Consequences"
Failed attempts consume the tool, teaching resource scarcity:

```lua
-- Bent pin on failed lock pick
-- Tangled thread on failed sewing
-- Both force player to find a new tool, creating pacing
```

### Pattern: "Alternative Paths"
Every puzzle has a no-skill solution, preserving player agency:

```
Puzzle: Open locked chest

Path A (no skill): Find brass key elsewhere
Path B (lockpicking): Find manual, learn skill, pick lock
Path C (future): Persuade NPC to open it
```

---

## Pitfalls to Avoid

| Pitfall | Why It's Bad | How to Avoid |
|---------|------------|-------------|
| Skill gates the only solution to a puzzle | Frustrating; forces specific path | Always provide no-skill alternative |
| Manual is hard to find | Player never discovers skill | Place manual in obvious room (library, study) |
| Skill feels like cheating | Players feel like they're "exploiting" | Frame skill as earned knowledge, not a shortcut |
| Too many skills; discovery is unclear | Overwhelming; players miss some | Keep MVP limited (2–3 skills); document clearly |
| Binary feels flat; no sense of progress | Demotivating; "I learned it or I didn't" | Add future proficiency levels (V2); design progression narrative |

---

## Checklists for Designers

### When Creating a New Skill

- [ ] Define the skill (id, name, description)
- [ ] Pick discovery method (manual, practice, NPC, observation)
- [ ] Create discovery object if needed (manual, NPC dialogue)
- [ ] List verbs unlocked by skill
- [ ] Define failure consequence (consumable or warning)
- [ ] Design no-skill alternative path for any gated puzzle
- [ ] Playtest: Confirm skill can be learned without walkthrough
- [ ] Playtest: Confirm skill actually helps (feels rewarding to use)
- [ ] Document in `player-skills.md` skill matrix

### When Using a Skill in Puzzle Design

- [ ] Verb gate: Check `player.skills[skill_id]` in handler
- [ ] Tool gate: Check `tool.provides_tool` matches requirement
- [ ] Failure mode: Define consumable cost (bent tool, tangled thread)
- [ ] Alternative path: Design no-skill solution
- [ ] Placement: Put skill manual/NPC near puzzle (hint, don't force)
- [ ] Pacing: Don't gate critical path; reserve for optional content

---

## Future Extensions (V2+)

### Proficiency Levels

```lua
player.skills = {
  lockpicking = { learned = true, level = 2, xp = 150 },
  sewing = { learned = true, level = 1, xp = 45 },
}

-- Higher level = lower failure rates, faster action speed
```

### Skill Trees

```
Basic Sewing (level 1)
  ↓ (learn 5 patterns)
  ↓
Advanced Tailoring (level 2)
  ├─ Armor Crafting
  └─ Fancy Clothing
```

### Skill Decay

```lua
-- If player doesn't use lockpicking for 20+ in-game hours:
if game_time - player.skills.lockpicking.last_used > 72000 then
  player.skills.lockpicking.level = player.skills.lockpicking.level - 1
end
```

---

## References

**Prior Art:**
- **Zork (Infocom, 1980):** Lock picking with lockpick → alternative to key
- **TADS 3:** Skill system with object-based learning
- **Leather Goddesses of Phobos (Infocom, 1986):** Skills affect perception (can't see clues without skill)

**This Project:**
- `docs/design/player-skills.md` — Full skill system design
- `.squad/decisions/inbox/comic-book-guy-player-skills.md` — Decision memo

---

**Template Author:** Comic Book Guy  
**Pattern Status:** ✅ Proven on lockpicking and sewing skills  
**Recommended for:** Any text adventure with gated mechanics and alternative puzzle paths

*"This pattern is elegant because it respects the player. You learn because you're curious, not because a number told you to. That's interactive design." — Comic Book Guy*
