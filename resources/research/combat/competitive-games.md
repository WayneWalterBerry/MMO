# Competitive Game Combat — Research Report

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** Combat systems in single-player games acclaimed for tactical depth — roguelikes, tactics games, and CRPGs. Focus on what makes combat FUN and what feels fair vs. frustrating.

---

## 1. Roguelikes — Turn-Based, Tactical, Permadeath

### NetHack (1987–present)

NetHack's combat is deceptively simple on the surface (bump into enemy = attack) but has enormous depth through **emergent item interactions**.

- **Base combat**: move into an enemy to melee attack. Damage = weapon base + STR bonus + enchantment. Defense = AC (base 10, lower is better, armor reduces it).
- **Emergent depth**: the real tactics come from the environment and inventory. Kicking a door has a STR-based chance to break it — fail and you take foot damage. Throwing a potion of paralysis at a monster paralyzes it. Applying a bullwhip to disarm an enemy. Zapping a wand of cold at a pool freezes it — walk across, or wait for it to thaw and drown enemies.
- **Polymorph system**: transform into monsters with their combat abilities. Become a dragon and use breath weapons. This makes combat contextual to your current form.
- **What makes it fun**: the combinatorial explosion of item-environment-enemy interactions. Every fight can potentially be solved multiple ways. The player who discovers "I can use a mirror to reflect Medusa's gaze" feels genuinely clever.
- **What frustrates**: instakill mechanics (touch of death, cockatrice corpse) that feel unfair without spoiler knowledge. The game assumes encyclopedic knowledge of 400+ monster types.

### Dungeon Crawl Stone Soup (DCSS)

DCSS deliberately simplified NetHack's item bloat while preserving tactical combat:

- **Noise system**: loud actions (casting spells, breaking doors) attract enemies from adjacent rooms. Combat is a resource: every fight risks attracting more fights.
- **Autoexplore removes tedium**: the game handles boring movement so every player decision is meaningful. Combat begins when you CHOOSE to engage.
- **Enemy unique abilities**: each monster type has distinct, learnable behavior. Orc priests heal allies. Centaurs kite (retreat while shooting). Sigmund (early unique) has confused targets attack randomly. Players learn enemy patterns through play, not spoilers.
- **What makes it fun**: every fight is a puzzle with known rules. You can see enemy abilities, evaluate your resources, and make informed tactical decisions. Death feels fair because you had the information.
- **What frustrates**: occasional unavoidable bad RNG on early levels (opening a door to 5 ogres on D:3).

### Brogue

Brogue is the minimalist masterpiece — combat with the fewest possible mechanics that still generates deep tactics:

- **Stealth and terrain**: tall grass hides you; deep water slows movement; gas clouds poison; steam clouds obscure vision. Combat is inseparable from terrain.
- **Ally system**: rescued captives fight alongside you with their own AI. You don't control them directly — you influence their behavior through positioning and terrain manipulation.
- **Item identification through use**: you discover what a weapon does by wielding it, creating risk-reward in mid-combat equipment changes.
- **What makes it fun**: every mechanic interacts with every other mechanic. Fire + gas = explosion. Water + electric = conductivity. The combat system is small but the interaction space is huge.

### Roguelike Synthesis
The universal lesson: **combat depth comes from systemic interaction, not complex mechanics.** A small number of well-designed rules that interact freely produces more emergent gameplay than a large number of isolated mechanics. This is critical for text IF — we can't afford UI complexity, so depth must come from interaction.

---

## 2. XCOM (2012, 2016) — Probability and Cover

XCOM's combat innovates through **transparent probability and meaningful positioning**.

### Core Mechanics
- **Hit chance is always visible**: 65% to hit, 15% crit. The player makes informed gambling decisions every turn.
- **Cover system**: half cover (+20 defense), full cover (+40 defense). Flanking ignores cover entirely. This creates a spatial puzzle: how do I get a soldier behind that alien without exposing them?
- **Action economy**: 2 actions per turn. Move + shoot, or dash (double move), or shoot + reload. Limited actions force prioritization.
- **Overwatch**: spend an action to set a reaction shot — fires at the first enemy that moves in sight. Creates area denial without direct attack.

### What Makes It Fun
- **Meaningful decisions every turn.** Move this soldier to flank? Or keep them in cover? Shoot at 45% or move closer for 75% next turn? Every choice has tradeoffs.
- **Escalation**: enemy reinforcements drop in, timers force advancement, environmental destruction removes cover. Staying still is never optimal.

### What Frustrates
- **Streaks of misses at 85%+** feel unfair even though they're statistically expected. XCOM 2 secretly gives the player bonus hit chance after misses (on easier difficulties) because perceived fairness matters more than mathematical fairness.
- **Binary outcomes**: a 90% shot that misses feels worse than a system where partial success exists.

### Relevance to Text IF
- Transparent probability is critical for text: if the player doesn't understand why they missed, combat feels arbitrary. Text output should explain: "You swing the sword at the rat, but it darts aside (your STR 8 vs. its AGI 14)."
- XCOM's lesson about perceived fairness is vital. In text IF, the player can't see the dice — they only see the narrative outcome. Streak protection or partial success prevents frustration.

---

## 3. Darkest Dungeon (2016) — Stress + Position

Darkest Dungeon adds **psychological stress** as a combat resource alongside HP, and uses **party position** as a core tactical axis.

### Core Mechanics
- **Position matters**: 4 heroes in a line, positions 1-4 (front to back). Each ability can only be used FROM certain positions and can only TARGET certain positions. A Crusader in position 1 can use "Smite" (melee, targets 1-2) but can't use "Holy Lance" (requires position 3-4, targets 1-2).
- **Stress system**: certain attacks deal stress instead of (or alongside) HP damage. At 100 stress, heroes crack — gaining a random affliction (paranoid, selfish, fearful, abusive) that overrides player control. At 200 stress, heart attack (instant death).
- **Corpse mechanic**: killed enemies leave corpses in their position, blocking access to enemies behind them. You must either destroy corpses or use abilities that reach past them.
- **Camping**: between combat, the party camps. Heroes can use camping skills to heal stress, buff allies, or prevent night ambushes. This creates a resource management metagame between fights.

### What Makes It Fun
- **The stress system makes combat emotionally engaging.** Watching your healer go paranoid and refuse to heal creates genuine tension that HP alone never achieves.
- **Position manipulation** is a unique tactical verb: shuffling enemies forward exposes their back line; shuffling your party disrupts their formation.

### What Frustrates
- Excessive RNG stacking: bad RNG → stress → affliction → more bad RNG cascades. The feedback loop can feel punishing rather than challenging.

### Relevance
- Stress/morale is directly applicable to our game. DF already models stress in combat — our injury system could include psychological effects (fear, panic, nausea at gore).
- Position is interesting for text IF: "the rat is cornered against the wall" vs. "the rat has a clear escape route" changes available tactics.

---

## 4. Into the Breach (2018) — Deterministic Combat

Into the Breach makes combat a pure puzzle by **eliminating randomness entirely**.

### Core Mechanics
- **No RNG**: every attack hits. Every damage value is fixed. The player sees EXACTLY what will happen next turn — enemy attack targets, damage values, movement.
- **Enemy telegraphing**: at the start of each enemy turn, every enemy action is displayed. The player then has their turn to react — block attacks, push enemies out of position, redirect damage.
- **Grid-based positioning**: combat is a spatial puzzle on an 8x8 grid. Most abilities push or pull units. A laser that does 1 damage but pushes a target into water (instant kill) is better than a cannon that does 3 damage.
- **Sacrificial math**: sometimes the optimal play is to let 1 building take damage to save 3 others. The game constantly asks "what's the least-bad outcome?"

### What Makes It Fun
- **Every death is your fault.** With perfect information, failure means you made a mistake — which means you can learn and improve. No blaming RNG.
- **Emergent combos**: push enemy A into enemy B, canceling B's attack and damaging both. The interaction space between abilities and positions creates elegant tactical moments.

### What Frustrates
- Very little — deterministic systems feel inherently fair. The main criticism is that it can feel more like a puzzle than a fight, lacking the excitement of uncertainty.

### Relevance
- A fully deterministic combat system is possible for text IF and might be the best fit for Phase 1. If the player knows "a steel sword always kills a rat in one hit," the tactical question becomes "HOW do I get close to the rat?" rather than "WILL my swing connect?"
- DF-style material interactions are inherently deterministic: steel cuts flesh. The question is whether to add variance (damage range) or keep it pure.

---

## 5. Baldur's Gate / D&D CRPGs — Initiative and Attack Rolls

The Baldur's Gate series (and the broader D&D CRPG tradition) translates tabletop combat to digital format:

### Core Mechanics
- **Initiative**: at combat start, all participants roll d20 + DEX modifier. This sets turn order for the entire fight (re-rolled each round in some editions).
- **Attack roll**: d20 + attack bonus vs. target's AC. Meet or exceed = hit. Natural 20 = critical hit (double damage). Natural 1 = automatic miss.
- **Saving throws**: when hit by special effects (poison breath, petrification gaze), the target rolls a saving throw to resist or reduce the effect. Different saves for different attack types (Fortitude vs. poison, Reflex vs. area damage, Will vs. mind control).
- **Action economy (5e)**: each turn you get: 1 action (attack, cast, use item), 1 bonus action (off-hand attack, some spells), 1 reaction (opportunity attack, counterspell), and movement. This creates rich per-turn decisions.
- **Concentration**: powerful spells require maintaining concentration — taking damage forces a check, failure ends the spell. This prevents spell stacking and creates counterplay.

### What Makes It Fun
- **The d20 creates drama.** The 5% chance of a critical hit or critical miss adds excitement to every swing. When the halfling rolls a natural 20 against the dragon, the table erupts.
- **Build diversity**: the combination of class, race, feats, and equipment creates thousands of viable combat styles.

### What Frustrates
- **Whiff factor**: missing 3 attacks in a row at level 1 when you can only attack once per round feels awful. Low-level D&D combat can be a coin-flip slog.
- **Complexity creep**: tracking 15 active buffs, 8 conditions, 4 concentration spells, and 6 party members' turn order overwhelms in text format.

### Relevance
- Initiative is needed for our multi-combatant system. A simple DEX-based order (or size-based: rats are fast, elephants are slow) works for text IF.
- Saving throws are elegant for our injury system: "the rat bites your hand — roll against your gauntlet's protection" becomes "the rat bites your hand — your leather glove absorbs most of the damage."
- The whiff factor warning is critical: in text IF, "You miss. The rat misses. You miss. The rat misses." is deadly boring. We need either high hit rates or interesting miss narration.

---

## 6. Universal Patterns — What Makes Combat FUN

### Across All Systems

1. **Meaningful decisions**: every turn should present a genuine choice with tradeoffs. "Do I attack, defend, flee, or use an item?" should never have an obvious always-correct answer.
2. **Transparent rules**: the player must understand WHY they hit or missed. Opaque systems breed frustration. Text IF can explain outcomes inline: "You stab the rat with your rusty dagger (2 piercing vs. 0 armor = 2 damage)."
3. **Systemic interaction**: the best combat systems emerge from simple rules that interact. NetHack's item combos, Brogue's terrain effects, Into the Breach's positional physics. Isolated mechanics feel shallow.
4. **Pacing through escalation**: combat should intensify, not stagnate. Darkest Dungeon's stress accumulates. XCOM's reinforcements arrive. Time pressure prevents turtling.
5. **Fair failure**: death should feel like the player made a mistake, not that the RNG betrayed them. Into the Breach achieves this with determinism. XCOM achieves it with visible probabilities. NetHack fails this with instakills.

### What WON'T Work for Text IF
- **Real-time systems** (action RPGs, timing-based combat). Text inherently requires time to read.
- **Complex spatial positioning** (XCOM grids, Into the Breach boards). Text can convey "near/far/cornered" but not grid coordinates.
- **High-frequency inputs** (fighting game combos, twitch reactions). Text input is slow by nature.
- **Extensive UI state** (15 buff icons, HP bars, cooldown timers). Text combat must communicate state through prose, not dashboards.

### What DOES Work for Text IF
- **Verb-based commands** (MUD tradition): `attack rat`, `throw flask at rat`, `flee north`.
- **Environmental interaction** (Brogue, NetHack): `push barrel at rat`, `light oil on fire`, `slam door on rat's tail`.
- **Resource management** (Darkest Dungeon): limited healing, weapon durability, light sources burning down.
- **Positional narrative** (Darkest Dungeon): "the rat is backed into a corner" gives tactical context without a grid.
- **Material-based determinism** (Into the Breach + DF): steel cuts flesh, wood burns, glass shatters. Physical consistency the player can reason about.
