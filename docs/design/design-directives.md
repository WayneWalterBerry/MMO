# Design Directives

**Last updated:** 2026-03-20  
**Audience:** Game Designers (Comic Book Guy et al.)  
**Purpose:** Consolidated reference for all game design directives when building objects, rooms, and mechanics.

---

## V1 Scope

**V1 Playable Test:** Single room, breakable objects, text REPL.

| Aspect | Directive | Source |
|--------|-----------|--------|
| **Play Test Target** | Get to playable test as fast as possible with single-room prototype | Wayne (2026-03-19T012051Z) |
| **Scope Boundaries** | Breakable objects, interactive elements | Wayne (2026-03-19T012051Z) |
| **Interface** | Text REPL only (no graphical UI for V1) | Wayne (2026-03-19T012051Z) |

---

## Light & Time System

### Light System

**Core Mechanic:** Objects cast light. Outside areas during daytime have natural light. Inside areas need either a window to the outside or objects that cast light (e.g., torches, candles, lit lamps).

| Rule | Details | Source |
|------|---------|--------|
| **Outside + Daytime** | Naturally illuminated | Wayne (2026-03-19T012411Z) |
| **Inside + No Light Source** | Dark — need window or light-casting object | Wayne (2026-03-19T012411Z) |
| **Light Objects** | Torch, candle, lamp with `casts_light = true` | Wayne (2026-03-19T012411Z) |
| **Window Mechanic** | Provides light during daytime; blocked at night | Wayne (2026-03-19T012411Z) |

### Time System

**Core Mechanic:** Game time moves faster than real time. One real-time hour = one full in-game day (6 AM to 6 PM is daytime).

| Rule | Details | Source |
|------|---------|--------|
| **Time Scale** | 1 real hour = 1 game day | Wayne (2026-03-19T012411Z) |
| **Daytime Window** | 6 AM to 6 PM (in-game) | Wayne (2026-03-19T012411Z) |
| **Darkness Outside** | Daytime (6 AM–6 PM) = outside is lit; nighttime (6 PM–6 AM) = outside needs light sources | Wayne (2026-03-19T012411Z) |

---

## Tools System

### Tool Convention (requires_tool / provides_tool)

**Core Pattern:** Tools enable verb actions on other objects via **capability matching**, not item-ID matching.

- **`requires_tool = "capability"`** — Declared on a mutation target; declares that this verb/mutation needs a tool with a specific capability.
- **`provides_tool = "capability"`** — Declared on a tool object; declares what capability this tool provides.

The engine resolves tool requirements by searching the player's inventory for any object whose `provides_tool` matches the target's `requires_tool`.

#### Tool Categories & Examples

| Tool Capability | Examples | Use Case |
|-----------------|----------|----------|
| **fire_source** | Match, matchbox, lighter, flint | Light candles, torches, fire |
| **cutting_tool** | Knife, sword, razor | Cut paper, rope, cloth; self-injury |
| **writing_tool** | Pen, pencil | Write on paper (WRITE ON paper WITH pen) |
| **prying_tool** | Crowbar, chisel | Open sealed containers, doors |
| **injury_source** | Knife, pin | Draw blood for use as writing instrument |

#### Consumable Tools

Tools can have limited charges via `charges` property and `on_tool_use` block:

```lua
provides_tool = "fire_source",
charges = 3,
on_tool_use = {
    consumes_charge = true,
    when_depleted = "matchbox-empty",
    use_message = "You strike a match...",
    depleted_message = "That was your last match.",
},
```

When a tool is depleted, it mutates to the `when_depleted` variant (full code rewrite per D-14).

#### Tool Matching vs. Item-ID Matching

| Pattern | Matches by | Example | Use |
|---------|-----------|---------|-----|
| `requires = "item-id"` | Specific item ID | `requires = "brass-key"` → bedroom door | Unique keys; one-to-one relationships |
| `requires_tool = "capability"` | Any provider of capability | `requires_tool = "fire_source"` → any match, lighter, etc. | Interchangeable tools; flexibility |

**Design Rule:** Use `requires = "item-id"` for unique items (specific key fits specific lock). Use `requires_tool = "capability"` for interchangeable tools (any fire source lights any candle).

---

## Writing & Paper

### Paper Object

**Core Mechanic:** Sheet of paper is a writable object. Writing on paper requires a writing tool: pen, pencil, or blood. The paper mutates when written on to include the written words.

| Directive | Details | Source |
|-----------|---------|--------|
| **Paper Object** | `sheet-paper.lua` or similar | Wayne (2026-03-19T014604Z) |
| **Writing Tools** | Pen, pencil, or blood | Wayne (2026-03-19T014604Z) |
| **Interaction Pattern** | WRITE ON {paper} WITH {pen\|pencil\|blood} | Wayne (2026-03-19T014604Z) |
| **Mutation Behavior** | When words are written, the paper object's code MUTATES to include those words. The paper literally becomes a different object (paper-with-writing) via the mutation engine. | Wayne (2026-03-19T014629Z) |
| **Reading** | LOOK AT paper shows what was written | Wayne (2026-03-19T014629Z) |

**Implementation Note:** The paper is a beautiful application of the true code rewrite mutation model (D-14) to player-generated content. The paper's code IS its state, including whatever the player wrote.

---

## Injury & Blood

### Blood as Writing Instrument

**Core Mechanic:** Players can injure themselves to draw blood, which can be used as a writing instrument on paper.

| Tool | Method | Verb | Result |
|------|--------|------|--------|
| **Knife** | Cut self | CUT SELF WITH knife | Draw blood; provides writing capability |
| **Pin** | Prick self | PRICK SELF WITH pin | Draw blood; provides writing capability |

**Constraint:** Blood is a dark, consequential resource. Players must actively choose to injure themselves to get this writing material. This creates moral/physical stakes around writing.

**Design Note:** Pin and knife are in the `injury_source` tool category. They are also in other categories (pin is a lock-picking tool with the right skill; knife is a cutting/weapon tool).

---

## Player Skills System

### Skills Mechanics

**Core Pattern:** Players can learn skills (e.g., lockpicking) through gameplay. A skill unlocks new tool+verb combinations that weren't available before. Skills are learned by finding books, practicing, being taught by NPCs, or other narrative triggers.

**Key Design Insight:** The same tool can have different uses depending on the player's skills. A pin without lockpicking skill = prick yourself to draw blood. A pin WITH lockpicking skill = pick a lock (alternative to using brass key) OR prick yourself.

### Skill-Enabled Tool Combinations

| Skill | Tool | Normal Use | Skill-Enabled Use | Replaces |
|-------|------|-----------|-------------------|----------|
| **Lockpicking** | Pin | Prick self (injury_source) | Pick lock on door | Brass key (one-time use) |
| **Weaponry** | Knife | Cut paper (writing tool) | Combat attack | (N/A for V1) |

**Design Rule:** Skills unlock alternative verb→tool combinations, creating emergent puzzle solutions and replay value. A skill doesn't replace the base use; it adds new capabilities.

### Learning Skills

| Method | Example | Design Note |
|--------|---------|-------------|
| **Find a book** | "Lockpicking Manual" in library | Player reads book → learns skill |
| **Practice** | Use lockpicking multiple times → proficiency | Skill grows through repetition |
| **NPC Teaching** | NPC mentor teaches skill | Narrative trigger; relationship-based |
| **Puzzle Solution** | Solve puzzle with tool → unlock related skill | Emergent learning |

---

## Mutation Model

### Code Rewrite vs. State Flags

**Core Principle (D-14):** The game uses **true code rewrite mutation model**. When game state changes, the object's definition/code is literally transformed — "the code IS the state." No separate state flags.

| Approach | Pro | Con | Decision |
|----------|-----|-----|----------|
| **Code Mutation** | Philosophically pure; emergent behavior; world literally evolves | Potentially LLM-costly; complex state tracking | ✅ **CHOSEN** (D-14) |
| **State Flags** | Simpler, faster iteration; traditional | Less magical; hidden state; harder to debug | Fallback if mutation cost prohibitive |

**Example:** Mirror object exists in code. When player types "BREAK mirror," the engine rewrites the mirror's code to reflect its broken state (`mirror.lua` → `mirror-broken.lua`). The player never touches code — they interact naturally; the engine translates their actions into code mutations.

### Engine-Driven Mutation (Not Player-Driven)

**Core Principle (D-12):** 
- ❌ Player modifies code directly
- ✅ Player interacts naturally → engine modifies code on their behalf

**Example:** Player types "LIGHT candle." Engine searches inventory for fire_source tool, finds matchbox, and mutates candle's code from `candle.lua` → `candle-lit.lua` (which includes `casts_light = true`). Player never writes code; they just play naturally.

---

## Newspaper

### Daily Edition Requirements

**Core Directive:** Every daily newspaper edition must include two recurring sections:

| Section | Content | Frequency | Design Note |
|---------|---------|-----------|-------------|
| **Comic Strip** | Daily comic panel or short comic sequence | Every edition | Thematic to game/team |
| **Op-Ed Piece** | Editorial opinion, developer commentary, or in-character article | Every edition | Voice of the game world |

**Architecture Note:** These are not one-off features; they are recurring structural elements that must be updated daily. See `newspaper/` folder for current editions.

### Documentation Maintenance

**Core Directive:** Keep architecture and design docs up to date as decisions and implementation progress. Docs should reflect current state, not lag behind.

| Document | Owner | Cadence |
|----------|-------|---------|
| Design directives | Game designers | Update as new directives added |
| Tool taxonomy | Architects | Update as new tool categories discovered |
| Architecture | Lead engineer | Update as decisions locked in |
| Game design foundations | Designer lead | Quarterly or as pillars shift |

---

## Object Design Patterns

### Multi-Surface Containment Model

**Pattern:** Objects with multiple interaction zones use `surfaces` instead of flat `contents`. Each surface has `capacity`, `max_item_size`, `weight_capacity`, and `accessible` flag.

**Examples:**
- **Bed:** `top` (where you sleep), `underneath` (storage)
- **Nightstand:** `top` (surface), `inside` (drawer)
- **Vanity:** `top` (surface), `inside` (drawer), `mirror_shelf`
- **Rug:** `top` (visible), `underneath` (hidden)

**Design Rule:** Never hide critical-path items without a hint. Example: rug description says "one corner is slightly raised" → hints at LOOK UNDER without spoiling.

### Composite Mutation Matrix (Multi-State Objects)

**Pattern:** When an object has N independent toggleable properties, it requires 2^N mutation files.

**Example - Vanity (2 axes: drawer open/closed × mirror intact/broken = 4 files):**
- `vanity.lua` — drawer closed, mirror intact
- `vanity-open.lua` — drawer open, mirror intact
- `vanity-mirror-broken.lua` — drawer closed, mirror broken
- `vanity-open-mirror-broken.lua` — drawer open, mirror broken

**Trade-off:** File count grows exponentially with independent states. For most objects (1 axis), this is fine. For 3+ axes, consider whether some states can be collapsed or chained.

### Template Inheritance

**Pattern:** Objects that share a base type use `template = "sheet"` to inherit default properties from `src/meta/templates/sheet.lua`. Instance overrides win.

**Template Examples:**
- `sheet.lua` — Fabric/cloth family (size 1, weight 0.2, portable, tearable)
- `furniture.lua` — Heavy immovable (size 5, weight 30, not portable)
- `container.lua` — Bags, boxes, chests (capacity 4, weight_capacity 10)
- `small-item.lua` — Tiny items (size 1, weight 0.1, portable)

**Design Rule:** Template resolution happens at load time. Instance fields override template fields. Nested tables (mutations, surfaces) are replaced wholesale, not deep-merged.

### Room Object Hierarchy

**Pattern:** Room `contents` lists only top-level furniture. Portable items live inside furniture surfaces, not directly in the room. This creates a natural discovery hierarchy: enter room → see furniture → examine furniture → find items.

**Example - Bedroom start state:**
```
Bedroom
├── bed (furniture)
│   ├── top (surface) → bed-sheets, pillow
│   └── underneath (surface) → wool-cloak
├── nightstand (furniture)
│   ├── top → candle
│   └── inside → (empty)
├── vanity (furniture)
│   ├── top → (empty)
│   └── inside → (empty)
├── wardrobe (furniture)
│   ├── inside → (empty)
├── curtains (furniture)
│   └── window behind
├── rug (furniture)
│   └── underneath → brass-key (hidden)
```

---

## Skill Interaction Matrix

Use this matrix when designing new tools and deciding whether a skill should unlock new interactions:

| Skill | Tool | Verb | Requirement | Alternative to |
|-------|------|------|-------------|-----------------|
| (none) | Knife | CUT | Tool exists | Required item |
| (none) | Pin | PRICK | Tool exists | Required item |
| (none) | Pen/Pencil | WRITE | Tool exists | Required item |
| (none) | Match/Matchbox | LIGHT | Tool exists, fire_source capability | Required item |
| **Lockpicking** | Pin | PICK LOCK | Tool exists + skill learned | Brass key (specific ID) |
| **Crafting** | Knife + Wood | CARVE | Tools exist + skill learned | (N/A for V1) |

**Design Note:** Blanks in this table are opportunities for new skills. Each skill should have at least one tool+verb combination that no other skill provides.

---

## Key Architectural Alignments

These directives align with core architectural decisions:

- **D-14 (Code Rewrite Mutation):** Paper mutation with written words; mirror breaking; candle lighting
- **D-12 (Engine-Driven Mutation):** Player interacts naturally; engine handles code changes
- **D-10 (Multiverse Per-Player):** Each player's universe has independent state
- **Tool Convention:** Enables verb dispatch on multiple similar tools via capability matching
- **Skills System:** Adds emergent tool combinations; increases replay value and puzzle diversity

---

## Adding New Directives

When Wayne issues new design directives:

1. Capture in `.squad/decisions/inbox/` with timestamp filename
2. Summarize the directive with source and date
3. Add to appropriate category in this document (create new category if needed)
4. Update tables and examples
5. Link to full decision file if it's a major architectural change

This is a **living document**. Refer to `.squad/decisions.md` and `.squad/decisions/inbox/` for full details on any directive.

---

## See Also

- **Game Design Foundations:** `docs/design/game-design-foundations.md`
- **Tool Objects Design:** `docs/design/tool-objects.md`
- **Containment Constraints:** `docs/design/containment-constraints.md`
- **Full Decisions Archive:** `.squad/decisions.md`
- **Recent Directives Inbox:** `.squad/decisions/inbox/`
