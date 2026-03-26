# GATE-6 LLM Walkthrough Scenarios

Combat integration scenarios for WAVE-6 validation.
Pipe each file into headless mode:

```bash
Get-Content test\scenarios\gate6\scenario-f-armed-combat.txt | lua src/main.lua --headless
```

## Scenarios

| File | Tests | WAVE-6 Dependency |
|------|-------|-------------------|
| `scenario-f-armed-combat.txt` | Get knife → go to cellar → attack rat with weapon | attack verb + creature combat |
| `scenario-g-flee-combat.txt` | Attack rat → flee from combat | flee verb + combat exit |
| `scenario-h-unarmed-combat.txt` | Go to cellar bare-handed → punch rat | hit/punch creature extension |
| `scenario-i-darkness-combat.txt` | Attack rat without light source | darkness combat rules |

## Pre-WAVE-6 Expected Failures

All scenarios currently FAIL because WAVE-6 features are not yet implemented:
- **"attack rat"** → "You don't see that here to attack" (no attack-creature verb)
- **"flee"** → "You can't go that way" (no flee verb)
- **"punch rat"** → "You can only hit yourself right now" (hit is self-only)
- **Trapdoor** → "won't budge" (game puzzle — separate from combat)

## Pass Criteria (GATE-6)

Each scenario passes when:
1. Player can navigate to the cellar (trapdoor puzzle resolved)
2. Combat verbs trigger resolve_exchange with creatures
3. Combat produces narration text (visual or sound-based)
4. Creature health decreases on hit
5. Dead creatures show dead state description
