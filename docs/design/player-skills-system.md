# Player Skills System

**Last updated:** 2026-03-21  
**Audience:** Game Designers  
**Purpose:** Reference for skill mechanics, skill-enabled tool combinations, and learning pathways.

*This section was extracted from `design-directives.md` for better organization.*

---

## Skills Mechanics

**Core Pattern:** Players can learn skills (e.g., lockpicking) through gameplay. A skill unlocks new tool+verb combinations that weren't available before. Skills are learned by finding books, practicing, being taught by NPCs, or other narrative triggers.

**Key Design Insight:** The same tool can have different uses depending on the player's skills. A pin without lockpicking skill = prick yourself to draw blood. A pin WITH lockpicking skill = pick a lock (alternative to using brass key) OR prick yourself.

## Skill-Enabled Tool Combinations

| Skill | Tool | Normal Use | Skill-Enabled Use | Replaces |
|-------|------|-----------|-------------------|----------|
| **Lockpicking** | Pin | Prick self (injury_source) | Pick lock on door | Brass key (one-time use) |
| **Weaponry** | Knife | Cut paper (writing tool) | Combat attack | (N/A for V1) |

**Design Rule:** Skills unlock alternative verb→tool combinations, creating emergent puzzle solutions and replay value. A skill doesn't replace the base use; it adds new capabilities.

## Learning Skills

| Method | Example | Design Note |
|--------|---------|-------------|
| **Find a book** | "Lockpicking Manual" in library | Player reads book → learns skill |
| **Practice** | Use lockpicking multiple times → proficiency | Skill grows through repetition |
| **NPC Teaching** | NPC mentor teaches skill | Narrative trigger; relationship-based |
| **Puzzle Solution** | Solve puzzle with tool → unlock related skill | Emergent learning |

---

## See Also

- **Design Directives:** `design-directives.md`
- **Tools System:** `tools-system.md`
- **Skill Interaction Matrix:** `design-directives.md#Skill-Interaction-Matrix`
- **Compound Tools:** `design-directives.md#Compound-Tools`
- **Writing & Paper System:** `writing-paper-system.md`
