# MUD Verb Systems: Comprehensive Research

## Overview

MUDs (Multi-User Dungeons) represent one of the oldest and most influential multiplayer text adventure paradigms. Their verb systems are the backbone of player interaction—rich, extensible, and purposefully designed for both mechanical gameplay and social roleplay. This research examines verb patterns across classic MUD architectures and modern derivatives.

**Key Finding:** Classic MUDs typically support **200-300+ distinct verbs**, with modern MUDs (Discworld, Achaea) reaching **300-400+ when including social, class-specific, and skill-based variants**. Single-player IF games rarely exceed 50-100 verbs.

---

## Standard MUD Verb Sets

### Navigation / Movement
**Core Commands:**
- `north`, `south`, `east`, `west`, `up`, `down` (directional movement)
- `enter`, `leave`, `go`, `move` (dynamic location changes)
- `climb`, `descend`, `swim`, `dive` (terrain-specific movement)

**Abbreviations (Universal):**
- `n`, `s`, `e`, `w`, `u`, `d` — Single-letter shortcuts are **mandatory** in classic MUDs
- Movement is the most frequently-used verb class; abbreviations reduce cognitive load and enable rapid navigation

**Notes:**
- Rooms modeled as graph nodes; exits stored as edges (direction → destination)
- Conditional exits (locked doors, requires key, skill check) handled via Door objects
- No analog in single-player IF; multiplayer requires shared geography

---

### Combat
**Initiate Combat:**
- `attack <target>` / `kill <target>` / `fight <target>` — Standard combat initiation
- `challenge <player>` — Formal PvP duel request

**Combat Actions:**
- `hit`, `stab`, `slash`, `kick`, `bash`, `punch`, `bite` — Attack verbs
- `feint <target>`, `parry <target>`, `riposte` — Tactical defense/response verbs
- `backstab <target>`, `assassinate <target>` — Class-specific assassination verbs
- `defend`, `shield <target>`, `rescue <player>` — Protection verbs
- `flee`, `retreat` — Escape combat (success varies by game balance)

**Resolution Models:**
- **Turn-based:** Commands execute in strict sequence (Achaea model)
- **Real-time/"Twitch":** Commands execute immediately with cooldowns (old MUD default)

**MUD-Specific Extensions:**
- No turn order overhead (player expects immediate resolution)
- No hidden hit points (players see damage numbers; encourages tactical decisions)
- Class-specific combat verbs grant mechanical differentiation (assassins backstab; priests heal; warriors parry)

---

### Social & Communication
**Voice Channels:**
- `say <message>` — Speak to everyone in current room
- `'<message>` — Shorthand for `say` (apostrophe-prefix)
- `tell <player> <message>` / `t <player> <message>` — Private message
- `reply <message>` / `r <message>` — Quick reply to last tell
- `shout <message>` / `yell <message>` — Room-wide announcement (audible globally or multi-room)
- `whisper <player> <message>` — Quiet private message (only target hears)
- `gossip <message>` / `gos <message>` — Global gossip channel (class-based or faction-based)
- `party chat <message>` / `pchat <message>` — Party-only communication
- `guild chat <message>` / `gchat <message>` — Guild-only communication

**Emotes / Roleplay:**
- `emote <action>` — Describe character action (e.g., `emote grins wickedly`)
- **Predefined Socials** (100+ variants):
  - `wave`, `smile`, `laugh`, `bow`, `nod`, `shrug`, `hug`, `kiss`, `slap`, `dance`, `prance`, `cower`, `salute`, `wink`, `punch <target>`, `kick <target>`, `bite <target>`, `beg <target>`
  - Each typically supports optional target: `hug` (general) or `hug <player>` (directed)
  - Socials are declarative; they modify the speaker's character description or trigger animations

**MUD-Specific Observation:**
- Socials are a **primary retention mechanism**. They enable roleplay without mechanical reward, keeping players engaged between combat/quests
- Social verb count in Discworld MUD exceeds **200+ distinct emote variants**
- Single-player IF games have **zero social verbs** by definition

---

### Inventory & Equipment
**Inventory Management:**
- `inventory` / `inv` / `i` — List carried items
- `get <item>` / `take <item>` — Acquire item from room
- `drop <item>` — Leave item in room
- `put <item> in <container>` / `put <item> on <object>` — Store item
- `give <item> to <player>` — Transfer ownership
- `look in <container>` — Examine container contents

**Equipping & Wielding:**
- `wear <item>` — Don clothing/armor
- `remove <item>` — Doff clothing/armor
- `wield <item>` — Ready weapon
- `unwield <item>` / `sheathe <item>` — Stow weapon
- `hold <item>` — Hold item (shield, torch, etc.)
- `equipment` / `eq` — List currently-equipped items

**Consumption & Use:**
- `eat <item>` — Consume food
- `drink <item>` — Drink beverage
- `fill <container> from <source>` — Fill container with water/liquid
- `use <item>` — Generic use command
- `activate <item>` — Trigger magical item

**Trade & Commerce:**
- `buy <item> from <merchant>` / `buy <item>` — Purchase item
- `sell <item> to <merchant>` / `sell <item>` — Sell item for money
- `list` — See merchant's shop inventory
- `value <item>` — Ask merchant price
- `give <item> to <player>` — Direct transfer (no coins)
- `trade <item> for <item> with <player>` — Barter system (if supported)

**MUD-Specific Notes:**
- Weight limits are **hard constraints** (unique to MUDs; IF rarely enforces)
- Money is **tokenized and tradeable** (gold coins, not abstract currency)
- Merchant shops are **persistent and shared** (all players see same inventory)

---

### Interaction & Examination
**Examination:**
- `look` / `l` — Examine current room
- `look at <object>` / `l <object>` — Examine specific object or player
- `examine <object>` / `x <object>` — Detailed inspection
- `look in <container>` — Peer inside
- `search <object>` — Thorough search (may trigger traps or reveal secrets)

**Object Interaction:**
- `open <door>` / `open <container>` — Unlock/open
- `close <door>` / `close <container>` — Seal/shut
- `lock <door>` — Secure door (if you have key)
- `unlock <door>` — Unlock door (if you have key)
- `pick <lock>` — Attempt lockpicking (rogue skill)
- `push <object>` — Activate mechanism
- `pull <object>` — Activate mechanism
- `turn <object>` — Rotate/manipulate
- `read <object>` — Read text (books, signs, scrolls)
- `press <object>` — Activate button/lever

---

## Verb Categories Grouped by Function

### 1. Navigation (Movement)
| Verb | Purpose |
|------|---------|
| north, n | Move north |
| south, s | Move south |
| east, e | Move east |
| west, w | Move west |
| up, u | Move up (stairs, climb) |
| down, d | Move down (stairs, descent) |
| enter | Enter location (enter shop, enter cave) |
| leave | Exit location |
| go | Generic movement (go to tavern, go outside) |
| climb, swim, dive | Terrain-specific movement |

**Verb Count:** 10+ base verbs + directional abbreviations

---

### 2. Combat
| Verb | Purpose |
|------|---------|
| attack, kill, fight | Initiate combat |
| hit, stab, slash | Physical attacks |
| kick, bash, punch | Unarmed attacks |
| feint, parry, riposte | Defense/tactics |
| backstab, assassinate | Class-specific attacks |
| defend, shield, rescue | Protection/support |
| flee, retreat | Escape combat |
| challenge | Formal duel request |

**Verb Count:** 15+ base combat verbs + class-specific variants

---

### 3. Social & Communication
| Verb | Purpose |
|------|---------|
| say, ' | Speak to room |
| tell, t | Private message |
| reply, r | Quick reply to last tell |
| shout, yell | Global announcement |
| whisper | Quiet private message |
| gossip, gos | Global channel (often faction-based) |
| party chat, pchat | Party-only communication |
| guild chat, gchat | Guild-only communication |
| emote | Describe action |
| wave, smile, laugh, bow, etc. (100+) | Predefined socials/emotes |

**Verb Count:** 200+ when including all social variants

---

### 4. Inventory & Equipment
| Verb | Purpose |
|------|---------|
| inventory, inv, i | List items |
| get, take | Acquire item |
| drop | Leave item |
| put | Store in container |
| give | Transfer item |
| wear | Don clothing |
| remove | Doff clothing |
| wield | Ready weapon |
| hold | Hold item |
| equipment, eq | List equipped items |
| eat, drink | Consume items |
| buy, sell | Commerce |

**Verb Count:** 15-20 base inventory verbs + social variants

---

### 5. Interaction & Examination
| Verb | Purpose |
|------|---------|
| look, l | Examine room/object |
| examine, x | Detailed inspection |
| search | Thorough search |
| open, close | Manipulate doors/containers |
| lock, unlock | Secure/unsecure |
| pick | Lockpicking |
| push, pull, turn | Activate mechanisms |
| read | Read text |
| press | Activate buttons |

**Verb Count:** 15+ base interaction verbs

---

### 6. Information & Status
| Verb | Purpose |
|------|---------|
| score, status | View character stats |
| who | List online players |
| inventory, eq | Item status |
| help | Access help system |
| commands | List available commands |
| skills | List learned skills |
| spells | List learned spells |
| where | Locate other players (if GM-level) |
| time | Current MUD time |

**Verb Count:** 10+ information verbs

---

### 7. Crafting & Production
| Verb | Purpose |
|------|---------|
| craft, build, forge | General crafting |
| smith | Blacksmithing |
| tailor | Clothing/armor making |
| carve, engrave | Artistic crafting |
| cook | Food preparation |
| weave | Textile work |
| brew, distill, ferment | Potion/drink creation |
| enchant | Magical enhancement |
| assemble, tinker | Mechanical assembly |

**Verb Count:** 10-15 crafting verbs + skill-specific variants

---

### 8. Magic & Casting
| Verb | Purpose |
|------|---------|
| cast | Cast spell (cast fireball at orc) |
| chant, invoke, recite | Alternative spell invocation |
| memorize, study | Learn spell (older systems) |
| use | Generic skill/spell activation |
| practice, train | Improve skill (grind action) |
| scribe | Write scrolls (if supported) |
| summon, conjure | Summon creatures/items |

**Verb Count:** 10+ magic verbs + spell-specific variants (50-100 spell names)

---

## MUD-Specific Verbs (Multiplayer-Only)

### Party Commands
- `party create` — Establish party
- `party invite <player>` — Invite to party
- `party accept <player>` — Accept invitation
- `party leave` — Exit party
- `party kick <player>` — Remove member (leader only)
- `party info` / `pwho` — View party roster
- `party chat <message>` / `pchat` — Party-only message
- `follow <player>` — Follow party leader
- `assist <member>` — Target party member's target in combat

**Unique Aspect:** Party verbs have **no equivalent in single-player IF**. These are purely multiplayer social/mechanical structures.

---

### Guild Commands
- `guild create <name>` — Establish guild
- `guild invite <player>` — Invite to guild
- `guild accept <name>` — Join guild
- `guild leave` — Exit guild
- `guild info` — View guild details
- `guild members` — List guild roster
- `guild promote <member>` — Promote member (officer+)
- `guild demote <member>` — Demote member (officer+)
- `guild disband` — Disband guild (leader only)
- `guild chat <message>` / `gchat` — Guild-only communication
- `guild tribute` — Contribute gold/resources to guild fund

**Unique Aspect:** Guild verbs provide **persistent identity and storage**—the guild persists even when individual players log off. This creates *guild history* and *emergent politics*.

---

### PvP-Specific Verbs
- `attack <player>` — Attack another player (conflicts with peaceful zones)
- `challenge <player>` — Formal duel (opt-in)
- `pvp on` / `pvp off` — Toggle PvP mode
- `track <player>` — Hunt player (ranger/tracker class)
- `duel <player>` — Formal one-on-one combat
- `murder <player>` — Assassination verb (some MUDs; morally-flagged)
- `rescue <party_member>` — Pull party member from combat
- `yield`, `surrender` — Surrender in combat (if supported)

**Contrast with IF:** Single-player IF has no PvP verbs. Multiplayer MUDs embed combat hierarchy (duels, murder flags, guard rules) directly into the verb system.

---

### Economy & Trade (Multiplayer-Extended)
- `auction <item> <starting_bid>` — List item for auction
- `bid <auction_id> <amount>` — Bid on auction
- `bank <action>` — Deposit/withdraw money at bank
- `trade <player>` — Initiate trade window
- `offer <item>` — Add item to trade negotiation
- `accept trade` — Confirm trade
- `fee <amount>` — Split payment with party (some MUDs)

**Unique Aspect:** Multiplayer economy requires **persistent market mechanics**. Single-player IF has zero economy verbs (no multi-party commerce).

---

## Verb Aliases & Abbreviations

### Philosophy
MUDs universally support **abbreviations** as a core feature. Reasons:

1. **Speed** — Single letter faster than full word (n vs north)
2. **Muscle Memory** — Players develop ingrained patterns (muscle memory for combat sequences)
3. **Accessibility** — Reduces cognitive load during high-stress combat
4. **Standardization** — Every MUD follows same abbreviation rules (no learning curve)

### Abbreviation Patterns

**Single-Letter Abbreviations (Universal):**
- Movement: `n`, `s`, `e`, `w`, `u`, `d`
- Inventory: `i` (inventory), `g` (get), `d` (drop)
- Look: `l` (look), `x` (examine)
- Combat: `k` (kill), `a` (attack)

**Multi-Letter Abbreviations:**
- `inv` — inventory
- `eq` — equipment
- `pchat` — party chat
- `gchat` — guild chat
- `t` — tell
- `r` — reply

### Alias System (Advanced)

MUDs provide an `alias` command allowing players to create custom shortcuts and **command chains**:

```
alias loot get all from corpse; put all in bag; sit
alias setup inv; eq; score; who
alias flee cast feetwings; west; north; south
```

**Key Observation:** Aliases enable **macro programming** within the MUD itself. Players can create complex tactics without scripting. Discworld MUD and others lean into this heavily—top players maintain 50+ aliases for rapid responses.

**Single-Player IF Contrast:** Traditional IF rarely supports alias chaining. Our system could learn from MUD alias design for power users.

---

## Notable MUD Systems: Verb Patterns

### 1. DikuMUD / CircleMUD (C-based, 1990s)
**Architecture:** Centralized command dispatch + object verb handlers

**Verb Philosophy:**
- Commands dispatch to verb handlers on objects
- Objects implement custom `do_<verb>` functions
- No natural language parsing; syntax is fixed (e.g., `get apple`, not `pick up the shiny apple`)

**Approximate Verb Count:**
- Base verbs: ~40
- Social verbs: ~50
- Spells/skills: ~80
- Total: ~170+

**Key Verbs:**
- Movement: north, south, east, west, up, down (shortcuts: n, s, e, w, u, d)
- Combat: kill, hit, flee, rescue
- Inventory: get, drop, wear, remove, inventory
- Social: say, tell, shout, emote (+ 50 predefined socials)
- Magic: cast, memorize
- Information: look, examine, score, who, help

**Limitations:**
- No natural language (can't say "pick up the apple")
- No context-aware parsing (can't infer object from description)
- Static verb lists (adding verbs requires recompile in older CircleMUD)

---

### 2. LPMud / MudOS (LPC-based, 1990s-present)
**Architecture:** Natural Language Parser (NLP) built into driver; verbs registered with parsing rules

**Verb Philosophy:**
- Verbs are **data structures**, not functions
- Parser rules specify allowed syntax patterns (e.g., `at LIV`, `in OBJ`, `with OBJ`)
- Objects implement parse lists (`parse_command_id_list()`) for smart disambiguation

**Approximate Verb Count:**
- Base verbs: ~100
- Social verbs: ~100+
- Spells/skills: ~150+
- Total: ~300+

**Key Verbs:**
- Movement: north, south, east, west, up, down, enter, leave, climb, swim
- Combat: attack, kill, hit, stab, feint, parry, backstab, flee, rescue
- Inventory: get, drop, wear, remove, put, give, take
- Social: say, tell, shout, emote, whisper, reply (+ 100+ predefined socials)
- Magic: cast, chant, invoke, recite, summon, conjure, enchant
- Crafting: brew, distill, ferment, craft, forge, weave
- Information: look, examine, search, score, who, help, commands, skills

**Advantages:**
- Natural language parsing (can accept multiple phrasings of same command)
- Dynamic verb registration (no recompile for new verbs)
- Flexible parsing rules (enables "get all but the dagger")

**Modern Examples:** Discworld MUD (LPC + Discworld-specific extensions)

---

### 3. MUSH / MOO (Scheme/LPC-based, 1980s-present)
**Architecture:** Minimalist verb system; emphasis on social simulation and roleplay

**Verb Philosophy:**
- Verbs are **methods** on objects, not global commands
- Emphasis on **builder programming** (non-coders can create verbs)
- Focus on social interaction and roleplay, not game mechanics

**Approximate Verb Count:**
- Base verbs: ~20
- Social verbs: **200+** (extensive emote library)
- Custom verbs: ~50+ (builder-created)
- Total: ~270+

**Key Verbs:**
- Movement: @go, north, south, east, west
- Social: say, ":' (emote), page, pose, semipose, whisper
- Object manipulation: @get, @drop, @take, @put, @give, @drop, @go
- Information: @look, @examine, @who, @help
- **Extensive predefined socials** (wave, smile, laugh, bow, nod, shrug, hug, kiss, dance, etc.—100+ variants)
- Builder commands: @create, @set, @verb, @action, @property

**Unique Aspect:** MUSH/MOO prioritize **social simulation and creative expression**. Combat is optional; some MUSH games have zero combat verbs. Socials are first-class citizens.

**Modern Examples:** Various MUSH variants (Discworld MUSH, Harry Potter MUSH), MOO communities (LambdaMOO descendants)

---

### 4. Modern MUDs (Achaea, Discworld MUD, Iron Realms games)

#### Achaea (Iron Realms Entertainment, 2002-present)
**Approximate Verb Count:** 250-400+ (class-dependent)

**Verb Hierarchy:**
- **Universal Verbs** (~100): movement, basic combat, inventory, social
- **Class-Specific Verbs** (~50-100): unique skills per class (Ranger: track, aim; Infernal: infernal smite, summon)
- **Skill-Based Verbs** (~100+): learned verbs from skill trees (50+ skills × 2-3 verbs each = 100-150 skill verbs)
- **Guild Verbs** (~20): guild-specific commands (join, leave, promote, demote)

**Philosophy:** Verbs are **highly stratified by class and skill**. A fresh character knows ~50 verbs; a max-level character with all skills knows 300+.

#### Discworld MUD (LPC-based, 1992-present)
**Approximate Verb Count:** 300-500+

**Verb Breakdown:**
- **Core Commands** (~80): movement, basic inventory, information (look, inventory, score, who, help)
- **Standard Verbs** (~150): combat, social, crafting, magic (attack, say, tell, shout, brew, cast, etc.)
- **Soul/Emotes** (**200+**): extensive social library (wave, smile, laugh, bow, nod, shrug, hug, kiss, slap, bite, punch, dance, prance, cower, salute, wink, etc.)
- **Guild/Skill Verbs** (~50-100): learned from guilds and skills
- **Special Verbs** (~20): administrative, game-specific

**Philosophy:** Discworld MUD treats **social verbs with equal importance to mechanical verbs**. The "soul" system (200+ predefined emotes) enables rich roleplay without mechanical reward.

**Unique Feature:** Discworld MUD has a **natural language parser** (inherited from MudOS tradition) that accepts multiple phrasings:
- `get apple` ✓
- `take the apple` ✓
- `pick up the apple` ✓
- `get all apples` ✓
- `get all but the knife` ✓

---

## Verb Count Comparison: MUDs vs. Single-Player IF

| Game Type | Typical Verb Count | Abbreviations | Social Verbs | Multiplayer Verbs |
|-----------|-------------------|----------------|--------------|-------------------|
| Classic IF (Infocom) | 20-40 | Few (maybe 10) | 0 | 0 |
| Modern IF (Inform 7) | 40-80 | ~20 | 0-5 | 0 |
| CircleMUD (C-based) | 170+ | Extensive (n,s,e,w,u,d) | 50+ | Yes (party, guild) |
| LPMud (Discworld) | 300-500+ | Extensive + parser | 200+ | Yes (party, guild, PvP, economy) |
| Achaea (Modern Iron Realms) | 250-400+ | Extensive + parser | 100+ | Yes (party, guild, PvP, auction) |
| MUSH/MOO | 200-300+ | Moderate | **200+** | Yes (social-focused) |

**Insight:** Multiplayer MUDs have **5-10× more verbs than single-player IF**, primarily due to:
1. Social/emote verbs (MUDs: 200+; IF: 0)
2. Multiplayer-specific verbs (party, guild, PvP, auction)
3. Skill/spell variants (MUDs scale with class and skill trees)

---

## Multiplayer-Specific Verbs (Absent from Single-Player IF)

### Party System
- Collaborative verb set enabling grouped play
- Core verbs: `party create`, `party invite`, `party accept`, `party leave`, `party info`, `party chat`
- Combat assist verbs: `assist`, `follow`, `rescue`

### Guild System
- Persistent org verbs (survive player logout)
- Core verbs: `guild create`, `guild invite`, `guild join`, `guild leave`, `guild info`, `guild chat`
- Admin verbs: `guild promote`, `guild demote`, `guild disband`
- Economy: `guild tribute`, `guild withdraw`

### PvP System
- Combat vs. humans (not just NPCs)
- Core verbs: `pvp on`, `pvp off`, `challenge`, `duel`, `track`, `murder` (flagged)
- Escape/surrender: `yield`, `surrender`

### Economy System
- Multi-party commerce
- Core verbs: `auction`, `bid`, `bank`, `trade`, `offer`, `accept trade`
- No equivalent in single-player IF

### Communication Channels
- Gossip/faction channels (not available in IF)
- Verbs: `gossip`, `guild chat`, `party chat`, `faction chat` (if supported)
- Single-player IF has zero channel verbs

---

## Key Patterns for Our Game Design

### 1. Verb Abbreviation is Essential
**Finding:** Every successful MUD supports single-letter and common abbreviations.

**Implication for Our Game:** We should design abbreviations into the verb system from day one:
- `n`, `s`, `e`, `w`, `u`, `d` for movement
- `i` for inventory
- `l` for look
- `k` for kill (if combat is relevant)

### 2. Social Verbs Drive Long-Term Retention
**Finding:** Discworld MUD's 200+ emotes are used frequently, even in non-combat contexts. MUSH games prioritize socials; MOOs have minimal combat but extensive emotes.

**Implication for Our Game:** Social verbs should be **first-class citizens**, not an afterthought. A small catalog of predefined socials (50+) enables roleplay without mechanical complexity.

### 3. Natural Language Parsing Enables Rich Input
**Finding:** LPMud and modern MUDs accept multiple phrasings of the same command. This reduces cognitive load and feels more natural.

**Implication for Our Game:** Our Tier 2 embedding parser should aim for this flexibility. Exact synonym matching is important.

### 4. Class/Skill Verbs Create Strategic Depth
**Finding:** Achaea and Discworld scale verbs by class and skill. A fresh character feels simple; a max-level character has 300+ verbs to master.

**Implication for Our Game:** If we implement progression, verbs should unlock as players grow. Don't overwhelm newbies with 300 verbs; scale verb discovery.

### 5. Multiplayer Verbs are Structurally Distinct
**Finding:** Party, guild, and PvP verbs have no single-player equivalents. They require new game state (party roster, guild treasury, PvP flags).

**Implication for Our Game:** Our multiplayer system should introduce new verb categories:
- `party invite`, `party chat`, `follow` (coordination)
- `guild create`, `guild chat`, `guild fund` (persistent org)
- `trade`, `auction` (economy)

These verbs should be **designed for multiplayer from the start**, not bolted on afterward.

### 6. Aliases Enable Power-User Customization
**Finding:** MUDs support the `alias` command, allowing players to create custom shortcuts and even command chains (e.g., `alias setup inv; eq; score; who`).

**Implication for Our Game:** An alias system could be a post-MVP feature, enabling power users to customize their experience. This also reduces cognitive load for new players (fewer verbs to memorize; more powerful sequences available).

---

## Recommendations for MMO Multiplayer Text Adventure

### Phase 1: Core Verbs (MVP)
Implement a minimal verb set for single-player prototype:

**Navigation:** north, south, east, west, up, down, enter, leave, go, look, examine
**Inventory:** get, drop, inventory, wear, remove, take, put, give
**Interaction:** open, close, push, pull, read
**Information:** score, help, commands, look, search
**Social:** say, emote, shout

**Total:** ~30 verbs

### Phase 2: Multiplayer Additions
Add multiplayer-specific verbs:

**Communication:** tell, reply, gossip, party chat, guild chat
**Multiplayer Mechanics:** party create, party invite, party leave, party chat, guild create, guild invite, guild chat, follow, assist, trade, auction
**PvP (if included):** challenge, duel, pvp toggle

**Total:** ~15 new verbs (45 cumulative)

### Phase 3: Expansion (Post-MVP)
Deepen the verb system as content grows:

**Crafting:** craft, brew, forge, cook, weave, enchant, disenchant
**Magic:** cast, chant, invoke, memorize, scribe
**Social/Emotes:** wave, smile, laugh, bow, nod, shrug, hug, kiss, dance, etc. (50+ variants)
**Economy:** banking, faction rep, specialized trading
**Aliases:** Support custom alias creation

**Total:** ~100+ verbs (150+ cumulative)

### Strategic Design Notes
1. **Abbreviations First:** Design abbreviations alongside verbs (n for north, i for inventory).
2. **Multiplayer as First-Class:** Party and guild verbs should be core to the design, not bolted on.
3. **Social Verbs Matter:** A small catalog of predefined socials (50+) enables roleplay and increases retention.
4. **Scalable Verb Discovery:** Verbs should unlock with progression; don't overwhelm newbies.
5. **Natural Language Parsing:** Our Tier 2 embedding parser should handle multiple phrasings of the same intent.

---

## Sources & Further Reading

- CircleMUD GitHub: `/lib/text/help/commands.hlp` (comprehensive command list)
- DikuMUD Wiki: https://wiki.dikumud.com/ (architecture and verb patterns)
- Discworld MUD Wiki: https://dwwiki.mooo.com/wiki/Category:Commands (300+ documented verbs)
- Islands of Myth LPC Parser Guide: http://islandsofmyth.org/wiz/parser_guide.html (MudOS verb system)
- Achaea Wiki Newbie Guide: https://wiki.achaea.com/Newbie_Guide (modern MUD command structure)
- The Adventurers' Guide to the Discworld MUD: https://herebefootnotes.wordpress.com/ (social verbs, aliases, roleplay)
- Evennia Documentation: https://www.evennia.com/ (modern Python MUD engine; good reference for verb system design)

---

## Conclusion

MUDs represent the most mature verb system in multiplayer text adventure design. Their lessons—abbreviations, social verbs as retention drivers, natural language parsing, multiplayer-specific commands, and progressive verb discovery—are directly applicable to our game.

The key insight: **Multiplayer text adventures need 5-10× more verbs than single-player IF**, not because the mechanics are more complex, but because social coordination (party, guild, chat channels) and commerce require new verb categories entirely absent from single-player games.

Our design should embrace this multiplayer-first philosophy and build the verb system accordingly, starting with essentials and scaling with content.
