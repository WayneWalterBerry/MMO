# MUD Combat Systems — Research Report

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** Combat mechanics in classic and modern MUDs — text-based multiplayer games that pioneered real-time and turn-based combat in pure text environments.

---

## 1. DikuMUD (1991) — The Grandfather

DikuMUD established the foundational combat loop that dominated online games for two decades. Its core mechanic is **auto-attack**: once combat begins, both combatants exchange melee blows every combat round (~2 seconds) without further player input.

### Key Mechanics
- **THAC0/AC system** borrowed from AD&D: attacker rolls d20, compares to target's Armor Class. Lower AC = harder to hit.
- **Combat rounds** are server-timed (typically 2-4 seconds). Each round: check initiative order → process attacks → apply damage → check death.
- **Hitroll and Damroll** are separate stats: hitroll modifies accuracy, damroll modifies damage output. This split means a character can be accurate-but-weak or inaccurate-but-devastating.
- **Flee mechanic**: player types `flee` → random chance based on DEX to escape. On failure, you lose your attack that round. On success, you move to a random adjacent room. This creates a real tension — fleeing is unreliable and choosing WHEN to flee is a genuine decision.
- **Spell casting** interrupts auto-attack: typing `cast 'magic missile' goblin` queues the spell for next round, replacing your melee attack. Spells have casting time (measured in rounds), and taking damage can interrupt a spell mid-cast.
- **Multiple combatants**: DikuMUD uses a simple aggro list. Each mob tracks who has dealt the most damage — it attacks that target. The `rescue` command lets a tank redirect a mob's aggro to themselves.

### What Works for Text IF
- The verb-driven command interface (`kill`, `flee`, `cast`, `rescue`) maps directly to text IF parser conventions.
- The round-based timing creates natural text output pacing — one paragraph of combat narration per round.

### What Doesn't Work
- Auto-attack removes player agency between rounds. In a single-player text game, idle combat feels wrong.
- Server-timed rounds don't translate to turn-based play.

---

## 2. LPMud — Flexible, Verb-Based Combat

LPMud's architecture was fundamentally different from DikuMUD: instead of hardcoded combat routines, LPMud exposed combat as **overridable methods** on objects. The MudOS/FluffOS drivers allowed builders to define custom `hit()`, `defend()`, and `attack()` functions on any object.

### Key Innovations
- **Weapon objects define their own combat behavior.** A sword's `hit()` function might check the wielder's STR, while a wand's `hit()` checks INT. The engine doesn't dictate — the object does. (This is remarkably close to our Principle 8: engine executes metadata.)
- **Defense is also object-driven.** Armor has a `defend()` function that reduces incoming damage. A shield might have a `block()` that negates attacks entirely on a skill check.
- **Verb-based commands**: players can use context-specific combat verbs beyond `kill`. A staff might enable `sweep` (area attack), while a dagger enables `backstab` (high damage from stealth).
- **Combat hooks**: LPMud's `heart_beat()` function (called every 2 seconds on every "living" object) drives combat rounds. Any object with a heartbeat can participate in combat — including animated furniture, golems, or even rooms.

### Relevance to Our Engine
- Object-defined combat behavior aligns perfectly with Principle 8 (objects declare behavior, engine executes).
- The idea that a weapon object carries its own `hit()` / `defend()` logic maps to our mutation and FSM systems — a weapon's state determines its combat capabilities.

---

## 3. DikuMUD Derivatives — ROM, SMAUG, CircleMUD

These codebases evolved DikuMUD's combat in specific directions:

### ROM (Rivers of MUD)
- Added **dual wield** (attack with both hands per round) — directly relevant to our 2-hand inventory system.
- Introduced **damage types** (slash, pierce, bash, fire, cold, etc.) with per-creature vulnerabilities and immunities. A skeleton takes half damage from pierce but double from bash.
- **Skill-based combat**: instead of class-defined abilities, ROM uses a skill percentage system. Your `sword` skill starts at 1% and increases through use. Each combat round, your skill is checked — you can miss even with a high-quality weapon if your skill is low.

### SMAUG
- Added **body parts and hit locations**. Attacks target specific body parts (head, torso, arms, legs). Armor protects specific locations. A helmet protects your head but not your legs.
- **Damage to body parts** causes specific debuffs: damaged legs reduce flee chance, damaged arms reduce attack accuracy.
- **Weapon proficiencies** are separate from general combat skill — you might be good with swords but terrible with axes.

### CircleMUD
- Kept DikuMUD's simplicity but added **position-based modifiers**: sleeping targets take 2x damage, sitting targets take 1.5x. A stunned target cannot flee.
- **Memory system for mobs**: if you flee and return, the mob remembers you and attacks immediately. Mob AI includes "hunt" behavior — aggressive mobs track fleeing players across rooms.

### Synthesis for Our Game
- ROM's damage types + SMAUG's hit locations = a rich material-aware combat system. Our existing material system (17+ materials) could determine damage types naturally.
- The 2-hand system from ROM's dual wield is already in our engine — weapon choice is inventory-constrained.
- CircleMUD's position modifiers translate well to our FSM states (a player who is "prone" or "stunned" has different combat capabilities).

---

## 4. Achaea/IRE MUDs — Modern Commercial Combat

Iron Realms Entertainment (IRE) MUDs represent the pinnacle of text-based combat sophistication. Achaea (1997–present) has been continuously refined for 28+ years.

### Combat Architecture
- **Affliction system**: combat revolves around applying and curing "afflictions" (paralysis, blindness, prone, broken limbs — over 100 distinct conditions). Each class has tools to apply specific afflictions; the "kill combo" requires stacking the right afflictions in the right order.
- **Curing priority**: players configure automatic curing queues — which affliction to cure first when multiple are active. Good curing config is as important as good offense. This creates a metagame of "do I cure paralysis first, or blindness?"
- **Balance/Equilibrium**: instead of round-based, Achaea uses two timers: **balance** (physical recovery, ~2-3 seconds) and **equilibrium** (mental recovery, ~3-4 seconds). Actions consume one or both. This creates natural pacing without explicit rounds.
- **Limb damage**: arms and legs have hidden HP pools. Enough limb damage causes "broken" state, which disables abilities and enables "instakill" finishers (e.g., Monk's `thwack` requires both legs broken).

### PvP Depth
- Achaea's PvP is deep enough that tournaments draw hundreds of spectators. The system proves text-based combat can be tactically rich and competitively engaging.
- **Group combat** uses "focus fire" coordination — tank/healer/DPS roles emerge naturally from the affliction/curing mechanics.

### Relevance
- The affliction/curing model maps to our injury system (7 injury types already defined). Injuries as "afflictions" that degrade capability until treated.
- Balance/equilibrium is elegant for text IF — it paces combat without real-time pressure. A turn-based version: "you can attack OR use an ability, not both."

---

## 5. Discworld MUD — Skill-Based Combat

The Discworld MUD (1991–present) uses a classless, skill-based system where combat ability comes entirely from trained skills.

### Key Mechanics
- **400+ skills** in a tree hierarchy. Combat skills include `fighting.melee.sword`, `fighting.melee.dagger`, `fighting.range.bow`, `fighting.defense.dodging`, `fighting.defense.blocking`.
- **Skill checks** are percentile: your skill level vs. difficulty produces a success chance. A character with `fighting.melee.sword` at 200 vs. a difficulty of 150 has roughly 75% hit rate.
- **Tactics command**: players set combat stance (offensive/neutral/defensive) and targeting (head/torso/legs). This replaces per-round commands with a strategic posture system.
- **Special attacks** unlock at skill thresholds — at sword skill 150, you learn `riposte`; at 250, `feint`. This provides character progression without class restrictions.

### What's Interesting
- The tactics/posture system is very text-IF friendly: instead of frantic per-round commands, the player sets a strategy and watches it play out. Intervention is optional but rewarding.
- The skill tree is too granular for our game (400+ skills), but the concept of "weapon familiarity improves with use" could inform a simpler proficiency system.

---

## 6. Cross-Cutting Patterns in MUD Combat

### Turn Order
All MUDs use some form of initiative: DikuMUD uses DEX-based ordering within a round; Achaea uses balance/equilibrium timers; Discworld uses skill-based reaction time.

### Damage Output
Universal pattern: **accuracy check → damage roll → defense reduction → apply**. Variations exist in where randomness enters (DikuMUD: accuracy + damage; Discworld: accuracy only; Achaea: deterministic damage).

### Flee Mechanics
Every MUD makes fleeing unreliable and costly. This is critical — flee must be a genuine risk/reward decision, not a free escape. Common costs: lose your attack round, random exit direction, aggro memory.

### Multiple Combatants
MUDs handle N-vs-M combat through aggro targeting: each combatant has a primary target. Group tactics emerge from target manipulation (`rescue`, `taunt`, focus fire). NPC-vs-NPC is handled identically — the same combat system processes mob-vs-mob fights.

### NPC-vs-NPC
In MUDs with mob AI (ROM, SMAUG), NPCs fight each other using the same combat system as players. Guards attack criminals; wolves hunt deer; rival factions clash. The engine doesn't distinguish player-vs-NPC from NPC-vs-NPC — all combatants are "living" objects with the same interface. This is exactly the design pattern we should follow.

---

## Key Takeaways for Our Engine

1. **Object-driven combat** (LPMud) aligns with Principle 8. Weapons and armor should declare their combat behavior; the engine executes it.
2. **Material-aware damage types** (ROM) fit our existing material system. A steel sword vs. a wooden shield should behave differently than vs. iron armor.
3. **Hit locations** (SMAUG) combined with our injury system creates a natural DF-inspired wound model.
4. **Balance/equilibrium pacing** (Achaea) solves turn order elegantly for text IF — no real-time pressure, but natural cadence.
5. **Flee as a risky decision** is universal and essential. Fleeing should cost something and can fail.
6. **Unified combatant interface** for player-vs-NPC and NPC-vs-NPC — the engine should not distinguish between them.
