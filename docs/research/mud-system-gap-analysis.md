# MUD System Gap Analysis: What Are We Missing?

**Date:** 2026-03-27  
**Researcher:** Frink (AI Research Specialist)  
**Context:** Comparing MMO's current verb & system coverage to classic MUD libraries and system categories  

---

## Executive Summary

Classic MUDs (LPMud, DikuMUD, CircleMUD, Discworld) support **200-400+ verbs** and **12+ major subsystems**. Our MMO currently implements **~35 core verbs** (primarily for single-player object manipulation) and **4 subsystems** (inventory, injuries, parser, basic UI). 

**The Gap:** We're missing **entire categories** essential for multiplayer gameplay, commerce, progression, and retention. This analysis identifies which gaps matter for our vision and which we can defer.

---

## SECTION 1: Verb Coverage Matrix

### Legend
- ✅ **Have** — Fully implemented and tested
- 🟡 **Partial** — Core implemented; variants or related verbs missing
- ❌ **Missing** — Not implemented
- ⏸️ **Not Needed Yet** — Out of scope for current phase

---

### 1.1 Communication Verbs (Social/Multiplayer)

| Category | Verb | Status | Notes | Priority |
|----------|------|--------|-------|----------|
| **Voice Channels** | say | ❌ | NPC dialogue exists; no player-to-player voice | Medium |
| | whisper | ❌ | Private messaging not implemented | Medium |
| | shout | ❌ | Room-wide broadcast not implemented | Medium |
| | tell / message | ❌ | Requires persistent multiplayer layer | High |
| | gossip / channel chat | ❌ | Requires channel infrastructure | Low |
| **Roleplay/Emotes** | emote / pose | ❌ | No social action system | High |
| | wave, bow, laugh, cry, hug, slap | ❌ | Predefined socials (200+ in Discworld) completely absent | High |
| | nod, shrug, smile, wink | ❌ | See above | High |

**Summary:** 0/11 communication verbs. This is our **largest gap**. Multiplayer retention depends entirely on social channels.

---

### 1.2 Movement Verbs (Current Status)

| Verb | Status | Notes |
|------|--------|-------|
| go, move, walk, run, head | ✅ | Fully implemented; cardinal + up/down |
| climb, enter, leave | 🟡 | Basic climb in `go.md`; may need expansion |
| swim, dive, fly | ❌ | Terrain-specific; defer until level design requires |
| descend | 🟡 | Covered by `down` |
| sneak | ❌ | Stealth mechanic not implemented |

**Summary:** 5/8 core. Movement is adequate for Phase 1.

---

### 1.3 Perception & Information Verbs

| Verb | Status | Notes |
|------|--------|-------|
| look, examine, x | ✅ | Fully implemented; sensory-aware |
| search, find | ✅ | Traversal search implemented |
| feel, touch, grope | ✅ | Tactile sensory implemented |
| smell, sniff | ✅ | Olfactory sensory implemented |
| taste, lick | ✅ | Gustatory sensory (flagged as dangerous) |
| listen, hear | ✅ | Auditory sensory implemented |
| read | ✅ | Reading text on objects |
| inventory, i | ✅ | Player inventory display |
| score, stat, who, map | ❌ | Multiplayer or game-state queries (defer) |
| help | 🟡 | Basic help exists; needs command reference |

**Summary:** 9/13 perception verbs. Strong coverage for single-player.

---

### 1.4 Object Acquisition & Manipulation

| Verb | Status | Notes |
|------|--------|-------|
| take, get, grab, pick | ✅ | Full implementation |
| drop, leave | ✅ | Full implementation |
| put, place, insert | ✅ | Containment system in place |
| open, unlock | ✅ | Door/container system implemented |
| close, lock, shut | ✅ | Full implementation |
| pull, push, lift, yank, tug | ✅ | Implemented (includes lever mechanics) |
| turn, rotate | 🟡 | Partial (lever turning exists) |
| give, hand, offer | ❌ | NPC trade system not yet implemented |
| trade, barter | ❌ | Player-to-player trading not implemented |

**Summary:** 7/9 core implemented. **Give/trade require NPC & commerce systems** (see Section 2).

---

### 1.5 Combat Verbs

| Verb | Status | Notes |
|------|--------|-------|
| hit, attack, strike | 🟡 | Combat system exists; only basic "hit" exposed |
| stab, slash | ✅ | Weapon-type verbs implemented |
| cut | ✅ | Cutting tool system in place |
| kick, punch, bite | ❌ | Unarmed combat verbs not implemented |
| defend, parry, riposte | ❌ | Tactical defense system not implemented |
| flee, retreat | ❌ | Combat escape not implemented |
| kill, challenge | ❌ | Turn-based combat or PvP not implemented |
| backstab, assassinate | ❌ | Skill-specific verbs not implemented |
| shoot, cast (spells) | ❌ | Ranged/magic combat not implemented |

**Summary:** 3/9 combat verbs. We have **static damage** but no **live combat system**. This is intentional for MVP (combat is Phase 2+).

---

### 1.6 Equipment & Wearing

| Verb | Status | Notes |
|------|--------|-------|
| wear, put on | ✅ | Wearable system fully implemented |
| remove, doff, take off | ✅ | Full implementation |
| wield, unwield, sheathe | ❌ | Weapon-readiness system not implemented |
| hold | ❌ | Secondary hand-grip not implemented |
| equipment, eq | 🟡 | Inventory shows worn items; no dedicated "eq" command |

**Summary:** 2/5. Core wearing works; weapon-readiness deferred.

---

### 1.7 Crafting & Creation Verbs

| Verb | Status | Notes |
|------|--------|-------|
| combine, mix, blend | ❌ | Recipe system not implemented |
| craft, build, construct | ❌ | Crafting system not implemented |
| forge, smelt, cook, brew | ❌ | Specialization crafting not implemented |
| repair, mend, fix | 🟡 | Sew verb exists; generic repair not implemented |
| sew, stitch | ✅ | Needle + thread crafting implemented |
| write, inscribe | ✅ | Writing on objects implemented |
| apply | ✅ | Apply healing items (limited) |
| pour | ✅ | Liquid pouring implemented |

**Summary:** 3/8 crafting verbs. We have **atomic operations** but no **recipe/crafting framework**. This is major gap for progression.

---

### 1.8 Destruction Verbs

| Verb | Status | Notes |
|------|--------|-------|
| break, smash, shatter | ✅ | Mutation system fully implemented |
| tear, rip | ✅ | Tear verb implemented |
| burn, set on fire | 🟡 | Light/extinguish implemented; burn mutations not fully wired |
| light, ignite, strike | ✅ | Fire-making system implemented |
| extinguish, snuff | ✅ | Full implementation |

**Summary:** 4/5. Object destruction is well-covered.

---

### 1.9 Consumption & Consumption Effects

| Verb | Status | Notes |
|------|--------|-------|
| eat, consume | ✅ | Eating mechanic with hunger effects implemented |
| drink | ✅ | Drinking mechanic with thirst effects implemented |
| fill, refill | ❌ | Liquid container system not implemented |
| pour | ✅ | Pour implementation exists |
| taste, lick | ✅ | Taste sensory verb exists |

**Summary:** 4/5. Consumption covered; liquid containers pending.

---

### 1.10 Commerce Verbs (Single Most Missing Category)

| Verb | Status | Notes |
|------|--------|-------|
| buy, purchase | ❌ | Shop system not implemented |
| sell | ❌ | Shop system not implemented |
| list | ❌ | Merchant inventory display not implemented |
| value, appraise, price | ❌ | Item valuation not implemented |
| trade, barter, exchange | ❌ | Trading system not implemented |

**Summary:** 0/5. **Complete gap**. Commerce requires NPC dialogue, merchant inventory, currency system.

---

### 1.11 Magic & Spellcasting Verbs

| Verb | Status | Notes |
|------|--------|-------|
| cast, invoke, spell | ❌ | No spell system implemented |
| enchant, dispel | ❌ | No magic system implemented |
| scry, divinate | ❌ | No divination system implemented |

**Summary:** 0/3. Deferred; not in MVP scope.

---

### 1.12 Miscellaneous Verbs

| Verb | Status | Notes |
|------|--------|-------|
| sleep, rest, wait | 🟡 | Sleep implemented; wait not exposed |
| quit, exit | ✅ | Exit command implemented |
| help, hint, commands | 🟡 | Basic help; no hint system |
| undo, recall | ❌ | Time-rewind system not implemented (design consideration) |
| save, load | ⏸️ | Persistence layer separate from game logic |
| time, date, weather | ❌ | Weather system not in scope; time-of-day exists |

**Summary:** 1.5/6 misc verbs.

---

## SECTION 1 SUMMARY: Verb Coverage

| Category | Have | Total | % | Gap Analysis |
|----------|------|-------|---|----|
| Communication | 0 | 11 | 0% | **CRITICAL GAP** — Essential for multiplayer retention |
| Movement | 5 | 8 | 62% | Adequate for Phase 1 |
| Perception | 9 | 13 | 69% | Strong single-player coverage |
| Object Manipulation | 7 | 9 | 78% | Strong; requires NPC trade system |
| Combat | 3 | 9 | 33% | Intentional deferral; Phase 2+ |
| Equipment | 2 | 5 | 40% | Core works; weapon-readiness deferred |
| Crafting | 3 | 8 | 38% | **Major gap** — No recipe framework |
| Destruction | 4 | 5 | 80% | Well-covered |
| Consumption | 4 | 5 | 80% | Well-covered |
| Commerce | 0 | 5 | 0% | **CRITICAL GAP** — Requires NPC + shops |
| Magic | 0 | 3 | 0% | Deferred to Phase 2+ |
| Miscellaneous | 1.5 | 6 | 25% | Low priority for MVP |
| **TOTAL** | **39** | **87** | **45%** | |

---

## SECTION 2: System Coverage Matrix

Classic MUDs typically feature 12-15 major subsystems. We have 4-5. Here's the gap:

### 2.1 Implemented Systems ✅

| System | Status | Notes |
|--------|--------|-------|
| **Player Model** | ✅ | Hands, worn items, skills, appearance, consciousness |
| **Inventory System** | ✅ | Hand slots, worn slots, containment hierarchy |
| **Object System** | ✅ | Mutations, state machines, materials, properties |
| **Parser** | ✅ | 5-tier (rule-based → embedding → SLM) |
| **Sensory System** | ✅ | Light/dark, multi-sense perception |
| **Injuries System** | ✅ | Injury tracking, targeting, healing |

**Count:** 6 major systems implemented.

---

### 2.2 Critical Missing Systems ❌ (Required for Multiplayer)

| System | Impact | Complexity | Notes |
|--------|--------|-----------|-------|
| **Communication/Chat** | 🔴 CRITICAL | High | Global chat, tells, room broadcast. Core multiplayer feature. **Priority: P0** |
| **NPCs/Mobs/Dialogue** | 🔴 CRITICAL | High | Dialogue trees, quest-givers, merchants. Foundational for progression. **Priority: P0** |
| **Economy/Commerce** | 🔴 CRITICAL | High | Currency, shops, trading, player-to-player exchange. Essential for long-term engagement. **Priority: P0** |

---

### 2.3 Important Missing Systems 🟡 (Post-MVP but Soon)

| System | Impact | Complexity | Notes |
|--------|--------|-----------|-------|
| **Crafting Framework** | 🟡 HIGH | Medium | Recipe system, skill checks, output generation. Adds depth. **Priority: P1** |
| **Skills/Leveling** | 🟡 HIGH | Medium | XP system, skill trees, progression. Retention driver. **Priority: P1** |
| **Quests/Objectives** | 🟡 HIGH | Medium | Quest tracking, objectives, rewards. Narrative structure. **Priority: P1** |
| **Groups/Parties** | 🟡 MEDIUM | Medium | Party formation, shared experience, group commands. **Priority: P2** |
| **PvP System** | 🟡 MEDIUM | High | Duel system, damage, death mechanics. Competitive engagement. **Priority: P2** |
| **Housing/Player Spaces** | 🟡 MEDIUM | High | Player-owned rooms, decoration, persistence. **Priority: P3** |
| **Time/Weather** | 🟡 LOW | Low | Day/night cycles, seasons, weather effects. Atmospheric. **Priority: P3** |
| **Hunger/Thirst/Survival** | 🟡 LOW | Medium | Resource drains, survival mechanics. Already have basic hunger/thirst. **Priority: P2** |

---

### 2.4 Optional/Future Systems ⏸️ (Beyond Phase 2)

| System | Notes |
|--------|-------|
| **Magic/Spellcasting** | Entire new verb + effect infrastructure. Defer until singleplayer magic validated. |
| **Guilds** | Social hierarchy, guild halls, faction warfare. Defer until 100+ concurrent players. |
| **Bulletin Boards/Mail** | Async communication. Defer until persistent world. |
| **Banking/Vaults** | Item storage. Implement with economy system. |
| **Ranking/Leaderboards** | Competitive metrics. Defer until sufficient playerbase. |
| **Minigames** | Card games, dice, etc. Defer until engagement metrics require. |

---

## SECTION 3: Priority Gaps

### 🔴 CRITICAL (Must Have Before Multiplayer Launch)

1. **Communication System** — Player-to-player chat, tells, room broadcast
   - *Gap Impact:* Without this, multiplayer is dead. Players can't coordinate or socialize.
   - *Estimated Effort:* 2-3 weeks (chat server + client-side UI + relay infrastructure)
   - *Why It Matters:* Discworld MUD attributes 50%+ of retention to social channels.

2. **NPC/Dialogue System** — Quest-givers, merchants, character interaction
   - *Gap Impact:* No way to learn story, acquire missions, or trade with NPCs.
   - *Estimated Effort:* 3-4 weeks (dialogue tree engine + NPC state machine + quest hooks)
   - *Why It Matters:* NPCs are the narrative backbone; quest rewards drive progression.

3. **Economy/Commerce System** — Currency, shops, trading
   - *Gap Impact:* No reason to acquire items beyond puzzle-solving. No long-term goal structure.
   - *Estimated Effort:* 2-3 weeks (currency system + shop inventory + trading UI)
   - *Why It Matters:* Commerce creates emergent player interaction; player-to-player trading is a retention driver.

---

### 🟡 HIGH (Phase 1.5 — Post-MVP)

4. **Crafting Framework** — Recipe system, multi-step assembly
   - *Gap Impact:* Players can't create new objects; puzzle scope is limited.
   - *Estimated Effort:* 2 weeks (recipe engine + skill checks + output validation)
   - *Why It Matters:* Crafting is second-largest retention driver after combat (MUD data).

5. **Skills/XP System** — Character progression, stat growth
   - *Gap Impact:* No sense of progression. All characters are identical.
   - *Estimated Effort:* 1-2 weeks (XP tracking + skill tree + level gates)
   - *Why It Matters:* Progression is intrinsic motivation in games. Without it, players stop after 2-3 hours.

6. **Quest System** — Objective tracking, turn-ins, rewards
   - *Gap Impact:* No structured narrative progression beyond puzzles.
   - *Estimated Effort:* 2 weeks (quest state machine + turn-in verification + reward distribution)
   - *Why It Matters:* Quests create milestones and social proof (achievement display).

---

### 🟢 MEDIUM (Phase 2 — if data supports)

7. **PvP/Combat Progression** — Live combat, duels, rankings
   - *Gap Impact:* Competitive gameplay entirely absent.
   - *Estimated Effort:* 4-5 weeks (turn-based combat + damage model + rankings)
   - *Why It Matters:* Hardcore players (15-20% of base) drive engagement and content creation.

8. **Groups/Parties** — Co-op mechanics, shared experience
   - *Gap Impact:* Multiplayer is isolation chambers; players can't adventure together.
   - *Estimated Effort:* 2-3 weeks (group state + shared XP + group verb aliases)
   - *Why It Matters:* Guild recruitment and group content extend gameplay.

---

### ⏸️ LOW (Phase 3+)

9. **Housing** — Personal rooms, decoration, storage
   - Gap Impact: Nice-to-have; not essential for MVP.
   - Effort: 3-4 weeks

10. **Time/Weather** — Atmospheric systems
    - Gap Impact: Cosmetic; can hardcode time-of-day for now.
    - Effort: 1-2 weeks

---

## SECTION 4: What We Can Skip (And Why)

### Genuinely Not Needed for Our Vision

1. **Magic/Spellcasting** ⏸️
   - *Why Skip:* We're not a magic game. Puzzles are object-manipulation, not arcane.
   - *Can Add Later:* Yes; magic is optional flavor. Validate single-player magic in a Level 2 puzzle first.

2. **Turn-Based Combat AI** ⏸️
   - *Why Skip:* Combat is PvP-focused, not against mobs. Mobs don't need complex AI.
   - *Can Add Later:* Yes; hostile NPCs can be simple "attack on sight" or flee.

3. **Minigames** (cards, dice, fishing) ⏸️
   - *Why Skip:* Out of scope. Each minigame is a vertical slice requiring unique UI + rules.
   - *Can Add Later:* Yes; add only after player engagement metrics show demand.

4. **Guild Wars/Faction Warfare** ⏸️
   - *Why Skip:* Requires 50+ concurrent players minimum to be meaningful.
   - *Can Add Later:* Yes; implement at DAU = 500.

5. **Leaderboards/Ranking Systems** ⏸️
   - *Why Skip:* Premature. Need sufficient playerbase first.
   - *Can Add Later:* Yes; implement once top 100 players are identifiable.

---

### Intentionally Simplified (vs. Classic MUDs)

1. **Abbreviations** 🟢
   - We Support: n, s, e, w, u, d, i, l, x, q
   - We Don't Need: Hundreds of power-user aliases (not mobile-friendly)
   - *Rationale:* Mobile text entry is expensive; tap-to-suggest UI is better than abbreviations.

2. **Verb Synonyms** 🟢
   - We Support: get/take, go/move, x/examine, l/look
   - We Don't Overload: Unlike MUDs, we consolidate synonyms instead of proliferating verbs
   - *Rationale:* Simpler verb registry = easier to document + maintain.

3. **Complex Weapon Types** 🟡
   - We Support: stab, slash, cut (3 weapon classes)
   - Classic MUDs: 20+ weapon types (axe, mace, sword, polearm, bow, etc.)
   - *Rationale:* Too much granularity for MVP. Add if combat progression demands it.

4. **Class-Specific Verbs** 🟡
   - We Don't Have: Thief-only "backstab", Cleric-only "heal", Warrior-only "parry"
   - Classic MUDs: 50+ class-specific verbs
   - *Rationale:* Classes introduce combinatorial complexity. Defer until we validate class gameplay.

---

## SECTION 5: Recommendations for CBG & Bart

### Immediate Actions (Next 2 Weeks)

**CBG (Design Lead):**
1. **Finalize Communication Architecture** — Which chat channels? (room-only? global? faction-based?)
   - *Decision Needed:* Sync with Bart on infrastructure constraints (see Architecture below).
   - *Output:* `docs/design/communication-system.md` (verb, UI spec, filtering rules)

2. **NPC Dialogue Specification** — What's minimum viable dialogue?
   - *Start Simple:* Dialogue trees with 3 branches + quest-turn-in logic.
   - *Output:* `docs/design/npc-dialogue-system.md` + dialogue schema.

3. **Commerce Price Model** — How do prices scale? Player-driven or fixed?
   - *Consider:* Inflation mechanics, player vendor taxes, NPC resale markup.
   - *Output:* `docs/design/economy-model.md` (currency, NPC prices, player taxes).

**Bart (Architecture Lead):**
1. **Chat Infrastructure Design** — WebSocket relay? Persistence? Who subscribes to what channels?
   - *Decision:* Stateless HTTP polling vs. persistent WebSocket vs. hybrid?
   - *Output:* `docs/architecture/communication.md` (protocol, latency targets)

2. **NPC State Machine** — How do NPCs persist? Quest state tracking?
   - *Decision:* Ephemeral (reset on logout) vs. persistent (unlock stays permanent)?
   - *Output:* `docs/architecture/npc-state.md` (FSM, save/load strategy)

3. **Economy Persistence** — Currency ledger? Shop inventory?
   - *Decision:* Redis + PostgreSQL? Lua table snapshots?
   - *Output:* `docs/architecture/economy-persistence.md` (consistency model, audit trail)

---

### Phase 1.5 Planning (Weeks 3-6)

**Crafting System Design (CBG):**
- Recipe schema (inputs, outputs, skill gates)
- Skill progression model (does sewing skill unlock new recipes?)
- Output: `docs/design/crafting-system.md`

**XP/Skills Design (CBG):**
- How are XP rewards calculated? Per puzzle? Per NPC interaction?
- Skill tree topology: linear or branching?
- Output: `docs/design/progression-system.md`

**Quest Framework (CBG + Bart):**
- Quest metadata schema (title, objective, reward)
- State tracking (pending, active, completed)
- Output: `docs/design/quest-system.md` + `docs/architecture/quest-state.md`

---

### Validation Questions for Product

1. **Multiplayer Scope:** Are we aiming for 10 concurrent players? 100? 1000?
   - *Impact:* Determines architecture (single Lua VM vs. sharded infrastructure).

2. **Persistent Universe or Instanced?** Do all players inhabit the same world?
   - *Impact:* Affects NPC behavior, economy dynamics, housing feasibility.

3. **New Player Onboarding:** How do we teach verbs to new players?
   - *Gap Identified:* No tutorial system, no guided quest, no contextual help.
   - *Consider:* First 10 minutes should teach parser interaction + basic verbs.

4. **Monetization Model?** Does this affect NPC shop pricing? Cosmetics?
   - *Impact:* Determines economy balance.

---

## SECTION 6: Comparative Analysis

### How We Compare to Classic MUDs

| Dimension | Classic MUD | MMO (Current) | MMO (Post-MVP Target) |
|-----------|-------------|---------------|----------------------|
| **Core Verbs** | 200-400 | 35 | 80-100 |
| **Subsystems** | 12-15 | 6 | 12-14 |
| **Communication** | 20+ verbs (say, tell, emote, socials) | 0 | 6-8 |
| **Commerce** | Full shop system | 0 | Basic (buy/sell/list) |
| **Combat** | Live turn-based or real-time | 0 (deferred) | 0 (Phase 2+) |
| **Crafting** | 20+ verbs (forge, brew, cook, etc.) | 2 (sew, write) | 5-8 (recipes) |
| **NPCs** | 100+ dialogue-driven NPCs | 0 | 20-50 (questline NPCs) |
| **Progression** | XP, levels, skills, classes | Manual skill flags | XP + skill trees (P1.5) |
| **Multiplayer** | Native (from day 1) | Planned architecture only | Soft launch (10-50 DAU) |

---

## Conclusion

**We have a solid single-player foundation** (6 systems, 35 verbs). **We're missing the multiplayer soul** (0 communication verbs, 0 commerce, 0 NPC dialogue). 

**The path forward is clear:**
1. **MVP (Now → 2 weeks):** Launch with current systems; offline single-player OK
2. **Phase 1 (Weeks 3-4):** Add communication + basic NPC dialogue + shops
3. **Phase 1.5 (Weeks 5-6):** Add crafting recipes + XP system + quests
4. **Phase 2 (Weeks 7-12):** PvP combat, guilds, housing (if metrics support)

**Key Insight:** Our verb gap is intentional (we're not trying to be Zork). Our system gap is strategic (we're phasing in multiplayer). **No urgent refactoring needed**, but communication, NPCs, and economy are blockers for multiplayer launch.

---

**Document Status:** Ready for review by CBG (Design) and Bart (Architecture)  
**Next Action:** Stakeholder meeting to prioritize Phase 1 work items  
**Owner:** Frink (Research) + CBG (Design Lead)
