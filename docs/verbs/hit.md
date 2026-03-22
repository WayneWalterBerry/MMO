# Hit

> Punch, strike, bash, or hit something with a blunt impact. Self-infliction for testing injury mechanics.

## Synonyms
- `hit` — Hit or punch
- `punch` — Punch (synonym)
- `strike` — Strike (synonym)
- `bash` — Bash (synonym)
- `bonk` — Bonk (synonym)
- `smash` — Smash (synonym)
- `thump` — Thump (synonym)

## Sensory Mode
- **Works in darkness?** ✅ Yes — can inflict by touch
- **Light requirement:** None (for self-infliction)

## Syntax
- `hit [body area]` — Hit yourself on body area
- `hit [body area] with [object]` — Hit with blunt weapon/object
- `hit self` — Hit yourself, random body area
- `punch head` — Punch your head (synonym)
- `strike arm` — Strike your arm (synonym)

## Behavior
- **Self-only:** Hit is currently only for self-infliction (testing)
- **Body area targeting:** Head, arm, leg, torso (reuses stab's area system)
- **Weapon optional:** Bare fists by default; blunt objects increase severity
- **Injury system:** Inflicts injury via injury module
- **Head hits:** Causes unconsciousness injury (severity-based duration)
- **Other hits:** Cause bruise injury (pain category, affects actions)
- **Armor protection:** Helmets reduce head hit unconsciousness; other armor reduces bruise severity
- **Message:** Varies by body area and weapon used

## Design Notes
- **Self-harm focus:** Hit is primary self-injury verb for testing unconsciousness (parallels stab for bleeding)
- **No world combat:** Currently no NPC/creature hitting (puzzle-focused)
- **Weapon profiles:** Uses blunt damage profiles only — sharp weapons rejected
- **Body area mechanics:** Different areas produce different injuries (head = unconscious, limbs = bruised)
- **Severity scaling:** Bare fist = base damage; heavy object = increased severity

## Related Verbs
- `stab` — Stabbing attack (similar self-harm pattern for bleeding)
- `cut` — Cutting attack (similar)
- `punch` — Synonym for `hit`

## Injury Results by Body Area

| Body Area | Injury Type | Effect | Armor Protection |
|-----------|------------|--------|------------------|
| **head** | Unconsciousness | Forced sleep for 5-15 turns | Helmet reduces 30-75% |
| **arm** | Bruise (pain) | Affects actions (slower, weaker) | Gloves reduce |
| **leg** | Bruise (pain) | Movement penalty | Leg armor reduces |
| **torso** | Bruise (pain) | Breathing/movement affected | Chest armor reduces |

## Implementation
- **File:** `src/engine/verbs/init.lua` → `handlers["hit"]`, `handlers["punch"]`, etc.
- **Self-infliction:** Body area and weapon resolution utilities
- **Injury system:** Routes to `engine.injuries` module
- **Body area parsing:** Direct object resolution (head, arm, leg, torso)
- **Weapon parsing:** Indirect object after "with" (blunt objects only)
- **Ownership:** Smithers (Engine implementation) — injury mechanics
