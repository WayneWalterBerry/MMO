# Stab

> Stabbing attack or self-infliction with a sharp weapon.

## Synonyms
- `stab` — Stab with a weapon
- `jab` — Jab (synonym)
- `pierce` — Pierce (synonym)
- `stick` — Stick (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can inflict by touch
- **Light requirement:** None

## Syntax
- `stab self with [weapon]` — Stab yourself (self-injury)
- `stab [body area] with [weapon]` — Target body area
- `stab self` — Stab with random body area (auto-selects weapon)

## Behavior
- **Self-only:** Stab is currently only for self-infliction
- **Weapon requirement:** Must have a stabbing weapon (knife, sword, etc.)
- **Body area:** If not specified, randomly selects one (arm, leg, etc.)
- **Injury system:** Inflicts injury via injury module
- **Damage modifier:** Body area affects damage (vital areas deal more)
- **Bleeding state:** Sets player.state.bloody = true, bleeding ticks
- **Message:** Weapon's description text (if has `on_stab` profile)

## Design Notes
- **Self-harm focus:** Stab is primary self-injury verb for testing/puzzle mechanics
- **No world combat:** Currently no NPC/creature stabbing (puzzle-focused)
- **Weapon profiles:** Uses damage profiles (on_stab, on_cut, on_slash)
- **Body area mechanics:** Different areas have different vulnerability

## Related Verbs
- `cut` — Cut with blade (similar self-harm capability)
- `slash` — Slash with weapon (similar)
- `prick` — Prick with sharp point (minor self-injury)

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["stab"]`, `handlers["jab"]`, `handlers["pierce"]`, `handlers["stick"]`
- **Self-infliction:** `handle_self_infliction()` utility
- **Injury system:** Uses `engine.injuries` module
- **Ownership:** Bart (Architect) — injury mechanics
