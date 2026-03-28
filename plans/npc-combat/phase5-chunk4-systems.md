# Phase 5 — Chunk 4: Feature Breakdown Per System + Cross-System Integration

**Author:** Bart (Architecture Lead) | **Date:** 2026-03-28 | **Chunk:** 4/5  
**Parent:** `plans/npc-combat/npc-combat-implementation-phase5.md`

---

## Section 1: Feature Breakdown (Per System)

### 1.1 Level 2 Rooms System

**Transition:** Brass key (from `start-room` rug, `src/meta/objects/brass-key.lua`) unlocks hallway `north` exit → `catacombs-entrance`. New `src/meta/levels/level-02.lua` mirrors `level-01.lua` structure. Loader initializes L2 rooms on boundary crossing. All L2 rooms start dark (light=0).

#### 7 Room Definitions

| Room ID | Name | Biome | Atmosphere Summary | Exits |
|---------|------|-------|--------------------|-------|
| `catacombs-entrance` | Catacombs Entrance | catacombs | Narrow stone passage, carved arch, faded inscriptions, cold draft, dust | S→hallway(L1), N→bone-gallery, E→collapsed-cellar |
| `bone-gallery` | The Bone Gallery | catacombs | Vaulted corridor, bone-patterned walls, niches, lime-dust air. 6°C | S→catacombs-entrance, W→underground-stream, N→werewolf-lair(stone door) |
| `underground-stream` | Underground Stream | water | Natural cavern, limestone stream, echoing water, mineral smell, dripping. 5°C, moisture 0.8 | E→bone-gallery, N→wolf-den(narrow) |
| `collapsed-cellar` | Collapsed Wine Cellar | rubble | Half-buried room, snapped beams, broken casks, vinegar-rot. 8°C | W→catacombs-entrance, Down→spider-cavern(hole) |
| `wolf-den` | Wolf Den | den | Low ceiling, packed earth, gnawed bones, musky predator stink, claw marks. 10°C | S→underground-stream, E→werewolf-lair(tunnel) |
| `spider-cavern` | Spider Cavern | web | High grotto, thick webs wall-to-wall, desiccated husks, sticky air. 9°C | Up→collapsed-cellar, N→wolf-den(crack, size-limited) |
| `werewolf-lair` | The Lair | lair | Largest chamber, rough pillars, human artifacts (torn clothing, broken lantern), deep stone gouges, rank musk. 11°C | S→bone-gallery(stone door), W→wolf-den(tunnel) |

**Topology:** Two paths to werewolf-lair: bone-gallery direct (stone door) or wolf-den via stream (longer, wolf encounters). Spider-cavern loops back through wolf-den crack. All 7 room `.lua` files → Moe (WAVE-1). `level-02.lua` → Moe + Bart (WAVE-1).

#### Biome Types

| Biome | Gameplay Effect |
|-------|----------------|
| `catacombs` | Sound carries 2 rooms; combat alerts creatures |
| `water` | Extinguishes unprotected flames; wet items |
| `rubble` | Some exits require clearing |
| `den` | Creature respawn point; territorial scent markers |
| `web` | Web traps; fire effective |
| `lair` | Boss territory; unique loot |

---

### 1.2 Werewolf Creature System

**Decision (Q1=B):** Separate NPC creature, not disease. No lycanthropy/transformation in Phase 5.

#### FSM States (6)

| State | Room Presence | Key Transitions |
|-------|---------------|-----------------|
| `alive-idle` | "A massive shape crouches motionless in the dark." | →patrol(timer:30), →aggressive(threat), →hunt(hunger) |
| `alive-patrol` | "A hulking figure stalks the passage." | →idle(complete), →aggressive(threat) |
| `alive-hunt` | "Something large moves with terrible purpose." | →aggressive(prey_found), →patrol(prey_lost) |
| `alive-aggressive` | "A werewolf looms — half-human, half-beast — fangs bared." | →idle(threat_gone), →flee(health<15%) |
| `alive-flee` | "The werewolf crashes away into the darkness." | →idle(safe_room) |
| `dead` | "In death, the face is almost human." | (final) |

**Behavior vs wolf:** aggression=85 (wolf:70), flee_threshold=15% (wolf:20%), `nocturnal=true`, `can_open_doors=true`, territory=`werewolf-lair`, patrol_rooms=`{werewolf-lair, bone-gallery}`.

#### Combat Stats

- **Size:** large (wolf: medium) | **Health:** 45 (wolf: 22) | **Speed:** 5
- **Weapons:** claw-swipe (slash, keratin, force=8, target=torso) + bite (pierce, tooth_enamel, force=7, target=arms)
- **Armor:** hide, coverage={body,head,arms,legs}, thickness=3 (wolf: 2)
- **Behavior:** territorial, counter defense, cycle attack pattern, pack_size=1

#### Loot Table

- **Always:** werewolf-hide, werewolf-claw
- **Weighted:** silver-pendant (25%), torn-journal-page (35%), nothing (40%)
- **Variable:** gnawed-bone ×1-3

#### Territory & Respawn

Home: `werewolf-lair`. Patrol: `{werewolf-lair, bone-gallery}`. Respawn: 400 ticks, max_population=1 (boss). Lingering scent in patrol rooms warns player. Death corpse: 4-stage spoilage (fresh→bloated→rotten→bones, 25% longer than wolf). Butchery: 4× werewolf-meat, 3× werewolf-bone, 1× werewolf-hide.

**Files (Flanders, WAVE-1):** `werewolf.lua`, `werewolf-hide.lua`, `werewolf-claw.lua`, `silver-pendant.lua`, `torn-journal-page.lua`, `werewolf-meat.lua`

---

### 1.3 Pack Tactics v1.1

**Decision (Q4=A):** Stagger attacks + alpha by health. No zone-targeting (Phase 6).

#### Existing Foundation (pack-tactics.lua, 110 LOC)

`select_alpha()` (health-based), `plan_attack()` (stagger +1/wolf), `should_retreat()` (health<20%), `get_pack_in_room()` — all ✅ implemented.

#### v1.1 Additions (~40 LOC)

**1. Dynamic pack_role:** `alpha` = highest health, `beta` = health>40%, `omega` = health≤40%. Recalculated each combat tick.

**2. Omega reserve:** New `evaluate_omega(creature, pack, ctx)` — omega disengages, moves toward nearest den exit. All-omega = full pack retreat.

**3. Alpha howl narration:** "The largest wolf throws back its head and howls. The pack surges forward." (Smithers)

**4. Stagger cap:** Max delay capped at 3 turns (prevents large packs feeling sequential).

#### Wolf Metadata Changes

- Add `pack_role = "beta"` (dynamic field)
- Change `pack_size` from 1 → 3 for Level 2 wolves
- Place 3 wolves in `wolf-den`, 1-2 in `underground-stream`

**Deferred (Phase 6):** Zone-targeting, formation behavior, howl-to-summon, pack morale, cross-room coordination.

**Files:** `pack-tactics.lua` modify (Bart, WAVE-2), `wolf.lua` modify (Flanders, WAVE-2), narration (Smithers, WAVE-2)

---

### 1.4 Salt Preservation System

**Decision (Q2=A):** Salt-only, ~80 LOC. No smoking/drying/pickling.

#### New Verb: `salt`

**Owner:** Smithers | **Aliases:** `salt`, `preserve`, `cure`

Checks: (1) target has `mutations.salt`, (2) player holds salt (`provides_tool = "preservative"`), (3) target in `fresh` state. Executes `context.mutation:apply(obj, "salt")`, consumes one salt use.

#### New Object: `salt.lua`

Template: `small-item`. Size: tiny, weight: 0.3. `provides_tool = "preservative"`, `consumable = true`, `uses = 3`. Sensory: soft leather pouch, coarse granules, sharp mineral smell, intensely salty. **Placement:** `collapsed-cellar` (shelf) and `werewolf-lair` (floor).

#### Mutation Pipeline

Meat objects gain `mutations.salt = { becomes = "salted-wolf-meat", message = "..." }`. Salted-meat objects are new definitions with 3-state FSM (fresh→stale→spoiled).

#### Spoilage Rates

| Type | Fresh | Stale | Total Edible |
|------|-------|-------|-------------|
| Unsalted meat | 7200s (2h) | — | 7200s |
| Salted meat | 21600s (6h) | 21600s (6h) | 43200s (12h) |

Spoilage multiplier lives in object FSM `duration` fields — no engine changes (Principle 8).

**Files (WAVE-3):** `salt` verb handler (Smithers), `salt.lua` + `salted-wolf-meat.lua` + `salted-werewolf-meat.lua` (Flanders), `wolf-meat.lua`/`werewolf-meat.lua` modify (Flanders), parser aliases (Smithers)

---

## Section 2: Cross-System Integration Points

### Integration Matrix

| Source → Target | Integration Point | Wave |
|----------------|-------------------|------|
| **L2 rooms → creature placement** | Wolves in wolf-den(×3) + stream(×1-2); werewolf in lair(×1); spiders in cavern(×2) | W1 |
| **L2 rooms → creature territory** | Wolf territory=wolf-den, patrol=stream. Werewolf territory=lair, patrol=bone-gallery | W1 |
| **L2 rooms → respawn system** | New home_rooms; caps: wolf=3, werewolf=1, spider=2 | W1 |
| **L2 rooms → level transition** | level-02.lua room membership; hallway.north → catacombs-entrance; loader init | W1 |
| **Werewolf → loot system** | Death triggers `roll_loot_table()`; always: hide+claw; weighted: pendant/journal | W1 |
| **Werewolf → butchery** | Corpse → 4×meat, 3×bone, 1×hide via existing butchery.lua | W1 |
| **Werewolf → spoilage FSM** | 4-state corpse decay (fresh→bloated→rotten→bones), 25% longer than wolf | W1 |
| **Pack tactics → combat engine** | `plan_attack()` stagger schedule feeds combat FSM turn-order | W2 |
| **Pack tactics → creature actions** | `evaluate_omega()` hooks creature tick; omega→retreat action | W2 |
| **Pack tactics → wolf metadata** | Wolf gains `pack_role` + `pack_size=3`; alpha/omega read/write per tick | W2 |
| **Pack tactics → narration** | Alpha howl + role-variant attack text ("alpha lunges" vs "another wolf presses") | W2 |
| **Salt verb → mutation engine** | `mutation:apply(obj, "salt")` — same pipeline as break/burn mutations | W3 |
| **Salt object → tool system** | `provides_tool = "preservative"` checked by `find_tool_in_hands()` | W3 |
| **Salted meat → food FSM** | Object declares 3× longer `duration` in FSM states; engine ticks generically | W3 |
| **Salt → consumable system** | `consumable=true, uses=3`; decremented per use, removed at 0 | W3 |
| **L2 rooms → salt placement** | Salt in collapsed-cellar (shelf) and werewolf-lair (floor) | W3 |

### Critical Integration Risks

| Risk | Mitigation |
|------|------------|
| Level transition breaks Level 1 | GATE-1: all 223 Phase 4 tests must pass |
| Werewolf loot references missing objects | Flanders creates loot objects in same wave as creature (WAVE-1) |
| Pack stagger vs combat FSM conflict | Nelson stagger-specific tests; deterministic seed `math.randomseed(42)` |
| Salt mutation targets nonexistent salted-meat | Parallel object+verb creation in WAVE-3 |
| Spoilage timers don't tick in L2 rooms | GATE-3 test: carry meat into L2, verify timer advances |
| Salt uses tracking | Nelson tests: salt 3 items, verify salt removed after 3rd |

---

**END OF CHUNK 4 (SYSTEMS)**

*Plan authored by Bart (Architecture Lead). Chunk 4/5 — feature breakdown + integration points complete.*
