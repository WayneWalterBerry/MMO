# Injury Reference Documentation

This directory contains **reference documentation** for each injury type in the game. Each file documents the technical specifications of an injury: FSM states, damage patterns, treatment mechanics, and symptom progression.

## Format

Each injury reference file includes:
- **Description** — what the injury is and how it manifests
- **FSM States** — all states and transitions
- **Damage Pattern** — category, severity, health impact, worsening behavior
- **Treatment** — what cures or manages the injury, and wrong treatments
- **Implementation Details** — template file location, states, timers, triggers
- **Body Location** — which body part is affected (if applicable)
- **Interactions** — how the injury affects other game systems

## Injury Index

| Injury | File | Severity | Category | Treatable |
|--------|------|----------|----------|-----------|
| Minor Cut | [minor-cut.md](minor-cut.md) | Low | One-Time | Optional (self-heals) |
| Bleeding | [bleeding.md](bleeding.md) | Medium/High | Over-Time (DoT) | Required |
| Burn | [burn.md](burn.md) | Low/Medium | One-Time | Optional (self-heals) |
| Bruised | [bruised.md](bruised.md) | Low | One-Time | Optional (self-heals with rest) |
| Poisoned by Nightshade | [poisoned-nightshade.md](poisoned-nightshade.md) | High | Over-Time (rapid) | Required |

## Cross-References

- **Gameplay Design:** For puzzle uses, discovery clues, and how injuries function as game mechanics → see `docs/design/injuries/`
- **Technical Architecture:** For how the engine stores, serializes, and updates injuries → see `docs/architecture/player/injuries.md`
- **Implementation:** For .lua source files → see `src/meta/injuries/`
- **Healing Items:** For items that cure or manage injuries → see `docs/design/healing-items.md`

## Reading These Docs

**Choose based on your needs:**
- **"What does this injury do?"** → Read the reference docs here
- **"How does the player experience this injury?"** → Read `docs/design/injuries/`
- **"How is this injury implemented?"** → Read `src/meta/injuries/` (code)
- **"Where should I place this injury in a level?"** → See `docs/design/injuries/` (puzzle integration section)
