# Magic: The Gathering Combat — Research Report

**Author:** Frink (Research Scientist)
**Date:** 2026-03-25
**Scope:** The combat phase in Magic: The Gathering — the world's most successful combat system, refined over 30 years and 25,000+ unique cards. Focus on what makes creature combat endlessly interesting and applicable to text IF.

---

## 1. Combat Phase Structure

MTG's combat phase is a masterclass in **structured decision points with response windows**. The phase breaks into 5 sub-steps, each with priority passes:

### The Five Steps
1. **Beginning of Combat**: last chance to tap/remove creatures before attacks are declared. Spells and abilities can be used.
2. **Declare Attackers**: active player simultaneously designates which creatures attack and which opponent/planeswalker they target. Tapped creatures and creatures with "summoning sickness" (entered this turn) cannot attack.
3. **Declare Blockers**: defending player assigns blockers. Each blocker is assigned to one attacker. Multiple blockers can gang up on one attacker. Unblocked attackers deal damage to the defending player.
4. **Combat Damage**: damage is assigned and dealt simultaneously (mostly). Attacking player orders blockers on each attacker and assigns lethal damage in order. Damage equals the creature's power stat.
5. **End of Combat**: cleanup effects trigger. "Until end of combat" effects expire.

### Why This Structure Matters
The **response windows between each step** are what make MTG combat rich. After attackers are declared but BEFORE blockers, the defender can cast spells (pump a creature, destroy an attacker, fog all damage). After blockers but BEFORE damage, the attacker can respond (pump their creature, give it trample, remove a blocker). Each window creates a sub-game of bluff and response.

### Translation to Text IF
- The **attack → block → resolve** sequence maps to text combat turns: "The rat lunges at you" (attack declared) → player chooses response (block with shield, dodge, counterattack) → resolution. This creates a natural 3-beat narrative rhythm per exchange.
- **Response windows** in text IF become player choice points: after the enemy commits to an action, the player can react before resolution.

---

## 2. Creature Keywords — Emergent Combat Properties

MTG's keyword abilities are individual mechanics that **combine to create complex interactions**. Each keyword is simple alone but profound in combination.

### Core Combat Keywords

| Keyword | Effect | Interaction Example |
|---------|--------|---------------------|
| **First Strike** | Deals damage before normal creatures | First strike + deathtouch = kills anything before it can fight back |
| **Double Strike** | Deals damage in first strike AND normal phases | Effectively doubles damage; with trample, devastating |
| **Deathtouch** | Any amount of damage kills the target | 1/1 deathtouch blocks and kills a 10/10; with trample, only 1 damage needed for lethal, rest tramples over |
| **Trample** | Excess damage beyond lethal carries through to defender | Trample + deathtouch = assign 1 to each blocker, rest hits player |
| **Flying** | Can only be blocked by flying or reach creatures | Creates aerial combat layer; ground creatures are helpless |
| **Reach** | Can block flying creatures | The anti-flying counter; gives ground creatures utility |
| **Vigilance** | Doesn't tap when attacking | Can attack AND block; removes the attack-defense tradeoff |
| **Lifelink** | Damage dealt also heals the controller | Makes combat math asymmetric — attacker gains resources |
| **Indestructible** | Cannot be destroyed by damage or "destroy" effects | Must be exiled, bounced, or given -X/-X instead |
| **Menace** | Must be blocked by 2+ creatures | Forces defenders to over-commit resources |
| **Hexproof** | Cannot be targeted by opponent's spells | Immune to removal; must be beaten in combat |

### The Interaction Matrix
The genius is that **any creature can have any combination of keywords**, creating exponential interaction space from a linear keyword list. A creature with flying + deathtouch is an aerial assassin. First strike + deathtouch is nearly unkillable in combat. Trample + double strike is a damage cannon. The rules don't change — the same resolution system handles all combinations.

### Translation to Text IF
- **Creature abilities as metadata keywords** aligns perfectly with Principle 8. A rat might have `{fast, small, bite}`. A wolf might have `{pack_tactics, lunge, knockdown}`. The engine resolves combat using the keyword interaction rules.
- The **linear keyword list → exponential interactions** principle means we can start with 5-8 keywords and still get rich combat variety.
- **Counter-keywords** (flying/reach, menace/token swarm) create rock-paper-scissors dynamics that make creature matchups interesting beyond raw stats.

---

## 3. Damage Assignment — Lethal Damage and Toughness

MTG's damage system uses **power/toughness** rather than a simple HP pool, creating nuanced combat math.

### Core Rules
- **Power** = damage dealt. **Toughness** = damage survived. A 3/4 creature deals 3 damage and dies to 4+ damage in a single turn.
- **Lethal damage**: damage ≥ toughness = creature dies (after damage resolves). Damage is marked, not subtracted — a 2/4 that takes 3 damage is still a 2/4 with 3 damage marked, not a 2/1. This matters because toughness-boosting effects can save it.
- **Damage clears at end of turn**: a 2/4 that took 3 damage this turn is a fresh 2/4 next turn. This prevents permanent attrition from chip damage — you must deal lethal in one turn.
- **Multiple blockers**: when multiple creatures block one attacker, the attacking player assigns damage in order. If a 5/5 is blocked by a 2/2 and a 3/3, the attacker assigns 2 to the first (lethal), then 3 to the second (lethal). With only 4 power, the attacker could only kill one.

### What Makes It Interesting
- **Toughness as threshold, not HP** means combat math is about "can I deal enough in one shot?" rather than grinding down a health bar over multiple turns.
- **Damage ordering on multiple blockers** is a genuine tactical decision: do I kill the 1/1 deathtouch creature first, or the 4/4 that will hit me next turn?
- **Damage clearing** means small creatures can't chip away at large ones. This creates strategic relevance for creatures at every size.

### Translation to Text IF
- **Threshold-based lethality** maps to material-based combat: a steel sword exceeds a rat's "toughness threshold" in one hit. A wooden stick might not — requiring multiple hits or a vulnerable target.
- **Damage clearing** might not translate directly (wounds should persist in our DF-inspired system), but the concept of **wound severity thresholds** does: a scratch doesn't impair function, but a deep cut causes bleeding.
- The **multiple-blocker ordering** mechanic translates to multi-target decisions: "Two rats attack. Do you focus on the larger one or dispatch the small one first?"

---

## 4. Combat Tricks — Instants and Activated Abilities

The richest strategic layer in MTG combat is the **interaction during combat** — instants and abilities that modify the fight in progress.

### Common Combat Trick Categories
- **Pump spells**: "+3/+3 until end of turn" — turns a losing block into a winning one. The attacker expected their 4/4 to beat the 2/2, but Giant Growth makes it a 5/5.
- **Removal during combat**: "Destroy target attacking creature" — kills an attacker after it's committed but before damage. The attacker loses the creature without dealing damage.
- **Fog effects**: "Prevent all combat damage this turn" — complete combat negation. The attacker committed resources (tapped creatures) for zero benefit.
- **Flash creatures**: creatures with flash can enter the battlefield during combat, appearing as surprise blockers. "I block your 3/3 with this 4/4 I just played."
- **Activated abilities**: creatures can have abilities usable during combat: "Tap: deal 1 damage to target creature" can finish off a wounded attacker before damage resolves.

### The Bluffing Layer
Combat tricks create a **metagame of bluffing**. When the defending player has untapped mana and cards in hand, the attacker must consider: "Do they have a combat trick? Is it worth the risk?" This turns every combat into a psychological game on top of the mathematical one.

### Translation to Text IF
- **Defensive reactions during combat** are essential for text IF. "The rat lunges — do you (1) block with your shield, (2) dodge and counterattack, (3) throw your flask at it?" These are combat tricks in IF form.
- **Surprise elements**: items in inventory become combat tricks. A flask of oil can be thrown mid-fight. A cloak can be used to entangle. The inventory IS the player's "hand" of combat tricks.
- **The 2-hand inventory system** limits available combat tricks: you can only use what you're holding. Choosing to carry a shield vs. a second weapon vs. a potion is strategic pre-combat deck-building.

---

## 5. Multiplayer Combat — N-Player Mechanics

MTG has evolved sophisticated multiplayer combat rules that handle asymmetric N-player fights.

### Core Multiplayer Rules
- **Attack target choice**: in multiplayer, each attacker is assigned to a specific opponent. You can split attacks across multiple opponents.
- **Only the attacked player blocks**: other players don't interfere in blocks (barring specific card effects). This prevents ganging up on defense.
- **Political combat**: in formats like Commander, attacking creates diplomatic consequences. Attacking the strongest player draws retaliation; attacking the weakest draws censure. Combat becomes a social negotiation.
- **Goad mechanic**: forces a creature to attack someone other than you. Creates forced aggression between other players.
- **Monarch mechanic**: a status token that draws an extra card. The monarch passes to whoever deals combat damage to the current monarch. Creates a constantly-shifting high-value target.

### Translation to Text IF
- For NPC-vs-NPC combat (wolves vs. rats, guard vs. thief), the system needs **target selection logic**: predators target prey, guards target hostiles. MTG's "each attacker chooses a target" model works.
- **Goad-like mechanics** for player influence: throwing a rock at a guard might redirect its aggression toward whatever you hit nearby.
- **Target priority as creature metadata**: predators declare their prey preferences. A cat targets rats before mice. A wolf targets the weakest herd member. This IS creature combat AI, declaratively specified.

---

## 6. Why MTG Combat Stays Interesting After 30 Years

### The Three Pillars

1. **Structured decision points with response windows**: the attack-block-damage sequence gives both players meaningful decisions at every step, with chances to react and counter-react.

2. **Keyword-based emergent complexity**: simple individual mechanics combine into complex interactions. 15 keywords × combinatorial pairing = hundreds of unique creature profiles, all resolved by the same engine.

3. **Resource context**: combat doesn't exist in isolation. Attacking taps your creatures (can't block next turn). Using a combat trick spends mana and cards. Every combat decision has ramifications beyond the current fight.

### The Key Insight for Our Engine
MTG proves that **a small, consistent rule set with declarative creature properties generates infinite variety**. We don't need 50 combat mechanics — we need 8-10 creature keywords, a clean resolution sequence, and the discipline to let interactions emerge from the rules rather than hardcoding specific outcomes. This is Principle 8 applied to combat: creatures declare abilities, the engine resolves interactions.
