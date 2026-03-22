# Daily Plan — 2026-03-23

**Owner:** Wayne "Effe" Berry
**Focus:** Injury system expansion (unconsciousness), hang elimination completion, deploy

---

## Carry-Over from 2026-03-22

### Hang Elimination Sprint (must complete before deploy)
- [ ] Bart: trace logging + RCA on remaining 5 hangs (BUG-105/106/116/117/118)
- [ ] Smithers: implement Bart's fix + global safety net timeout
- [ ] Nelson: Pass 035 hang hunting results → file new Issues
- [ ] Marge: verify all hang fixes in live play, close GitHub Issues
- [ ] Deploy once Marge gives go/no-go

### Open GitHub Issues (WayneWalterBerry/MMO)
- [ ] Review all 11 open Issues, close any that were fixed yesterday
- [ ] Triage any new Issues from Nelson's hang hunting

---

## New Feature: Unconsciousness Injury System

**Wayne's design:** Expand the injury system to include injuries that cause unconsciousness — like a blow to the head. These are fundamentally different from bleeding/health-drain injuries.

### Design Principles

1. **Unconsciousness = temporary forced sleep.** Player can't act for N turns.
2. **Duration-based.** Each unconscious injury has a wake-up timer (e.g., "blow to the head" = 5-10 turns).
3. **Injury ticking continues while unconscious.** If you have a bleeding wound AND go unconscious, the bleeding ticks every turn. You can bleed out and die before waking up.
4. **Sleep + injuries = same risk.** If you go to sleep voluntarily with active bleeding injuries, you can bleed out and die during sleep. Sleep doesn't pause injury ticking.
5. **Wake-up narration.** When the timer expires: "You groan and open your eyes. Your head throbs. [time] has passed."
6. **Death during unconsciousness.** If health reaches 0 while unconscious: "You never wake up. The bleeding was too much."

### Injury Categories (after expansion)

| Category | Example | Mechanic | Ticks During Sleep/Unconscious? |
|----------|---------|----------|-------------------------------|
| **Bleeding** | Stab wound, cut | Loses health every turn | ✅ Yes — can bleed out |
| **Pain** | Bruise, sprain | Affects actions (slower, weaker) | No — dormant during sleep |
| **Unconsciousness** | Blow to head, knockout | Forced sleep for N turns | N/A — IS the sleep state |
| **Poison** | Nightshade | Ticks health + special effects | ✅ Yes — can die |

### Implementation Tasks

#### Phase 1: Design Docs (CBG + design team)
- [ ] `docs/design/injuries/unconsciousness.md` — Full design doc:
  - Unconsciousness FSM states: conscious → unconscious → waking → conscious
  - Duration mechanics: fixed vs random (e.g., 5-10 turns for head blow)
  - Interaction with existing injury ticking (bleeding continues during unconsciousness)
  - Interaction with voluntary sleep (same risk — injuries tick during sleep too)
  - Death conditions: health ≤ 0 while unconscious = permanent death
  - Wake-up narration templates (vary by cause)
  - What triggers unconsciousness? (blow to head, poison, gas, magic?)
- [ ] Update `docs/design/injuries/` index if one exists — add unconsciousness to injury category list
- [ ] `git commit && git push`

#### Phase 2: Architecture Docs (Bart)
- [ ] `docs/architecture/player/` — Update player model architecture:
  - Player consciousness state (conscious/unconscious/sleeping)
  - How the game loop handles forced-sleep (skip input, tick injuries, check death, decrement timer)
  - Interaction between sleep command and injury ticking (voluntary sleep now dangerous)
  - Death-during-unconsciousness handler architecture
  - Wake-up event and narration dispatch
- [ ] Review engine implications — does `src/engine/loop/init.lua` need a state machine for player consciousness?
- [ ] `git commit && git push`

#### Phase 3: Engine Implementation (Smithers + Bart)
- [ ] Implement unconsciousness state in the player model
- [ ] Game loop: if player is unconscious, skip command input, tick injuries, check death, decrement wake timer
- [ ] Integrate with existing sleep command — sleep now also ticks injuries
- [ ] Death-during-unconsciousness handler: special narration
- [ ] Wake-up handler: narration + time advancement
- [ ] **`hit` verb:** Allow players to hit themselves (like `stab` for self-infliction testing):
  - `hit head` → unconsciousness injury (severity-based duration)
  - `hit arm` / `hit leg` → bruise injury (pain category, affects actions)
  - `hit` with no target → "Hit what?" (Prime Directive friendly)
  - This is the primary way to TEST unconsciousness — player can trigger it on themselves
- [ ] Armor interaction: if wearing a helmet, `hit head` reduces or prevents unconsciousness
- [ ] **TEST GATE:** Write unit tests for all states/transitions including:
  - hit head → unconscious → injuries tick → wake up
  - hit head → unconscious → bleed out → die (if also stabbed)
  - sleep with injuries → bleed out → die
  - hit head with helmet → reduced/no unconsciousness
  - hit arm → bruise (pain, not unconsciousness)
- [ ] `git commit && git push`

### 🧪 Nelson Sanity Check
- [ ] Nelson tests: get injured → go unconscious → wake up (or die)
- [ ] Nelson tests: get injured → sleep voluntarily → bleed out
- [ ] Nelson tests: get injured → get knocked out → bleed out while unconscious
- [ ] Write results + file Issues for any bugs

#### Phase 3: Objects (Flanders)
- [ ] Create injury-causing objects that trigger unconsciousness
  - Falling rock trap? Ceiling collapse?
  - Enemy blow (combat precursor)?
  - Poison gas (cellar area)?
- [ ] Design narration for each unconsciousness trigger
- [ ] `git commit && git push`

---

## Process Rules (same as 2026-03-22)

1. Nelson play-tests between every phase
2. Commit+push between every step
3. Keep this plan updated — mark items [x] as they complete
4. All tests must pass before advancing
5. Bugs tracked in GitHub Issues (WayneWalterBerry/MMO)
6. Engineers don't close Issues — Marge verifies and closes
7. Hang bugs require RCA before closure

---

## Design Decisions (answered 2026-03-22)

1. **Duration:** Severity-based — harder hit = longer unconscious. Each injury source defines a severity that maps to turn count.
2. **Early wake-up:** Single player for now — you always wait out the timer. Design the hook for future multiplayer but don't implement NPC wake-up yet.
3. **Dazed state:** No — binary conscious/unconscious, clean transition. No intermediate state.
4. **Armor protection:** Yes — helmets/armor reduce unconsciousness duration or prevent it entirely for weak blows. Design the `reduces_unconsciousness` property on wearable objects.
