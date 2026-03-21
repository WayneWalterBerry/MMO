# Injury Design

This folder documents the **gameplay design** of injury types: how they function as puzzles, their discovery mechanisms, treatment matching, puzzle integration, and narrative moments. These are the design documents that precede implementation.

⚠️ **For technical reference** (FSM states, damage values, treatment items, symptom text) → see `docs/injuries/`

## What Is an Injury?

An injury is a modifier that affects the player's state for a duration. Injuries follow the same architectural pattern as objects:

- **Base Types (Templates):** Defined in `src/meta/injuries/` as individual .lua files
- **Instances:** The player holds individual injury instances with per-instance state (duration, severity, etc.)
- **Identity:** Each injury type has a Windows GUID (consistent with the metadata identity system)
- **Loading:** Injury metadata is JIT-loaded on demand, just like object metadata

## Design vs. Reference Documentation

**This folder (design):** Gameplay design, puzzle uses, discovery paths, treatment mechanics as puzzles, narrative integration, design rationale

**`docs/injuries/` (reference):** Technical specifications, FSM state diagrams, damage calculations, treatment items, symptom text, implementation details

The design documents in this folder are comprehensive — they include technical details too — but they're focused on **how the injury plays as a game mechanic**. For a quick reference lookup (just the facts), see the reference docs.

## Design Workflow

1. **Design phase:** Create a `.md` file in this folder describing the injury concept, puzzle uses, and integration
2. **Implementation phase:** Flanders converts the design into a `.lua` template in `src/meta/injuries/`
3. **Reference docs:** Extract the technical content into a reference doc in `docs/injuries/`
4. **Live:** The injury is ready for puzzle mechanics, gameplay, and discovery

## Injury Design Template

Each injury design document should include:

- **Name** — Human-readable injury name (e.g., "Bleeding", "Poisoned by Nightshade")
- **Cause** — How the player gets this injury (what interaction or combat situation causes it?)
- **Symptoms** — What does the player experience? Sensory descriptions (pain, dizziness, numbness, etc.)
- **FSM States** — State machine describing the injury progression
  - Example: `uninfected → bleeding → clotted → healed`
  - Each state includes severity level, sensory feedback, and capability restrictions
- **Treatment Items** — What cures or reduces this injury? (bandages, antidotes, rest, etc.)
- **Damage Pattern** — How does the injury unfold?
  - **One-time:** Effect happens once when applied (e.g., "-5 health")
  - **Over-time (DoT):** Damage accumulates per turn (e.g., "-1 health per turn")
  - **Degenerative:** Damage worsens if untreated (e.g., bleeding gets worse without bandage)
- **Puzzle Uses** — How can this injury be used as a puzzle mechanic?
  - Time pressure: injury worsens if not treated (bleeding out during puzzle)
  - Capability gate: injury prevents certain actions (too hurt to climb)
  - Treatment matching: player must find the right cure for the poison
  - Discovery: getting hurt teaches player about the world ("I learned the river has leeches")
- **GUID** — Windows GUID assigned to this injury type (assigned during implementation)

## Cross-References

- **Reference Documentation:** `docs/injuries/` — FSM diagrams, damage values, treatment items, symptom text (the facts)
- **Technical Architecture:** `docs/architecture/player/injuries.md` — How injuries are stored, serialized, and updated in the player object
- **Implementation:** `src/meta/injuries/` — All injury type .lua files
- **Object Design:** `docs/design/objects/` — Objects follow the same template→instance pattern; study object designs for parallel structure
- **Healing Items:** `docs/design/healing-items.md` — Items that cure or manage injuries

## Examples

See individual injury design documents in this folder:

### Level 1 Injuries (Designed)
- `minor-cut.md` — One-time, low severity. From glass/sharp edges. Treated with cloth bandage. Self-heals.
- `bleeding.md` — Over-time (DoT). From deep wounds. Treated with cloth bandage (stops drain). Heals naturally once bandaged.
- `poisoned-nightshade.md` — Rapid over-time, lethal. From poison bottle. Requires specific nightshade antidote.
- `burn.md` — One-time. From flame/hot objects. Treated with cold water or cool cloth.
- `bruised.md` — One-time, minor. From falls/impacts. Heals naturally with rest. No treatment item needed.

### Treatment System
- `treatment-targeting.md` — How the parser resolves "apply X to Y" where Y is a specific injury. Context resolution, disambiguation, and example interaction flows.

### Future Injuries
- `fractured-arm.md` *(Level 2+)*
- *(more to come)*

## Design Principles

1. **Realistic grounding:** Injuries should mimic real-world medical effects
2. **Sensory richness:** Describe what the player feels, sees, and hears
3. **Puzzle potential:** Every injury should enable at least one puzzle mechanic
4. **Balanceable:** Injuries should have clear treatment paths and progression
5. **Discoverable:** Players should learn about injuries through gameplay, not menus
