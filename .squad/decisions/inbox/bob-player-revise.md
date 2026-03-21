### Decision: Player Design Docs Revised for Derived Health & Injury-Specific Healing
**Date:** 2026-07-24  
**By:** Sideshow Bob (Puzzle Designer)  
**Directive:** copilot-directive-2026-03-21T19-17Z.md  
**Requested by:** Wayne Berry

---

#### What Was Done

Revised all four documents in `docs/design/player/` to align with Wayne's directives:
1. Health is derived from injuries, not a stored/displayed number
2. Healing is injury-specific — each injury has ONE correct cure
3. The `injuries` verb is the player's health interface
4. Nested inventory creates container-navigation puzzles under injury pressure

#### Files Changed

| File | Summary of Changes |
|------|-------------------|
| `docs/design/player/README.md` | Rewrote core principles around derived health, injury-matching puzzle, nested containers. Removed HP phases. |
| `docs/design/player/health-system.md` | Removed 100-HP numeric model and HP tiers. Added `injuries` verb design (§2) with full example output. Narrative tied to injury severity, not HP ranges. Added viper bite matching-puzzle scenario. Removed engine integration section (Bart's domain). |
| `docs/design/player/injury-catalog.md` | Added "Cured By" and "Wrong Treatments" to every injury. New injuries: viper venom, nightshade poisoning. Discovery clues for each. New puzzle patterns: Diagnosis Puzzle, Nested Container Emergency. |
| `docs/design/player/healing-items.md` | Eliminated generic HP restoratives. Every item lists exactly which injuries it treats. Added viper antivenom, nightshade antidote. Master Treatment Matching Table (§8). Wrong-treatment failure messages designed. |

#### Design Principles Established

1. **No HP bar, ever.** Health is the aggregate of injuries. The player sees descriptions, not numbers.
2. **`injuries` verb = `inventory` for your body.** First-person physical assessment with embedded treatment clues.
3. **Treatment matching IS the puzzle.** Generic antidote cures food poisoning but NOT viper venom. Bandage stops bleeding but NOT poison. The player must match.
4. **Wrong treatment wastes the item and gives a clue.** "The antidote doesn't help the burning in your leg. This wasn't made for viper venom."
5. **Death hints teach the matching puzzle.** "The gash needed a bandage — tight cloth wrapped around the wound."
6. **Specificity increases with game progression.** Level 1: bandage + rest. Level 2: targeted antidotes. Level 3: precise poison-identification puzzles.

#### Impacts on Other Team Members

| Who | What Changes for Them |
|-----|-----------------------|
| **Bart** (Architect) | Engine design for player.lua: injuries as nested data, derived health computation, `injuries` verb handler. Previous engine integration notes removed from design docs — Bart designs architecture independently. |
| **Flanders** (Object Designer) | Healing objects now declare `treats` (specific injury list) instead of `heals` (HP amount). Each object needs `wrong_treatment_message` for when used on the wrong injury. |
| **CBG** (Game Designer) | The injury-matching puzzle is now a core gameplay loop, not a side system. Pacing and difficulty ramp through treatment specificity. |
| **Nelson** (Tester) | Test matrix: every injury × every healing item = correct match or failure. Verify wrong-treatment messages. Test `injuries` verb output at each severity. |

#### Open Items

- [ ] Bart to design engine architecture for derived health and injury FSMs in player.lua
- [ ] Flanders to update healing object specs with `treats` field and wrong-treatment messages
- [ ] CBG to align game pacing with treatment-specificity progression
- [ ] Nelson to build injury×treatment test matrix
