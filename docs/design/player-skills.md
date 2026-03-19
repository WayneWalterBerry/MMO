# Player Skills System

**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-21  
**Status:** Design Complete (Ready for implementation review)  
**Related:** `design-directives.md`, `tool-objects.md`, `containment-constraints.md`

---

## 1. Overview

Skills are the gateway mechanic that unlocks advanced tool+verb combinations. A player without lockpicking cannot PICK LOCK with a pin. A player without sewing cannot SEW cloth with a needle. This creates **emergent puzzle solutions** and **replayability**: the same room solved five different ways depending on what skills the player has acquired.

**Core Design Principle:** Skills unlock *alternative* paths. They never invalidate the base puzzle solution. If a player can open a locked chest with a brass key, they can also open it with a lockpick (if skilled). This rewards player agency and experimentation.

---

## 2. Skill Acquisition Model

Players learn skills through **discovery, practice, and narrative progression**. This is not a leveling system—skills are binary (have/don't have) with optional proficiency tracking for future expansion.

### 2.1 Acquisition Methods

| Method | Example | Design Rationale |
|--------|---------|------------------|
| **Find & Read** | Lockpicking Manual in library | Explicit discovery; rewards exploration; can fail/succeed based on comprehension |
| **Practice** | Use pin to prick self 3+ times → learn lockpicking | Emergent learning; teaches cause-effect; player must discover they *can* prick themselves |
| **Narrative Trigger** | NPC mentor teaches during dialogue | Story beats unlock mechanics; paces skill discovery |
| **Puzzle Solve** | Solve the "paper writing" puzzle → learn about dynamic paper mutations | Meta-learning; player discovers system capabilities |
| **Observation** | Player learns cloth → sewing by finding needle, thread, and cloth together in same room | Implicit discovery; "the pieces tell the story" |

**Implementation Note:** V1 supports **Find & Read** and **Practice** methods. Narrative triggers and observation-based learning are designed for future phases with NPC system.

### 2.2 Skill Discovery Pacing

Skills should be discovered in a natural order:
1. **Early (dark room):** Prick self → discover blood → write with blood (no formal skill needed; it's tactile discovery)
2. **Mid (light obtained):** Find lockpicking manual OR practice pricking until understanding emerges
3. **Late (optional):** Sewing skill via needle+thread combination or NPC teaching

This pacing ensures the player never feels stuck without a skill—always an alternative path exists.

---

## 3. Skill List (MVP + Future)

### 3.1 MVP Skills (Priority 1: Required for V1 puzzles)

| Skill | Unlocks | Primary Tool | Learning Method | Failure Mode |
|-------|---------|--------------|-----------------|--------------|
| **Lockpicking** | PICK LOCK verb + pin | Pin (with `lockpick` capability) | Manual or practice | Pick breaks → splinter in finger (health cost) |
| **Sewing** | SEW verb + cloth | Needle + thread (compound) | Manual or observation | Tangled thread, pricked finger (minor health cost) |

### 3.2 Candidate Skills (Priority 2: Post-V1, designed for expansion)

| Skill | Unlocks | Primary Tool | Use Case |
|--------|---------|--------------|----------|
| **Anatomy** | CUT/PRICK for medical benefit (extract poison, create antidote) | Knife + plant/creature material | Crafting puzzles; non-violent solutions |
| **Alchemy** | BREW verb; combine liquids → new substances | Bottles, mortar, pestle (compound tools) | Potion system; area effects |
| **Cartography** | READ MAP verb with enhanced comprehension; MAP ROOM verb | Paper, pen, ink | Navigation puzzles; world exploration |
| **Interrogation** | Enhanced dialogue options; convince NPC to reveal info | (No tool—social skill) | NPC interactions; alternative solutions |
| **Sleight of Hand** | STEAL verb; palm items undetected | (None—social/dexterity) | Stealth puzzles; non-violence paths |

**Rationale:** MVP skills are bound to tools that already exist in the bedroom (pin, needle, thread). Candidate skills are designed to expand the verb vocabulary and create new object categories (potions, maps, NPCs).

---

## 4. Skill + Tool + Verb Matrix

This matrix shows which skill unlocks which verb+tool combination. It is the **source of truth** for implementation.

### 4.1 Complete Skill Matrix

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Skill Matrix: (Skill, Tool, Verb) → Action Enabled                           │
├──────────────────┬──────────────────┬──────────────┬──────────────────────────┤
│ Skill            │ Tool(s)          │ Verb         │ Enabled Action           │
├──────────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ (none)           │ Pin              │ PRICK SELF   │ Draw blood (always OK)   │
│ (none)           │ Knife            │ CUT SELF     │ Draw blood (always OK)   │
│ (none)           │ Pen + Ink        │ WRITE        │ Write on paper (always)  │
│ (none)           │ Pencil           │ WRITE        │ Write on paper (always)  │
│ (none)           │ Blood            │ WRITE        │ Write w/ blood (always)  │
│ (none)           │ Needle + Thread  │ SEW          │ [BLOCKED] → get skill   │
│ (none)           │ Pin              │ PICK LOCK    │ [BLOCKED] → get skill   │
├──────────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ Lockpicking      │ Pin              │ PICK LOCK    │ Pick lock (enables)      │
│                  │ Pin (alt)        │ PRICK SELF   │ Still works (not replaced) │
├──────────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ Sewing           │ Needle + Thread  │ SEW          │ Sew cloth → clothing     │
├──────────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ Anatomy          │ Knife + Plant    │ CUT          │ Extract poison antidote  │
│ (future)         │ Knife + Creature │ PRICK        │ Extract venom            │
├──────────────────┼──────────────────┼──────────────┼──────────────────────────┤
│ Alchemy          │ Bottle + Liquid  │ BREW         │ Combine → new substance  │
│ (future)         │ Pestle + Mortar  │ GRIND        │ Crush materials          │
└──────────────────┴──────────────────┴──────────────┴──────────────────────────┘
```

### 4.2 Design Rules

1. **Skills unlock alternatives, not replacements.** Pin without lockpicking still pricks (draw blood). With lockpicking, it *also* picks locks.
2. **Compound tools still require both components.** Sewing requires BOTH needle AND thread. Pin alone cannot pick (no thread metaphor).
3. **No skill gating on basic writing.** Pen + paper and blood + paper always work. Ink as a medium is not gated.
4. **Knife ambiguity is resolved by verb.** CUT SELF → injury. CUT rope → cutting edge. PRICK SELF → injury. Each verb dispatches to the correct tool capability.

---

## 5. Progression Model

Skills are **binary in V1** (have / don't have), but designed to support proficiency in V2.

### 5.1 V1: Binary Skills

```lua
player.skills = {
  lockpicking = false,
  sewing = false,
}

-- When player learns:
player.skills.lockpicking = true
```

**Rationale:** Simplicity. Skills are discovery milestones, not grinding mechanics. A player learns lockpicking when they read the manual or practice enough times.

### 5.2 V2 Extension: Proficiency Levels (Future)

```lua
player.skills = {
  lockpicking = { level = 1, xp = 0 },  -- level 0 = not learned, 1+ = learned
  sewing = { level = 2, xp = 850 },     -- higher level = faster craft, less failure
}
```

**Benefits:**
- Practice unlocks proficiency (10 lock picks → level 2)
- Proficiency affects failure rates (level 1 picks have 30% break chance, level 3 = 5%)
- Supports speedrunning / optimization strategies

**Does NOT affect:** Availability of actions. Level 0 lockpicking still *blocks* the PICK LOCK verb entirely.

---

## 6. Failure Modes

When a player attempts a skilled action WITHOUT the skill, they get sensory feedback that teaches the game's logic.

### 6.1 MVP Failure Modes

#### Attempt PICK LOCK without lockpicking skill

**Response:**
```
> PICK LOCK WITH pin
[BLOCKED] You don't know how to pick locks. The pin bends uselessly against the lock.
(Try: Find a lockpicking manual to learn the skill, or find an alternative solution like a key.)
```

**Mechanics:** Pin enters "bent" state (bent-pin.lua); player must restore it (or find another pin).

**Design Rationale:** Teaches consequence. Careless attempts break tools. Real-world feedback.

---

#### Attempt SEW without sewing skill

**Response:**
```
> SEW cloth WITH needle
[BLOCKED] You don't know how to sew. The needle tangles hopelessly in the thread.
(Try: Find a sewing manual to learn, or observe how cloth, needle, and thread work together.)
```

**Mechanics:** Needle + thread are consumed (tangled-mess.lua appears in inventory). Player must find/craft new supplies.

**Design Rationale:** Failure has cost. Mistakes consume resources, encouraging caution and planning.

---

#### Attempt WRITE with missing writing instrument (no skill required, but missing tool)

**Response:**
```
> WRITE "hello" ON paper WITH blood
[BLOCKED] You have no blood available. Try PRICK SELF WITH pin to draw blood first.
```

**Mechanics:** Compound action required. Engine checks for blood as an object before allowing WRITE.

**Design Rationale:** Teaches verb chaining. Some actions have prerequisites.

---

### 6.2 Proficiency-Based Failure (V2)

At proficiency level 1, skilled actions have a failure rate:

| Skill | Level 1 Failure Rate | Level 2 | Level 3 |
|-------|---------------------|---------|---------|
| Lockpicking | 30% (pick breaks) | 15% | 5% |
| Sewing | 25% (thread tangles) | 10% | 2% |

On failure, the tool is consumed (bent pin, tangled thread) and must be replaced. This creates emergent difficulty: players must find multiple tools to practice.

---

## 7. Integration with Existing Systems

### 7.1 Tool Capability Dispatch

The engine checks `requires_tool` on a verb handler to see if the tool provides the required capability:

```lua
-- In verb handler for PICK_LOCK:
local action = {
  verb = "PICK_LOCK",
  object = locked_door,
  tool = pin,
  requires_tool = "lockpick",
}

-- Engine checks:
if not player.skills.lockpicking then
  return "[BLOCKED] You don't know how to pick locks."
end

if not tool.provides_tool or tool.provides_tool ~= "lockpick" then
  return "[BLOCKED] The pin is not suitable for picking locks."
end

-- Action allowed!
```

**Design Insight:** `requires_tool` already exists in verb handlers. Skills add a second gate: tool capability + skill both required.

### 7.2 Compound Tool Actions (Needle + Thread)

The SEW verb requires TWO tools, both in player's possession:

```lua
-- SEW verb handler:
local action = {
  verb = "SEW",
  material = cloth,
  requires_tool_1 = "sewing_tool",      -- needle
  requires_tool_2 = "sewing_material",  -- thread
  requires_skill = "sewing",
}

-- Engine validates:
1. Player has needle (provides sewing_tool) ✓
2. Player has thread (provides sewing_material) ✓
3. Player has sewing skill ✓
4. Cloth is in inventory ✓
5. → Action allowed! Consume needle/thread, create terrible-jacket
```

**Containers vs. Compound Objects:** The engine already supports containers (matchbox with matches). Compound tools (needle + thread) are separate objects in inventory, not one object containing another. They are *co-located by design*, not physically nested.

### 7.3 Dynamic Paper Mutation with WRITE

The WRITE verb enables **dynamic content injection** into paper's description:

```lua
-- paper.lua (base object)
{
  id = "paper",
  name = "a sheet of paper",
  on_feel = "Smooth, cool. It smells faintly of linen pulp.",
  on_look = function(self)
    return "A sheet of cream-coloured paper, unmarked."
  end,
}

-- After: WRITE "help me" ON paper WITH pen
-- Engine generates: paper-with-writing.lua (or mutates paper in-place)
{
  id = "paper",
  name = "a sheet of paper with writing",
  written_text = "help me",
  on_look = function(self)
    return "A sheet of paper. The writing reads:\n\n  \"" .. self.written_text .. "\""
  end,
}
```

**Key Pattern:** The player's written text becomes part of the object's persistent state. Paper is not a stateless surface—it is **code-as-state**. The paper's Lua definition includes the player's words.

### 7.4 Paper Mutation Rules

Once paper is written on, its mutability depends on the **writing instrument**:

| Instrument | Mutability | Result | Future Writes |
|------------|-----------|--------|----------------|
| Pen + Ink | Permanent | `written_with = "ink"` | [BLOCKED] "Already written in permanent ink." |
| Pencil | Erasable | `written_with = "pencil"` | ERASE verb available (restores blank paper) |
| Blood | Permanent + Visceral | `written_with = "blood"` | [BLOCKED] "Already written in blood. Disturbing." |

**Design Rationale:** Materials have consequences. Ink is permanent and clean. Blood is permanent and transgressive (fits the dark game tone). Pencil is the "reversible" option.

---

## 8. Blood Writing Mechanic

Blood is the bridge between the **injury system** and **writing system**. It teaches that player actions have consequences.

### 8.1 The Prick → Bleed → Write Chain

```
Step 1: Player inventory has pin or knife
Step 2: PRICK SELF WITH pin
        → Player loses 5 HP
        → Blood object appears in inventory (or ON player)
        → Player feels pain: "Your finger throbs. Blood drips."
        
Step 3: WRITE "..." ON paper WITH blood
        → Blood is consumed
        → Paper becomes paper-with-blood-writing (permanent, visceral)
        → Player sees: "You write in blood. It looks like a crime scene."
```

### 8.2 Blood Availability Rules

- **One prick = sufficient blood for one write.** Pricking again generates fresh blood, consuming the old supply.
- **Blood has a time limit.** Blood object persists for ~5 game-minutes before it "clots" and becomes unavailable. This teaches urgency.
- **Health cost is real.** Each prick costs 5 HP. The player can bleed to death if reckless (health floor = 0, auto-save required at 1 HP).

### 8.3 Design Philosophy

Blood writing is intentionally **transgressive and costly**. It should feel like a last resort:
- "I have no other writing instrument."
- "I need to sign this in blood to make it real."
- "This is a message someone will be disturbed to see."

The mechanic teaches: **Resources are finite. Choices have consequences.**

---

## 9. Dynamic Paper Mutation Design

Paper is the game's most meta object: its description is **player-authored**, not designer-authored. This is code-as-state pushed to its limit.

### 9.1 Paper States (Finite State Machine)

```
paper (blank)
  ↓ [WRITE "..." ON paper WITH pen/pencil/blood]
  ↓
paper-with-writing (mutated)
  ├─ written_text = player input
  ├─ written_with = "ink" / "pencil" / "blood"
  └─ If written_with == "pencil": ERASE available
  
paper-with-writing (pencil)
  ↓ [ERASE paper]
  ↓
paper (blank) — restored to original state
```

### 9.2 Player Input Validation

The WRITE verb must sanitize player input to prevent engine breakage:

```lua
-- Whitelist allowed characters:
local allowed = "[%w%s%p]+"  -- letters, numbers, spaces, punctuation (Lua regex)

-- Truncate to 256 characters (reasonable limit for a "sheet of paper")
-- Escape quotes and newlines in Lua table definition

-- Example: WRITE "It's <script>alert('xss')</script>" ON paper
-- Becomes: "It's <script>alert('xss')</script>" (stored as-is, but escaped in Lua)
```

**Rationale:** The player's text will be embedded in Lua code. We must ensure it doesn't break the parser.

### 9.3 Paper Mutations in Disk Storage

When paper is written on, the engine performs one of two actions:

**Option A: File-per-state** (preferred for clarity)
- Base: `src/meta/objects/paper.lua` (blank)
- Mutated: `src/meta/objects/paper-with-writing.lua` (created dynamically)
- The mutated file includes the player's written_text in its definition

**Option B: In-place mutation** (simpler but less visible)
- Modify `paper.lua` in-place
- Add `written_text` field during WRITE action
- On room load, paper.lua includes its written_text

**Implementation Recommendation:** Use **Option A** (file-per-state) for consistency with existing mutation patterns (match → match-lit, candle → candle-lit). Files persist on disk and are human-readable (designers can inspect player-authored papers).

---

## 10. Puzzle Design Implications

### 10.1 Skill-Gated Puzzle Solutions

Example puzzle: **"Locked chest in dark room"**

| Approach | Skill Required | Tool Required | Steps | Difficulty |
|----------|----------------|---------------|-------|------------|
| Use brass key | None | Brass key in room | Find key, unlock | Easy (baseline) |
| Pick lock with pin | Lockpicking | Pin in room | Find manual OR practice, prick, unlock | Medium (discovery) |
| Call for help (future NPC) | Interrogation | None | Persuade NPC, they open | Hard (social) |
| Find window (break containment) | None | None | Explore alternative, climb | Hard (exploration) |

**Design Rule:** Every puzzle must have a no-skill solution. Skills are *accelerators*, not blockers.

### 10.2 Skill Discovery Puzzles

Example: **"The Paper Puzzle"**

The game teaches the WRITE verb by the player discovering it:
1. Player finds pen, paper, ink in drawer
2. EXAMINE paper → "A blank sheet"
3. Player tries WRITE "test" ON paper WITH pen
4. Paper mutates → "A sheet of paper with writing. It reads: 'test'"
5. Player learns: "Oh! I can write on things and make them persistent!"

This is **emergent learning**. The skill is meta-learning about the game's verbs, not a formal "skill tree" unlock.

---

## 11. Narrative Integration (Future)

For reference: how skills connect to story (post-V1).

### 11.1 Skill Books as Story

Finding a "Lockpicking Manual" in the library isn't just a mechanic—it's world-building:
- WHO wrote this manual? A thief? A security expert?
- WHY is it in this bedroom? Did someone hide it? Was it borrowed?
- WHEN was it written? Old paper → old manual → historical context

### 11.2 NPC Teaching

A character can teach a skill through dialogue:
```
NPC: "I'll teach you to pick locks. Watch carefully..."
[Player learns: lockpicking]
```

This is a dialogue action, not a verb. Handled by the NPC/dialogue system (future).

---

## 12. Implementation Roadmap

### Phase 1: MVP (Current)
- [x] Skill acquisition: Find & Read method (lockpicking manual, sewing manual in room)
- [x] Skill acquisition: Practice method (prick self multiple times → learn lockpicking)
- [x] Binary skill system (have/don't have)
- [x] Lockpicking skill unlocks PICK LOCK verb
- [x] Sewing skill unlocks SEW verb
- [x] Failure modes (bent pin, tangled thread, blocked messages)
- [ ] Blood writing mechanic (PRICK SELF → blood object → WRITE WITH blood)
- [ ] Dynamic paper mutation (WRITE generates paper-with-writing state)

### Phase 2: Expansion
- [ ] Proficiency levels (practice increases level → lower failure rates)
- [ ] Candidate skills (Anatomy, Alchemy, Cartography, etc.)
- [ ] NPC teaching system
- [ ] Skill books as immersive objects (readable, teachable)

### Phase 3: Integration
- [ ] Skill dialogue triggers (NPC "wants to teach you")
- [ ] Skill-based alternative puzzle paths
- [ ] Skill-gated content (hidden rooms/items only accessible with skills)

---

## 13. Design Decisions Ratified

1. **Skills are binary in V1, not progressive.** Simplicity first. Proficiency levels are designed but not implemented until V2.

2. **Skills unlock alternatives, not replacements.** A pin can prick (without skill) or pick locks (with skill). Both capabilities coexist.

3. **Failure has consequences.** Attempt to pick lock without skill → bent pin (consumed). Failure is **costly**, encouraging planning.

4. **Paper is code-as-state.** Player text is embedded in the paper's Lua definition. Paper mutations are file-per-state for clarity.

5. **Blood writing is transgressive.** Expensive (5 HP per prick), permanent (ink-like), and disturbing (fits dark game tone). A last resort.

6. **Skill discovery is paced naturally.** Early: basic discovery (prick, write). Mid: manual reading or practice. Late: NPC teaching or emergent meta-learning.

---

## 14. Appendix: Tool Capability Reference

For quick lookup during implementation:

| Tool | Provides Capability | Verb | Requires Skill |
|------|-------------------|------|-----------------|
| Pin | `injury_source` | PRICK SELF | None |
| Pin | `lockpick` | PICK LOCK | Lockpicking |
| Knife | `injury_source` | CUT SELF, PRICK SELF | None |
| Knife | `cutting_edge` | CUT rope, cloth, etc. | None |
| Needle | `sewing_tool` | SEW | Sewing |
| Thread | `sewing_material` | SEW (compound) | Sewing |
| Pen | `writing_instrument` | WRITE | None |
| Pencil | `writing_instrument` | WRITE | None |
| Blood | `writing_instrument` | WRITE | None |
| Glass Shard | `cutting_edge`, `injury_source` | CUT, PRICK SELF | None |

---

## 15. References & Prior Art

**Classic IF Games Referenced:**
- **Zork (Infocom, 1980):** The lockpicking puzzle using a lockpick. The sewing concept from object manipulation. The brass key as baseline solution.
- **Leather Goddesses of Phobos (Infocom, 1986):** Multi-path puzzle solving. Skills affect what the player can observe/do.
- **Photopia (Adam Cadre, 1998):** Narrative puzzle gates. Discovery-based learning.

**Modern IF (Parser-Based):**
- **Counterfeit Monkey (Emily Short, 2012):** Word-based puzzles. Object transformations. Skill-like verb unlocks.
- **Fail Safe (not published):** Blood/sacrifice mechanics in dark IF.

**Containment & Tool Systems:**
- **The Inform 7 Recipe Book:** Multi-part tools (handle + blade = knife). Compound actions (STRIKE MATCH ON MATCHBOX).
- **TADS 3 Documentation:** Tool capability dispatch patterns.

---

**End of Document**

*"Worst. Skills. System. Ever. Just kidding—I'm actually quite proud of this one. It's elegant, it teaches through play, and it respects the darkness. Mmm, darkness." — Comic Book Guy*
