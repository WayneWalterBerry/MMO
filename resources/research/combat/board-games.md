# Board Game Combat — Research Report

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** Combat resolution in tabletop board games — systems designed to be elegant without computers. Focus on what translates to text-based interactive fiction.

---

## 1. Gloomhaven — Card-Driven Combat, No Dice

Gloomhaven (2017) replaced dice with a **dual-card system** that makes combat about hand management rather than luck.

### Core Mechanics
- **Two-card play**: each turn, play 2 cards from your hand. Each card has a top half (usually an attack) and a bottom half (usually a movement). You use the top of one card and the bottom of the other — creating a combinatorial decision space every turn.
- **Initiative**: each card has an initiative number. You secretly choose cards, then reveal simultaneously. The lower initiative number goes first. But powerful cards tend to have high (slow) initiative — there's a tradeoff between power and speed.
- **Attack modifier deck**: instead of dice, attacks draw from a 20-card modifier deck: +0, +1, -1, +2, -2, ×0 (miss), ×2 (critical). This creates bounded randomness — you know the distribution, and the deck thins as cards are drawn, making probability trackable.
- **Card exhaustion**: using a card's powerful "loss" ability removes it from the game permanently. Your hand shrinks over time — combat has a natural clock. Run out of cards = exhaustion = elimination.
- **No healing surplus**: you can never exceed your starting HP. Damage is a ratchet that tightens over the scenario.

### What Makes It Elegant
- **Every turn is a genuine decision.** Which cards? Which tops/bottoms? Fast or powerful? The combinatorial space means no two turns feel identical.
- **Bounded randomness**: the modifier deck feels fairer than dice because streaks are self-correcting (drawing ×0 means the deck now has more positives).
- **The exhaustion clock** creates natural pacing. Players can't turtle — they MUST progress or run out of cards.

### Translation to Text IF
- The concept of **limited combat resources that deplete over the fight** translates directly. In our game: weapon durability, stamina, light sources.
- Card selection maps to **verb selection**: each turn, the player chooses one action. The interesting part is that some actions have costs (using a match to light an oil flask costs a match and a flask).
- The modifier deck concept could inform damage variance without pure RNG: a "condition deck" where previous outcomes affect future probabilities.

---

## 2. Descent / Imperial Assault — Dice Pools and Defense Dice

Fantasy Flight's dungeon crawlers use **custom dice** with symbols instead of numbers, creating a language of combat outcomes.

### Core Mechanics
- **Attack dice**: roll colored dice based on weapon type. Blue dice (ranged) show range + damage. Red dice (melee) show high damage. Yellow dice show surges (special abilities). Each die face shows: damage hearts, range pips, surge lightning, and sometimes misses (X).
- **Defense dice**: the defender rolls gray/black/brown dice showing shield symbols. Each shield cancels one damage heart. The interaction is: attacker's hearts minus defender's shields = damage dealt.
- **Surge abilities**: weapon cards list "surge: +2 damage" or "surge: pierce 2" or "surge: stun." Rolling surge symbols lets you activate these — creating per-attack tactical choices about which surge abilities to spend.
- **Line of sight**: Descent uses physical line of sight (can you draw an unobstructed line between attacker and target?). Simple but creates meaningful positioning.

### What Makes It Elegant
- **Custom dice compress multiple decisions into one roll.** A single roll produces accuracy, damage, range, and special effects simultaneously.
- **The surge system** means even a weak attack roll can be tactically interesting — do I spend my one surge on extra damage or on stunning the enemy?
- **Defense dice give the defender agency.** Being attacked isn't passive — you're rolling too, which keeps all players engaged.

### Translation to Text IF
- The concept of **attack and defense as simultaneous resolution** is very text-friendly: "You slash at the rat with your dagger (2 piercing) — it twists aside, its hide absorbing 1 point (1 damage dealt)."
- Surge-like mechanics could be "critical effects" triggered by weapon quality or material properties: a steel blade might "pierce" armor on a good hit, while an obsidian blade might "shatter" on a bad one.
- Defense as an active check (not just passive AC) means armor quality matters every hit, creating equipment decisions.

---

## 3. Mage Knight — Deterministic Card Management

Mage Knight (2011) is a heavy strategy game where combat is almost entirely **deterministic** — you know before committing whether you can win.

### Core Mechanics
- **Card-based everything**: movement, combat, defense, healing — all from the same hand of cards. Playing a card for combat means NOT using it for movement or defense later. Pure resource allocation.
- **Attack = play cards totaling ≥ enemy armor; then play cards totaling ≥ enemy HP.** Two separate thresholds. A heavily armored enemy with low HP (golem) plays differently from a lightly armored enemy with high HP (dragon).
- **Ranged vs. melee**: ranged attacks happen first. If you can kill an enemy at range, it never hits you. Otherwise, the enemy deals its full attack damage, THEN you melee.
- **Block = play cards totaling ≥ enemy attack.** If you can't fully block, you take FULL damage (no partial blocking). This creates knife-edge decisions: can I exactly block 7 with my remaining cards?
- **Damage types**: physical, fire, ice, force. Enemies have resistances. Physical resistance means you need double the card value to overcome armor. Fire resistance means fire attacks deal zero.

### What Makes It Elegant
- **Perfect information combat.** You know enemy stats, you know your hand, you can calculate exactly whether you can win. The decision is: is this fight WORTH the cards I'll spend?
- **The armor/HP split** creates interesting enemy design variety with just two numbers.
- **No partial blocking** forces commitment: either invest heavily in defense or accept the full hit. No wimpy half-measures.

### Translation to Text IF
- The **two-threshold model** (penetrate armor, then deal damage) maps perfectly to material-based combat: weapon material vs. armor material determines penetration, then remaining force determines wound severity.
- **Deterministic combat with known outcomes** is achievable in text IF using our material system: the player can reason "my steel dagger will penetrate leather but not iron chain."
- **Ranged-before-melee priority** creates a natural text IF tactic: throw things first, then close to melee. This gives thrown objects (rocks, flasks) tactical value.

---

## 4. Kingdom Death: Monster — Hit Locations and Wound System

Kingdom Death: Monster (2015) has the most detailed wound system in board gaming, directly relevant to our DF-inspired combat.

### Core Mechanics
- **Hit location deck**: each monster has a custom deck of hit location cards (~12-20 cards). When you attack, draw a card — it shows WHERE you hit (head, body, legs, tail, wings) and what happens.
- **Critical wounds**: some hit locations have a "critical wound" threshold. Deal enough damage in one hit to that location → trigger a critical effect (sever limb, puncture organ, blind an eye). Critical effects permanently weaken the monster for the rest of the fight AND provide rare crafting materials.
- **Monster AI deck**: the monster acts by drawing from its own AI deck. Each card specifies: target priority (closest? weakest?), movement, attack type, and hit location on survivors. "Claw Attack: target closest survivor, 3 damage to arms."
- **Survivor wound system**: survivors also have hit locations (head, body, arms, waist, legs). Each location has armor from equipped gear. Damage exceeding armor causes a wound. Wounds to specific locations have specific effects: head wound = knocked down; arm wound = drop weapon; leg wound = can't move.
- **Trap cards**: some hit location cards are "traps" — hitting the monster's armored plate or triggering a reflexive counterattack. This creates tension in every attack: you WANT to hit the soft belly, but you might hit the armored crest.

### What Makes It Elegant
- **The hit location deck makes every attack a narrative moment.** Drawing a card and reading "You strike the beast's wounded flank — it howls and swipes at you reflexively" creates drama that simple HP subtraction never achieves.
- **Persistent monster damage** (critical wounds) gives fights an arc: early hits probe for weak spots, critical wounds create openings, the finale targets those openings.
- **Attacker risk**: trap cards mean attacking is never purely positive. Every swing is a gamble, even if the odds favor you.

### Translation to Text IF
- **Hit location as narrative driver** is PERFECT for text IF. Instead of "you deal 3 damage," it's "your dagger finds a gap in the rat's hide, slicing its flank." Hit location determines the combat description.
- **Critical wound thresholds** translate to our injury system: enough damage to a body part triggers an injury type (laceration, fracture, puncture). The injury's effects are determined by the injury definition, not hardcoded combat logic (Principle 8).
- **Monster AI as metadata** aligns with Principle 8: creature objects declare their combat behavior (target priority, attack patterns, hit locations) — the engine executes it.
- **Trap/counterattack** mechanics give defensive creatures personality: a porcupine's "hit location deck" includes "quills — attacker takes 1 piercing damage."

---

## 5. Arkham Horror LCG — Skill Tests and the Chaos Bag

Arkham Horror: The Card Game (2016) uses a **chaos bag** instead of dice — a physical bag of tokens that creates bounded, customizable randomness.

### Core Mechanics
- **Skill test**: declare action → commit skill cards (spending resources for bonus) → draw 1 token from chaos bag → add token modifier to skill value → compare to difficulty. Success if skill ≥ difficulty.
- **Chaos bag contents**: a mix of tokens from +1 to -8, plus special tokens (skull, cultist, tablet, elder thing, auto-fail, auto-success). The bag is customized per scenario and difficulty level. Easy mode has mild negatives; Hard mode has brutal ones.
- **Committed cards are spent**: boosting a skill check costs cards from your hand. Every test is a resource decision: how much do I invest in success?
- **Failure is not binary**: many cards have "if you fail by 2 or less" effects. Failure has degrees, and skilled characters fail more gracefully.

### What Makes It Elegant
- **The chaos bag is tunable randomness.** Unlike dice, the contents are fully customizable. A horror scenario can add more negative tokens as doom approaches — the system literally gets harder as tension rises.
- **Committed cards as investment** means skill tests feel meaningful even when you succeed — you spent something to get there.
- **Graduated failure** prevents the "whiff feel" — even failing, something usually happens.

### Translation to Text IF
- **Tunable randomness** could manifest as environmental conditions affecting combat outcomes: fighting in darkness adds "penalty" to the metaphorical bag; fighting near a light source removes penalties.
- **Graduated outcomes** instead of binary hit/miss: "You swing at the rat — your blade grazes its side, a shallow cut (1 damage instead of 3)." Partial success is far more narratively interesting than "you miss."
- **Resource commitment** before resolution: "Do you lunge aggressively (higher damage, but you'll be off-balance) or strike cautiously (lower damage, maintain guard)?" The player commits before knowing the outcome.

---

## 6. Cross-Cutting Patterns for Text IF

### What All These Games Share

1. **Bounded randomness or determinism**: no game uses pure unbounded dice rolls. All constrain variance through modifier decks (Gloomhaven), custom dice (Descent), calculated certainty (Mage Knight), curated bags (Arkham), or elimination (Kingdom Death).

2. **Attack-defense interaction**: combat is never just "roll to hit." The defender's properties always matter — armor in Mage Knight, defense dice in Descent, hit locations in Kingdom Death.

3. **Resource depletion as timer**: Gloomhaven's card exhaustion, Mage Knight's hand management, Arkham's committed cards. Combat can't last forever because resources run out.

4. **Every attack tells a micro-story**: hit locations, surge abilities, chaos tokens, trap cards. The resolution mechanic generates narrative, not just numbers.

### What Translates Best to Text IF

- **Deterministic material interaction** (Mage Knight model): steel beats leather, wood burns, glass shatters. The player reasons about physical reality, not abstract stats.
- **Hit location narrative** (Kingdom Death): every attack hit produces a different text description based on where and how it landed.
- **Graduated outcomes** (Arkham Horror): miss / graze / hit / critical instead of binary miss/hit. Four outcomes = four narrative descriptions per attack.
- **Exhaustion clock** (Gloomhaven): weapon durability, stamina, light sources. Combat must end before resources do.
- **Defender-matters** (Descent): armor quality, creature anatomy, defensive posture all affect the outcome. Getting good armor is as strategic as getting a good weapon.
