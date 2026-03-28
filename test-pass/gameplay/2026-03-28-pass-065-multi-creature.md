# Pass-065: Multi-Creature Room — Rat + Spider Coexistence in Cellar

**Date:** 2026-03-28
**Tester:** Nelson
**Build:** Lua src/main.lua --headless (commit af64085)
**Scope:** Multi-creature interactions in cellar rooms — verify rat and spider coexist, test targeting, combat reactions, sensory detection

## Executive Summary

**Total Tests:** 23 | **Pass:** 10 | **Fail:** 10 | **Warn:** 3
**Bugs Filed:** 12 (BUG-192 through BUG-203)

The cellar successfully hosts both a rat and spider simultaneously — room descriptions confirm both creatures, and sensory systems (feel, smell, listen, taste, touch) all work well for targeting individual creatures. The creature ecosystem is atmospherically rich.

However, **combat narration is deeply broken** — "Someone" appears instead of "You", spider body zones reference human anatomy (knee, thigh, shin), and subject-verb disagreement is pervasive. The **creature stimulus system is partially broken** — the rat reacts when the spider is attacked, but the spider does NOT react when the rat is attacked. The **rat's wander FSM** makes it intermittently invisible to "look" (alternates every command). The **corpse spoilage FSM** runs at warp speed (fresh→bones in 3 commands). Several common combat synonyms (kill, slay, murder) are unrecognized.

**Severity Breakdown:**
- 🔴 CRITICAL: 0
- 🟠 HIGH: 5 (BUG-192, 193, 194, 195, 200)
- 🟡 MEDIUM: 6 (BUG-196, 197, 198, 199, 201, 202)
- 🔵 LOW: 1 (BUG-203)

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-192 | HIGH | Spider does not react when rat is attacked/killed in same room |
| BUG-193 | HIGH | Combat narration uses "Someone" instead of "You" for player actions |
| BUG-194 | HIGH | Combat narration grammar: subject-verb disagreement ("the teeth fails", "the organs gives") |
| BUG-195 | HIGH | Garbled spider bite text: "sinks its fangs into toward", incomplete sentences |
| BUG-196 | MEDIUM | Spider body zones reference human anatomy (knee, thigh, shin) instead of arachnid parts |
| BUG-197 | MEDIUM | "kill", "slay", "murder" not recognized as combat verbs |
| BUG-198 | MEDIUM | "look the rat" fails but "attack the rat" works — article stripping inconsistency |
| BUG-199 | MEDIUM | "look vermin" fails despite "vermin" being a registered keyword for rat |
| BUG-200 | HIGH | Dead rat corpse spoilage FSM runs at warp speed (fresh→bones in 3 commands) |
| BUG-201 | MEDIUM | "attack creature" silently picks first creature — no disambiguation (but "look creature" does ask) |
| BUG-202 | MEDIUM | Ambient smell/listen don't include rat in room scan results |
| BUG-203 | LOW | Death messages use lowercase: "a brown rat is dead!" should capitalize |

---

## Individual Tests

### T-001: Navigate to cellar — "go down"
**Input:** `go down` (from bedroom, no preparation)
**Response:** `a trap door blocks your path.`
**Verdict:** ✅ PASS — Trapdoor correctly blocks unprepared descent.

---

### T-002: Full navigation sequence to cellar
**Input:** `move bed` → `pull rug` → `open trapdoor` → `go down`
**Response:** Bed moves, rug reveals brass key, trapdoor opens with atmospheric text, player descends to cellar. Full room description rendered.
**Verdict:** ✅ PASS — Navigation chain works. Atmospheric text is excellent ("a breath of cold, damp air from below").

---

### T-003: Verify both creatures present in cellar
**Input:** `go down` (after opening trapdoor)
**Response:**
```
There is a large brown spider here. An iron brazier glows with dull coals,
radiating warmth. There is a brown rat here.

A glistening web stretches across the corner. A spider waits at its center. A
rat scurries along the baseboard.
```
**Verdict:** ✅ PASS — Both rat and spider confirmed in cellar room description. Spider has web, rat scurries. Atmospheric.

---

### T-004: Look at rat — keyword "rat"
**Input:** `look at rat` (in cellar)
**Response:** `A plump brown rat with matted fur and a long, naked tail. Its beady black eyes dart nervously, and its whiskers twitch with constant, anxious energy.`
**Verdict:** ✅ PASS — "look at rat" works. Great description.

---

### T-005: Look at spider — keyword "spider"
**Input:** `look at spider` (in cellar)
**Response:** `A palm-sized brown spider with thick, bristled legs and a bulbous abdomen marked with pale chevrons. It sits motionless at the center of a glistening web.`
**Verdict:** ✅ PASS — "look at spider" works. Vivid description.

---

### T-006: "look rat" intermittent failure
**Input:** `look rat` repeated 5 times in sequence
**Response:** Alternates: success → fail → success → fail → success. Every other command returns "You don't notice anything called that nearby." The rat messages alternate between "A brown rat scurries up." (leaves?) and "A rat scurries along the baseboard." (returns?).
**Verdict:** ❌ FAIL — Rat's wander FSM makes it intermittently invisible to "look" despite being in the room. Attack/feel/smell always find it.
**Note:** Not filed as separate bug — related to wander behavior. "look at rat" (with "at") works consistently; bare "look rat" triggers the issue combined with wander state.

---

### T-007: Examine rat and spider
**Input:** `examine rat` / `examine spider`
**Response:** "examine rat" intermittently fails (same wander issue as T-006). "examine spider" always works.
**Verdict:** ⚠️ WARN — Same intermittent rat targeting issue as T-006.

---

### T-008: Attack rat while spider is present
**Input:** `attack rat` (with knife, spider in same room)
**Response:**
```
You engage a brown rat with a small knife!
Someone plunges the steel into a brown rat's chest, hitting something vital.
The sight of death shakes you.
a brown rat is dead!
```
Spider reaction: **NONE.** No stimulus response, no flee, no tension change.
**Verdict:** ❌ FAIL
**Bug:** BUG-192 — Spider should react to combat/death in same room. Creature stimulus system defines `creature_attacked` and `creature_died` events, but spider shows no response. Compare: when spider is attacked first (T-010), the rat DOES react and flees.

---

### T-009: "Someone" in combat narration
**Input:** `attack rat` / `attack spider` (multiple sessions)
**Response:** Consistently uses "Someone" for player actions: "Someone plunges the steel", "Someone cuts toward", "Someone drives the steel deep into".
**Verdict:** ❌ FAIL
**Bug:** BUG-193 — All player combat actions narrated in third person as "Someone" instead of second person "You". Occurs 100% of the time across all combat sessions.

---

### T-010: Attack spider first — does rat react?
**Input:** `attack spider` (with knife, rat in same room)
**Response:**
```
You engage a large brown spider with a small knife!
[combat rounds...]
a large brown spider is dead!
The rat squeals — a piercing, desperate sound — and bolts!
A brown rat bolts up!
```
**Verdict:** ✅ PASS — Rat reacts to spider combat! Flees with atmospheric text. Returns after a beat ("A brown rat darts into the room, eyes wide with fear!"). This is excellent creature AI... but asymmetric with BUG-192 (spider doesn't react to rat combat).

---

### T-011: Combat grammar errors
**Input:** Multiple combat sessions
**Response samples:**
- "the keratin claws fails to bite" (should: "fail")
- "the organs gives way" (should: "give way")
- "the claws glances off" (should: "glance off")
- "the teeth fails to bite" (should: "fail")
**Verdict:** ❌ FAIL
**Bug:** BUG-194 — Pervasive subject-verb disagreement in combat narration. Plural nouns paired with singular verbs.

---

### T-012: Garbled spider bite narration
**Input:** `hit spider` / `attack spider` (multiple sessions)
**Response samples:**
- `A large brown spider sinks its fangs into toward someone's knee; the teeth fails to bite.` — "into toward" is garbled
- `The tooth-enamel skitters off someone's shin as A large brown spider sinks its fangs into.` — "into." is incomplete; "tooth-enamel" is material name leaking; capital "A" mid-sentence
**Verdict:** ❌ FAIL
**Bug:** BUG-195 — Spider bite narration has broken string interpolation: dangling prepositions, incomplete sentences, material-name leaking into prose, mid-sentence capitalization.

---

### T-013: Spider body zone mismatch
**Input:** `attack spider` (multiple sessions)
**Response samples:** Combat references spider's "knee", "thigh", "shin", "ribs", "haunch" — none of which exist on a spider. Spider body tree defines: cephalothorax, abdomen, legs.
**Verdict:** ❌ FAIL
**Bug:** BUG-196 — Combat system generates human body zones for spider targets instead of using creature-specific body tree. Spider has cephalothorax/abdomen/legs but combat narrates hits to knee/thigh/shin/ribs.

---

### T-014: Combat verb synonyms — "kill", "slay", "murder"
**Input:** `kill rat` / `slay rat` / `murder rat`
**Response:** All return "I'm not sure what you mean."
**Verdict:** ❌ FAIL
**Bug:** BUG-197 — "kill", "slay", "murder" are natural player combat words not mapped to attack verb. Also: "stab rat" only allows self-harm ("You can only stab yourself"), "cut rat" blocked ("You can't cut a brown rat"), "slash rat" unrecognized.

---

### T-015: Article stripping inconsistency
**Input:** `look the rat` vs `attack the rat` vs `look at the rat`
**Response:**
- "look the rat" → "You don't notice anything called that nearby." ❌
- "attack the rat" → Engages combat ✅
- "look at the rat" → Shows description ✅
- "look the brown rat" → Fails ❌
- "look at the spider" → Works ✅
**Verdict:** ❌ FAIL
**Bug:** BUG-198 — "look" verb doesn't strip leading article "the" from noun. "attack" verb does. "look at the X" works because "at" preprocessor handles articles. Inconsistent between verbs.

---

### T-016: "look vermin" keyword failure
**Input:** `look vermin` / `look arachnid` / `look rodent`
**Response:**
- "look vermin" → "You don't notice anything called that nearby." ❌
- "look arachnid" → Shows spider description ✅
- "look rodent" → Shows rat description ✅
**Verdict:** ❌ FAIL
**Bug:** BUG-199 — "vermin" is a registered keyword for rat but fails to resolve. "rodent" and "arachnid" work fine.

---

### T-017: Dead rat corpse spoilage speed
**Input:** `attack rat` → `look dead rat` → `examine dead rat` → `feel dead rat`
**Response (3 consecutive commands):**
1. "The rat's body has swollen, its belly distended with gas." (bloated state)
2. "The rat is a putrid mess of matted fur and exposed tissue." (rotten state)
3. "Tiny, fragile bones. They click together." (bones state)
**Verdict:** ❌ FAIL
**Bug:** BUG-200 — Spoilage FSM advances through ALL states (fresh→bloated→rotten→bones) in 3 commands. Design spec: fresh=30s, bloated=40s, rotten=60s (total 130s). Timer appears to tick per command/look rather than per game second.

---

### T-018: Disambiguation — "look creature" vs "attack creature"
**Input:** `look creature` / `attack creature` (both creatures alive)
**Response:**
- "look creature" → "Which do you mean: a large brown spider or a brown rat?" ✅ Disambiguation!
- "attack creature" → Silently attacks first creature (rat) without asking ❌
**Verdict:** ⚠️ WARN
**Bug:** BUG-201 — "attack creature" with ambiguous target doesn't prompt for disambiguation like "look creature" does. Inconsistent verb behavior. Player could accidentally attack the wrong creature.

---

### T-019: Sensory detection — feel around in cellar
**Input:** `feel around` (in cellar)
**Response:**
```
You reach out in the darkness, feeling around you...
  an old barrel
  an iron torch bracket
  an open trap door and stone stairway
  a heavy iron-bound door
  a large brown spider
  an iron brazier
  a brown rat
```
**Verdict:** ✅ PASS — Both creatures detectable by touch. All room objects listed. Excellent for dark navigation.

---

### T-020: Sensory detection — smell in cellar
**Input:** `smell` (room ambient)
**Response:** Lists barrel, trapdoor, door, spider, brazier, knife smells. Rat NOT listed.
**Input:** `smell rat` (direct target)
**Response:** `Musty rodent — damp fur, old nesting material, and the faint ammonia of urine.`
**Verdict:** ⚠️ WARN
**Bug:** BUG-202 — Ambient "smell" room scan doesn't include rat (but does include spider). Direct "smell rat" works. Similarly, ambient "listen" doesn't include rat but "listen to rat" works. Rat may be excluded from ambient scans due to wander state.

---

### T-021: Sensory targeting — all senses on both creatures
**Input:** `feel rat` / `feel spider` / `smell rat` / `smell spider` / `listen to rat` / `listen to spider` / `taste rat` / `taste spider` / `touch rat` / `touch spider`
**Response:** All 10 commands return appropriate, unique, atmospheric sensory text:
- Feel rat: "Coarse, greasy fur over a warm, squirming body. A thick tail whips against your fingers. It bites."
- Feel spider: "You brush sticky silk. Something large moves nearby. Hard, bristled legs scramble across your hand."
- Smell rat: "Musty rodent — damp fur, old nesting material, and the faint ammonia of urine."
- Smell spider: "A faint, musty odor — old silk and dry insect husks."
- Listen rat: "Skittering claws on stone. An occasional high-pitched squeak."
- Listen spider: "Faint scratching, like tiny claws on stone."
- Taste rat: "You'd have to catch it first. And then you'd regret it."
- Taste spider: "Bitter chitin and a sharp, chemical sting on your tongue."
- Touch rat/spider: Maps to feel, works correctly.
**Verdict:** ✅ PASS — All 5 senses work for both creatures with distinct, atmospheric descriptions. Excellent sensory design.

---

### T-022: Combat with both creatures — kill sequence
**Input:** `attack rat` → `attack spider` (sequential, same session)
**Response:** Rat dies in 1 hit. Spider takes 2-3 rounds, fights back with venom. Spider venom causes progressive numbness ("Sharp pain flares from the bite. A burning numbness begins to spread.") and can kill the player.
**Verdict:** ✅ PASS — Both creatures are independently targetable and fightable. Spider is significantly more dangerous than rat (venom). Combat works for sequential kills.
**Note:** "a brown rat is dead!" / "a large brown spider is dead!" — lowercase 'a' (BUG-203)

---

### T-023: Death message capitalization
**Input:** Kill any creature
**Response:** `a brown rat is dead!` / `a large brown spider is dead!`
**Verdict:** ❌ FAIL
**Bug:** BUG-203 — Death announcement starts with lowercase article. Should capitalize: "A brown rat is dead!"

---

## Summary of Findings

### What Works Well
- Both rat and spider coexist in cellar ✅
- Room descriptions mention both creatures with atmospheric presence text ✅
- All 5 senses (feel, smell, listen, taste, touch) work for both creatures with distinct text ✅
- "feel around" detects both creatures in darkness ✅
- Rat stimulus system works — rat flees when spider is attacked ✅
- "look creature" prompts disambiguation when multiple creatures present ✅
- Combat targeting with "attack rat" / "attack spider" works ✅
- Spider venom system works — progressive numbness, can kill player ✅
- Dead rat corpse can be picked up and carried ✅
- Keyword synonyms work: "rodent" → rat, "arachnid" → spider ✅

### What's Broken
- Spider doesn't react to rat combat (asymmetric stimulus, BUG-192)
- Combat narration uses "Someone" instead of "You" (BUG-193)
- Pervasive grammar errors in combat text (BUG-194)
- Spider bite text is garbled/incomplete (BUG-195)
- Spider gets human body zones in combat (BUG-196)
- "kill/slay/murder" not recognized (BUG-197)
- Article "the" not stripped by look verb (BUG-198)
- "vermin" keyword doesn't resolve (BUG-199)
- Corpse spoilage runs at warp speed (BUG-200)
- "attack creature" skips disambiguation (BUG-201)

---

**Sign-off:** Nelson, 2026-03-28. Multi-creature coexistence is functionally working but combat narration needs significant polish.
