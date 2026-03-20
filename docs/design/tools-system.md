# Tools System

**Last updated:** 2026-03-21  
**Audience:** Game Designers  
**Purpose:** Comprehensive reference for tool capabilities, matching patterns, and tool-based interactions.

*This section was extracted from `design-directives.md` for better organization. See also `design-directives.md` for overview context.*

---

## Tool Convention (requires_tool / provides_tool)

**Core Pattern:** Tools enable verb actions on other objects via **capability matching**, not item-ID matching.

- **`requires_tool = "capability"`** — Declared on a mutation target; declares that this verb/mutation needs a tool with a specific capability.
- **`provides_tool = "capability"`** — Declared on a tool object; declares what capability this tool provides.

The engine resolves tool requirements by searching the player's inventory for any object whose `provides_tool` matches the target's `requires_tool`.

### Tool Categories & Examples

| Tool Capability | Examples | Use Case |
|-----------------|----------|----------|
| **fire_source** | Match, matchbox, lighter, flint | Light candles, torches, fire |
| **cutting_tool** | Knife, sword, razor | Cut paper, rope, cloth; self-injury |
| **writing_tool** | Pen, pencil | Write on paper (WRITE ON paper WITH pen) |
| **prying_tool** | Crowbar, chisel | Open sealed containers, doors |
| **injury_source** | Knife, pin | Draw blood for use as writing instrument |

### Consumable Tools

Tools can be consumable — destroyed after a single use or after a timed duration:

```lua
-- match-lit.lua (lit match, provides fire_source temporarily)
provides_tool = "fire_source",
consumable = true,
burn_remaining = 30,
on_consumed = {
    message = "The match flame reaches your fingers...",
    becomes = nil,
},
```

When a consumable tool is used (e.g., LIGHT candle WITH match-lit), the tool is destroyed after the action. Timed consumables (like burning matches) also auto-consume when `burn_remaining` reaches 0.

### Compound Tool Actions

Some actions require two objects working together. Neither alone produces the result:

```lua
-- match.lua (unlit match — NOT a fire_source)
mutations = {
    strike = {
        becomes = "match-lit",
        requires = "matchbox",
        requires_property = "has_striker",
        message = "You drag the match head across the striker strip...",
        fail_message = "You need a rough surface to strike it on.",
    },
},
```

STRIKE match ON matchbox → match becomes match-lit (now provides fire_source). The matchbox is a container with `has_striker = true`; it holds the matches and provides the striking surface.

### Tool Matching vs. Item-ID Matching

| Pattern | Matches by | Example | Use |
|---------|-----------|---------|-----|
| `requires = "item-id"` | Specific item ID | `requires = "brass-key"` → bedroom door | Unique keys; one-to-one relationships |
| `requires_tool = "capability"` | Any provider of capability | `requires_tool = "fire_source"` → any match, lighter, etc. | Interchangeable tools; flexibility |

**Design Rule:** Use `requires = "item-id"` for unique items (specific key fits specific lock). Use `requires_tool = "capability"` for interchangeable tools (any fire source lights any candle).

---

## See Also

- **Design Directives:** `design-directives.md`
- **Tool Objects Design:** `tool-objects.md`
- **Object Design Patterns:** `object-design-patterns.md`
- **Skill Interaction Matrix:** `design-directives.md#Skill-Interaction-Matrix`
