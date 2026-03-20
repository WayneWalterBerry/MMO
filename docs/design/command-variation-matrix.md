# Command Variation Matrix

**Version:** 1.0  
**Author:** Comic Book Guy (Game Designer)  
**Date:** 2026-03-22  
**Purpose:** Define natural language variations for all 31 verbs in the MMO engine, for training the embedding-based parser (Tier 2).

---

## Overview

This matrix documents what players will actually type for each verb in the game. It serves two purposes:

1. **Training data:** Variations feed into Bart's Python script to generate embedding training data.
2. **QA validation:** After deployment, these variations validate that the embedding matcher correctly maps natural language back to verbs.

For each verb, this document includes:
- The **canonical form** (how the code recognizes it)
- **Synonyms** (directly supported by engine aliases)
- **Natural language variations** (10-20 per verb) — what real players type
- **Edge cases and ambiguities** — tricky inputs that need handling
- **Context-sensitive variations** — changes based on game state (darkness, tools available, etc.)

---

## NAVIGATION & PERCEPTION VERBS

### LOOK
**Canonical:** `look [at {object}]`  
**Synonyms:** see (thematic, maps to look)  
**Aliases in code:** (none — look is primary)

**Variations:**
- "look" — look around the room
- "look around"
- "look at the {object}"
- "look at {object}"
- "examine the room"
- "get my bearings"
- "see what's here"
- "what do I see?"
- "describe the room"
- "glance around"
- "scan the room"
- "look carefully"
- "look for {object}"
- "look in this direction"
- "what's in this room?"
- "look around me"

**Edge cases:**
- "look" (no object) → room description (this is the primary use case)
- "look at nothing" → should gracefully fail or print generic response
- "look at the {non-existent}" → "You don't see that here."
- "look it" → pronoun resolution: last examined/mentioned object?

**Context-sensitive:**
- **In darkness:** Room description includes "You can't see anything. Darkness fills the space." Exits may still be listed if they're tactile (feel a wall, a door frame).
- **With light source:** Full sensory description including colors, details, visible exits.
- **After FEEL:** Player has tactile memory of room layout, so look might be faster/smoother mentally.

---

### EXAMINE
**Canonical:** `examine {object}`  
**Synonyms:** x, find, inspect  
**Aliases in code:** x (examine), find (examine)

**Variations:**
- "examine {object}"
- "examine the {object}"
- "x {object}" — power-user shorthand
- "x the {object}"
- "look at the {object}" — delegates to LOOK
- "inspect {object}"
- "inspect the {object}"
- "look closer at {object}"
- "study {object}"
- "study the {object}"
- "check {object}"
- "what is this {object}?"
- "describe {object}"
- "find {object}" — contextual, can mean search
- "look inside {object}" — when object is a container
- "get a better look at {object}"
- "focus on {object}"
- "check out {object}"

**Edge cases:**
- "examine nothing" → fails gracefully
- "examine" (no object) → "Examine what?"
- "examine room" or "examine around" → delegates to LOOK
- "examine it" → pronoun resolution (last looked-at object)
- "x x" (abbreviation of abbreviation) → malformed, fail
- "examine {container}" → shows contents if open/transparent

**Context-sensitive:**
- **In darkness:** If object has no light source, only sensory descriptions (feel, smell, taste, listen) are available. LOOK shows "too dark to see details."
- **With light:** LOOK shows full visual description including colors and fine details.
- **After FEEL:** Player already knows texture, so redundant info is skipped.

---

### READ
**Canonical:** `read {object}` — delegates to EXAMINE  
**Synonyms:** (none — read is primary for written text)  
**Aliases in code:** (READ handler delegates to EXAMINE with special handling for written_text field)

**Variations:**
- "read {object}"
- "read the {object}"
- "read this"
- "read it"
- "what does it say?"
- "look at the text"
- "examine the text"
- "read the writing"
- "read the inscription"
- "read the label"
- "read the note"
- "read the page"
- "read aloud"
- "check the text"
- "decipher {object}"
- "read the lines"

**Edge cases:**
- "read" (no object) → "Read what?"
- "read wall" or "read air" → non-readable object → "There's nothing to read there."
- "read it" (no previous object in context) → "It what? Be more specific."
- "read something" → ambiguous → "Which object?"
- "read the whole book" → reads all pages (if book has multiple pages)
- "read the inscription" on poison bottle → shows skull-and-crossbones label (visual, requires light)

**Context-sensitive:**
- **In darkness:** "You can't see anything to read. Perhaps you could use another sense?"
- **With light:** Full text visible.
- **On written_text field:** If object has player-written text, READ returns it verbatim. This is the critical mechanic for persisting player actions (blood-written messages, pen-written notes).

---

### SEARCH
**Canonical:** `search {object}` — delegates to EXAMINE or LOOK  
**Synonyms:** (none — search is primary for containers)  
**Aliases in code:** (SEARCH delegates to EXAMINE for target, or LOOK for room)

**Variations:**
- "search {object}"
- "search the {object}"
- "search around"
- "search the room"
- "look around for {object}"
- "search for {object}"
- "find {object}" — if FIND verb delegates to EXAMINE
- "look inside {object}"
- "peek inside {object}"
- "check inside {object}"
- "rummage through {object}"
- "explore {object}"
- "search in {object}"
- "search this container"
- "search the drawer"
- "search the nightstand"
- "search everywhere"
- "shake down {object}" — aggressive search

**Edge cases:**
- "search" (no object) → defaults to LOOK (search room)
- "search {non-container}" → "There's nothing inside that to search."
- "search {closed-container}" → "It's closed. Maybe open it first?" or enumerate contents anyway (design choice)
- "search this" (referring to last object) → works if last object is container
- "search for a needle in a {container}" → looks in that container for needle

**Context-sensitive:**
- **Containers open/closed:** If container is closed, search might fail or give blind results (feel, sound, smell only).
- **Darkness:** If searching by feel only, can find items but not see them clearly.
- **After FEEL:** Player has tactile sense of what's inside, so search gives faster/better results.

---

### FEEL
**Canonical:** `feel [at|around|{object}]`  
**Synonyms:** touch, grope  
**Aliases in code:** touch (feel), grope (feel)

**Variations:**
- "feel" — feel around the room (tactile survey)
- "feel around"
- "feel around me"
- "feel the {object}"
- "feel the {surface}"
- "touch {object}"
- "touch the {object}"
- "touch around"
- "grope around"
- "grope for {object}"
- "grope the {object}"
- "run my fingers over {object}"
- "feel my way"
- "feel the walls"
- "feel for exits"
- "feel for a door"
- "palpate {object}" — medical term, but some players use it
- "feel the texture"
- "touch and feel"
- "brush my hand against {object}"

**Edge cases:**
- "feel" (no object) → tactile description of the current room/surroundings
- "feel nothing" → "Your fingers find only emptiness."
- "feel it" → last touched object
- "feel for it" → searching by touch
- "feel around for {object}" → search-by-feel variant
- "feel the floor" → tactile description of floor (texture, temperature, obstacles)

**Context-sensitive (CRITICAL for darkness gameplay):**
- **In complete darkness:** FEEL is the PRIMARY sense. Returns detailed tactile description + lists surface zones and container contents (after the Bart fix).
- **With light:** FEEL still works but is redundant with LOOK.
- **After container discovery:** If player has felt a closed drawer, subsequent FEEL provides state (still closed, now ajar, open).
- **On objects with hazards:** If object is hot (lit candle), FEEL warns "It's hot!" with damage/consequence feedback.

**Related:** The FEEL verb now enumerates accessible contents after printing sensory description (engine fix). This is the core mechanic for darkness puzzle solvability.

---

### SMELL
**Canonical:** `smell [at|{object}]`  
**Synonyms:** sniff  
**Aliases in code:** sniff (smell)

**Variations:**
- "smell" — smell around the room
- "smell around"
- "smell the {object}"
- "smell the air"
- "sniff {object}"
- "sniff the {object}"
- "sniff the air"
- "sniff around"
- "catch a whiff of {object}"
- "take a whiff of {object}"
- "smell my way"
- "smell for {object}"
- "smell this"
- "does it smell like anything?"
- "what does it smell like?"
- "get a nose on {object}"
- "inhale near {object}"
- "check the odor"

**Edge cases:**
- "smell" (no object) → ambient room smell (stale air, must, mold in bedroom, etc.)
- "smell nothing" → "You detect no particular odor."
- "smell it" → last examined object
- "smell poison" → critical edge case: poison bottle should smell "acrid and chemical" (warning), NOT the poison itself (player would taste it then, which is deadly)

**Context-sensitive:**
- **In darkness:** SMELL is a safe identification sense (unlike TASTE). Smells work fine in pitch darkness.
- **Poison identification:** Object.on_smell = "Acrid and chemical. Something dangerous." provides the WARNING before TASTE.
- **On containers:** Smelling a closed container might reveal contents: "You smell something metallic" (coins), "You smell matches" (matchbox), etc.
- **Consumable items:** Fresh vs. stale smells indicate if an item is fresh, edible, or dangerous.

**Design note:** SMELL is the safe, non-lethal sense for object identification. It should always be accurate but non-committal: "It smells metallic" not "It's definitely a knife."

---

### TASTE
**Canonical:** `taste [at|{object}]`  
**Synonyms:** lick  
**Aliases in code:** lick (taste)

**Variations:**
- "taste {object}"
- "taste the {object}"
- "taste it"
- "lick {object}"
- "lick the {object}"
- "lick it"
- "put it in my mouth"
- "eat a small bit of {object}"
- "try tasting it"
- "sample {object}"
- "get a taste of {object}"
- "lick my finger and touch {object}" — proxy for TASTE
- "taste the air"
- "taste around"

**Edge cases (CRITICAL — TASTE IS DANGEROUS):**
- "taste" (no object) → "Taste what?" — require explicit object
- "taste nothing" → "There's nothing to taste."
- "taste the ground" or "taste the floor" → "You taste dust and stale earth. Unpleasant." (usually harmless)
- "taste poison bottle" → **IMMEDIATE CONSEQUENCE:** "BITTER! You spit it out. That tasted like poison." → **PLAYER DIES**
- "lick the poison bottle" → same as above
- "taste the candle" → depends on material; wax tastes waxy (not toxic), lit candle tastes burnt and acrid
- "taste everything" → dangerous if multiple objects; should ask for clarification

**Context-sensitive (CRITICAL):**
- **Poison bottle:** on_taste field triggers death. This is intentional game design: TASTE is the "learn by dying" sense.
- **Safe objects:** Pen tastes like plastic, paper tastes papery, wood tastes woody — harmless but not tasty.
- **In darkness:** TASTE works fine. It's actually the primary sense for identifying poison.
- **After SMELL warning:** If player smelled "acrid and chemical," they have a clue that TASTE is dangerous. Smell = warning, Taste = consequence.

**Design note:** TASTE is transgressive and dangerous. It's not the usual adventure game mechanic. It teaches consequence and caution. The poison bottle's deadly TASTE is intentional — it's how players learn "this sense can kill you, be careful."

---

### LISTEN
**Canonical:** `listen [to|{object}]`  
**Synonyms:** hear  
**Aliases in code:** hear (listen)

**Variations:**
- "listen" — listen to the room ambience
- "listen around"
- "listen to {object}"
- "listen to the {object}"
- "hear {object}"
- "hear the {object}"
- "hear anything?"
- "what do I hear?"
- "listen for {object}"
- "listen carefully"
- "put my ear to {object}"
- "press my ear against {object}"
- "eavesdrop on {object}"
- "hear something?"
- "listen out for danger"
- "hear the sounds"
- "listen in"
- "pay attention"

**Edge cases:**
- "listen" (no object) → room ambience (silence, ambient noise, distant sounds)
- "listen to nothing" → "You hear only silence."
- "listen to it" → last examined object
- "listen for danger" → "You hear nothing immediately threatening." or specific sounds if present
- "listen at the door" → "You hear muffled footsteps" or "nothing but silence"

**Context-sensitive:**
- **In darkness:** LISTEN is unaffected by darkness (sound works in pitch black).
- **Mechanical objects:** Lit candle crackles, matchbox rattles if shaken, drawer squeaks if opened slowly.
- **Containers with contents:** "You hear something shifting inside" if container has loose objects.
- **On surfaces:** Mirror might show silence unless reflective (metaphorical), desk might have pages rustling if papers are inside.

**Design note:** LISTEN is the most underused sense in text adventures, but critical for dark-room gameplay. Every object should have an on_listen field even if it's just "silence."

---

## INVENTORY MANAGEMENT VERBS

### TAKE
**Canonical:** `take {object}` or `take {object} from {container}`  
**Synonyms:** get, pick, grab  
**Aliases in code:** get (take), pick (take), grab (take)

**Variations:**
- "take {object}"
- "take the {object}"
- "take this {object}"
- "grab {object}"
- "grab the {object}"
- "pick up {object}"
- "pick up the {object}"
- "get {object}"
- "get the {object}"
- "pick {object} up" — verb-particle order
- "grab the {object} up"
- "take {object} from {container}"
- "get {object} out of {container}"
- "take {object} off {surface}"
- "grab {object} off {surface}"
- "snatch {object}"
- "snatch the {object}"
- "collect {object}"
- "take it"
- "grab this"
- "snag {object}"

**Edge cases:**
- "take" (no object) → "Take what?"
- "take all" → should this work? (design choice: probably "take all {visible-objects}" or "Take what specifically?")
- "take it" (pronoun) → last examined/mentioned object
- "take nothing" → "There's nothing to take there."
- "take the undead wizard" → non-portable object → "You can't take that."
- "take from {non-container}" → "There's nothing inside that to take."
- "take {object} from {wrong-container}" → "That's not in there."
- "take this, this, and this" → multiple objects (parser job)

**Context-sensitive:**
- **Inventory full:** "Your hands are full. Drop something first?"
- **Object too heavy:** "It's too heavy to carry."
- **Object too large:** "It won't fit in your hands."
- **From inside container:** TAKE intelligently routes "take key from drawer" to the correct nested object.
- **From surface of furniture:** "take candle off nightstand" should work even if candle is listed on nightstand's zone.

**Design note:** TAKE is the core inventory verb. Must support "from" syntax for nested objects.

---

### GET
**Canonical:** Alias to TAKE  
**Synonyms:** (GET is itself a synonym)  
**Aliases in code:** GET delegates to TAKE

**Variations:**
- Everything listed under TAKE applies.
- "get {object}" is the most common natural language form.
- "get {object} from {container}" — very common in real player input.
- "get me a {object}" — would need to be parsed as "get {object}" (informal speech)

**Context-sensitive:**
- Same as TAKE.

---

### PICK
**Canonical:** Alias to TAKE (with "up" implicit)  
**Synonyms:** (PICK is itself a synonym)  
**Aliases in code:** PICK delegates to TAKE

**Variations:**
- "pick {object}" — colloquial for "pick up"
- "pick the {object}" — colloquial
- "pick up the {object}" — standard
- "pick {object} up" — verb-particle order (both orders supported)

**Edge cases:**
- "pick" (no object) → "Pick up what?"
- "pick it up" → standard usage, pronoun works

**Context-sensitive:**
- Same as TAKE.

**Note on tool verb PICK:** This PICK is inventory. A separate PICK LOCK verb exists (tool verb, requires lockpicking skill). The parser must distinguish "pick up {object}" from "pick lock {container}".

---

### GRAB
**Canonical:** Alias to TAKE  
**Synonyms:** (GRAB is itself a synonym)  
**Aliases in code:** GRAB delegates to TAKE

**Variations:**
- "grab {object}" — informal, urgent tone
- "grab the {object}" — standard
- "grab this" — pronoun
- "quickly grab {object}" — speed modifier (ignored by engine, but natural player language)

**Context-sensitive:**
- Same as TAKE. GRAB works identically to TAKE mechanically, but players use it when acting quickly or in panic.

---

### DROP
**Canonical:** `drop {object}`  
**Synonyms:** (none — drop is primary)  
**Aliases in code:** (none — DROP is primary)

**Variations:**
- "drop {object}"
- "drop the {object}"
- "drop this {object}"
- "let go of {object}"
- "release {object}"
- "put down {object}"
- "set down {object}"
- "throw down {object}" — aggressive variant
- "drop it"
- "drop this"
- "leave {object} here"
- "leave {object} behind"

**Edge cases:**
- "drop" (no object) → "Drop what?"
- "drop nothing" → "You're not holding that."
- "drop it" (if not holding it) → "You're not holding that."
- "drop everything" → should drop all hand-held items? (design choice)
- "drop on {surface}" → parser job to handle "drop key on desk" → standard DROP routing

**Context-sensitive:**
- **In water:** Dropped items might float or sink (world state).
- **At height:** Dropped items might fall and break (physics, mutations).
- **In darkness:** "You release the object. You hear it hit the ground." Feedback is tactile/auditory, not visual.

**Design note:** DROP is straightforward. Most edge cases are parser-level distinctions.

---

### INVENTORY
**Canonical:** `inventory` — list all carried items  
**Synonyms:** i  
**Aliases in code:** i (inventory)

**Variations:**
- "inventory"
- "i" — power-user shorthand
- "check inventory"
- "check my inventory"
- "what am I carrying?"
- "show my inventory"
- "what am I holding?"
- "what's in my bag?"
- "list my items"
- "check pockets"
- "check bag"
- "what do I have?"
- "my inventory"
- "status" — meta, might or might not map to inventory

**Edge cases:**
- "inventory {object}" → doesn't make sense, probably ignored
- "i" (alone) → shows inventory
- "i {anything}" → probably ignored as malformed

**Context-sensitive:**
- **In darkness:** Inventory lists items verbally. Player might feel items but not see them.
- **With light:** Inventory lists items with visual descriptions.

**Design note:** Inventory is a meta verb. Variations are mostly shorthand and clarification. No ambiguity here.

---

### PUT
**Canonical:** `put {object} in|on|into {container}`  
**Synonyms:** place  
**Aliases in code:** place (put)

**Variations:**
- "put {object} in {container}"
- "put the {object} in the {container}"
- "put {object} into {container}"
- "put {object} on {surface}"
- "place {object} in {container}"
- "place the {object} on the {surface}"
- "put {object} down on {surface}"
- "stash {object} in {container}"
- "store {object} in {container}"
- "put it in {container}"
- "place it on {surface}"
- "insert {object} into {container}"
- "shove {object} into {container}" — aggressive
- "drop {object} in {container}"
- "put {object} with {other-object}"
- "combine {object} with {other-object}" — thematic for compound actions

**Edge cases:**
- "put" (no object) → "Put what?"
- "put {object}" (no destination) → "Put it where?"
- "put it in nothing" → "There's nothing there to put it in."
- "put {object} in {wrong-container}" → depends on whether object exists in that context
- "put {object} on {non-surface}" → "You can't put it there."
- "put {object} in a locked container" → depends on whether container is open

**Context-sensitive:**
- **Container open/closed:** Closed containers shouldn't accept PUT unless explicitly designed to accept items from top (like mailslots).
- **Container full:** "The container is full. You can't fit it in."
- **Object wrong size:** "It's too large to fit inside."
- **Object wrong type:** "It won't fit there." (e.g., trying to put a bed on a table)

**Design note:** PUT is more complex than TAKE because it requires two objects and two locations. Parser must handle "from" and "to" relationships.

---

### OPEN
**Canonical:** `open {container}` or `open {exit}`  
**Synonyms:** (none — open is primary)  
**Aliases in code:** (none — OPEN is primary)

**Variations:**
- "open {container}"
- "open the {container}"
- "open this {container}"
- "open {door}"
- "open the {door}"
- "open it"
- "pry open {container}"
- "crack open {container}" — aggressive
- "open up {container}"
- "unseal {container}"
- "undo {container}" — for objects with latches
- "unfasten {container}"
- "unlatch {door}"
- "try to open {container}"

**Edge cases:**
- "open" (no object) → "Open what?"
- "open the {non-container}" → "That doesn't open."
- "open the drawer" (already open) → "It's already open."
- "open locked door" → "It's locked. Do you have a key?"
- "open it" (pronoun) → last mentioned container/door

**Context-sensitive:**
- **Darkness:** "You feel for a seam and pull. The container opens." Feedback is tactile.
- **Locked:** "The lock won't budge." Additional attempt with key shows success.
- **Stuck/jammed:** "It's stuck. You need more force." (or BREAK as alternative)
- **Containers with hazards:** "You open the drawer and feel something soft inside." or "A strong chemical smell rushes out!"

**Design note:** OPEN works for both containers (drawers, boxes, sacks) and exits (doors, trapdoors). Parser must distinguish context.

---

### CLOSE
**Canonical:** `close {container}` or `close {exit}`  
**Synonyms:** shut  
**Aliases in code:** shut (close)

**Variations:**
- "close {container}"
- "close the {container}"
- "close this {container}"
- "close {door}"
- "close the {door}"
- "close it"
- "shut {container}"
- "shut the {container}"
- "shut {door}"
- "shut the {door}"
- "seal {container}"
- "close it up"
- "close the door quietly"
- "close the drawer"

**Edge cases:**
- "close" (no object) → "Close what?"
- "close the {non-container}" → "That doesn't close."
- "close the drawer" (already closed) → "It's already closed."
- "close it" (pronoun) → last mentioned container/door

**Context-sensitive:**
- **In darkness:** "You feel for the container and push. It closes." Feedback is tactile.
- **With light:** Full visual feedback.

**Design note:** CLOSE is the inverse of OPEN. Straightforward.

---

## OBJECT INTERACTION VERBS

### LIGHT
**Canonical:** `light {fire_source}` — requires striker surface (usually requires two objects)  
**Synonyms:** ignite  
**Aliases in code:** ignite (light)

**Variations:**
- "light {candle}"
- "light the {candle}"
- "light it"
- "light {object} with {striker}" — explicit tool variant
- "ignite {object}"
- "ignite the {object}"
- "set {object} on fire"
- "set {object} alight"
- "start a fire"
- "light the room"
- "light the way"
- "create light"
- "use {fire_source} to light {object}"

**Edge cases:**
- "light" (no object) → "Light what?"
- "light {non-fire-source}" → "That won't light."
- "light {candle}" (no striker available) → "You need a striker surface to light that."
- "light a match on nothing" → "There's nowhere to strike it."
- "light a match on matchbox" → core compound action: STRIKE match ON matchbox → match-lit

**Context-sensitive (CRITICAL FOR PUZZLE):**
- **First puzzle (001-light-the-room):** Player must:
  1. FEEL around to find matchbox
  2. OPEN matchbox (or FEEL inside)
  3. TAKE match
  4. STRIKE match ON matchbox → match-lit
  5. Use match-lit to LIGHT candle
- **In darkness:** Starting room is completely dark. LIGHT is the goal. Player must solve by tactile sense (FEEL) first.
- **Fire source states:** Match vs. match-lit vs. burnt-out-match. Only match-lit can light other objects. Match consumes after use.
- **Candle variants:** Lit candle provides light (casts_light=true), provides tool capability (fire_source), and lasts ~X commands before burning out or being consumed.

**Design note:** LIGHT is the critical early-game verb. It's compound (two objects, two actions, one result). The first puzzle teaches: feel → search → take → strike → light. This is core game flow.

---

### STRIKE
**Canonical:** `strike {object1} on|against {object2}` — compound tool verb  
**Synonyms:** (none — strike is specific to compound actions)  
**Aliases in code:** (none — STRIKE is primary)

**Variations:**
- "strike {match} on {matchbox}"
- "strike the {match} on the {matchbox}"
- "strike {match} against {matchbox}"
- "strike it on that"
- "rub {match} on {matchbox}" — thematic
- "friction the {match} on {matchbox}" — uncommon but valid
- "strike a light"
- "strike {object} against {surface}"
- "knock {object} against {surface}"

**Edge cases:**
- "strike" (no object) → "Strike what on what?"
- "strike {object}" (no target) → "Strike it on what?"
- "strike {non-match}" → "You can't strike that."
- "strike {match}" (no matchbox with striker) → "There's nowhere to strike it."
- "strike {match} on {wrong-object}" → "That won't work as a striker."

**Context-sensitive:**
- **Compound action flow:** STRIKE is always a two-object action. Must find both, must have both accessible, must have the right properties (match + striker_surface).
- **Mutation on success:** Match → match-lit. Match-lit has fire_source capability, casts_light, consumable, burn_remaining.
- **Failure state:** Could add "struck-out-match" (bent, won't light again). For now, assume success.
- **In darkness:** "You carefully position the match against the rough striker surface. You feel it ignite, a tiny flame blooming in the darkness." Tactile feedback during discovery.

**Design note:** STRIKE is the linchpin of the first puzzle. It teaches compound actions and tool manipulation. The implementation uses a mutation system: striking a match ON a matchbox transforms the match into a match-lit variant.

---

### EXTINGUISH
**Canonical:** `extinguish {fire_source}`  
**Synonyms:** snuff  
**Aliases in code:** snuff (extinguish)

**Variations:**
- "extinguish {candle}"
- "extinguish the {candle}"
- "extinguish it"
- "snuff {candle}"
- "snuff the {candle}"
- "snuff it out"
- "put out {candle}"
- "put out the {candle}"
- "blow out {candle}"
- "blow out the {candle}"
- "extinguish the flame"
- "douse {candle}"
- "douse the {candle}"
- "kill the flame"
- "dampen {candle}"

**Edge cases:**
- "extinguish" (no object) → "Extinguish what?"
- "extinguish {non-light}" → "There's no flame to extinguish."
- "extinguish {candle}" (already out) → "It's not lit."
- "extinguish it" (pronoun) → last mentioned lit object

**Context-sensitive:**
- **In darkness:** Extinguishing the only light source returns the room to darkness. Feedback: "The light goes out. Darkness returns."
- **Safe action:** Unlike TASTE, extinguishing is safe and encouraged (conserve resources).
- **Future: wind state:** On windy areas, open flames might extinguish automatically (not MVP but consider for design).

**Design note:** EXTINGUISH is the safe counterpart to LIGHT. It's straightforward — no edge cases or danger.

---

### BREAK
**Canonical:** `break {object}`  
**Synonyms:** smash, shatter  
**Aliases in code:** smash (break), shatter (break)

**Variations:**
- "break {object}"
- "break the {object}"
- "break this {object}"
- "smash {object}"
- "smash the {object}"
- "shatter {object}"
- "shatter the {object}"
- "break it"
- "smash it"
- "shatter it"
- "destroy {object}"
- "destroy the {object}"
- "wreck {object}"
- "demolish {object}"
- "break {object} apart"
- "crack {object}"

**Edge cases:**
- "break" (no object) → "Break what?"
- "break {non-breakable}" → "You can't break that."
- "break {already-broken}" → "It's already broken."
- "break {object} with {tool}" → parser should route to BREAK, not a separate verb

**Context-sensitive:**
- **Object mutations:** BREAK checks object's mutations.break table. If present, triggers transformation (mirror → shattered-mirror, spawns glass-shard).
- **Consequences:** Broken objects might be sharp (glass-shard has sharp_tool property), unusable, or more fragile.
- **Container state:** Breaking an open container with contents spills them. Breaking a locked container bypasses the lock.
- **In darkness:** "You swing. There's a crack and something shatters. Debris scatters." Tactile/auditory feedback.

**Design note:** BREAK enables puzzle solutions (forced entry into containers, destroying hazards). Future puzzles will use BREAK as a gate or requirement.

---

### TEAR
**Canonical:** `tear {object}`  
**Synonyms:** rip  
**Aliases in code:** rip (tear)

**Variations:**
- "tear {object}"
- "tear the {object}"
- "tear it"
- "rip {object}"
- "rip the {object}"
- "rip it"
- "tear {object} apart"
- "rip {object} apart"
- "tear {object} up"
- "tear {object} in half"
- "shred {object}"
- "tear the page"
- "tear the cloth"

**Edge cases:**
- "tear" (no object) → "Tear what?"
- "tear {non-tearable}" → "You can't tear that." (e.g., stone, metal)
- "tear {already-torn}" → "It's already torn."
- "tear it to pieces" → TEAR works; multiple pieces might be a design choice (single torn object or multiple torn-piece objects?)

**Context-sensitive:**
- **Paper/cloth:** TEAR creates torn variants or multiple pieces.
- **Mutation:** TEAR checks mutations.tear. Consequence might be destroying a written message (if tear-able paper with text).
- **In darkness:** "You feel the material tear under your grip. Pieces come away in your hands." Tactile feedback.

**Design note:** TEAR is less common than BREAK but important for cloth/paper objects. Future: tearing pages might be a puzzle mechanic.

---

### WRITE
**Canonical:** `write {text} on {paper}` — requires writing instrument  
**Synonyms:** inscribe  
**Aliases in code:** inscribe (write)

**Variations:**
- "write {text} on {paper}"
- "write {text} in the {paper}"
- "write the message"
- "write {text} with {pen}"
- "write {text} using {pen}"
- "inscribe {text} on {paper}"
- "inscribe {text} in the {paper}"
- "pen {text}"
- "jot down {text}"
- "scribble {text}"
- "write my name"
- "write a message"
- "write the instructions"
- "write in blood"
- "write with my blood"
- "write with pen"

**Edge cases (CRITICAL FOR PUZZLE 003):**
- "write" (no text) → "Write what?"
- "write" (no object) → "Write on what?"
- "write {text} with nothing" → "You need a writing instrument."
- "write in blood" → requires prick-self action first to generate blood state. Then WRITE with blood as capability.
- "write {text} on locked paper" → paper shouldn't be locked, but containers might be. WRITE goes to paper inside container if accessible.

**Context-sensitive (CRITICAL):**
- **Pen + paper:** Standard use case. WRITE {text} ON paper (or WITH pen) checks requires_tool="writing_instrument".
- **Blood writing (puzzle 003):** Player must PRICK SELF to enter "bloody" state. Then WRITE accesses blood as writing_instrument. Generated paper has written_text field with player's input.
- **Mutation on write:** WRITE generates a new object (paper-with-writing.lua, file-per-state). Original paper might be discarded or replaced.
- **Persistence:** Written text is stored in written_text field on object. Future READ verb returns verbatim text. This is how player actions persist.
- **In darkness:** "You feel the nib of the pen on paper. You write carefully, hoping you're on the page." Tactile feedback; player doesn't see result until light.

**Design note:** WRITE is core to puzzle 003 (write in blood). It also demonstrates file-per-state mutation: every written paper is a unique object with player-provided text embedded.

---

### CUT
**Canonical:** `cut {object}` — requires sharp tool  
**Synonyms:** slash  
**Aliases in code:** slash (cut)

**Variations:**
- "cut {object}"
- "cut the {object}"
- "cut it"
- "slash {object}"
- "slash the {object}"
- "slash it"
- "cut {object} with {knife}"
- "slice {object}"
- "slice the {object}"
- "carve {object}"
- "cut {rope}" — common variant
- "cut {rope} with {knife}" — explicit tool
- "cut through {object}"
- "cut {object} in half"

**Edge cases:**
- "cut" (no object) → "Cut what?"
- "cut {object}" (no tool) → "You need a sharp tool to cut that."
- "cut {non-cuttable}" → "You can't cut that." (metal, stone)
- "cut {rope}" (with no sharp tool) → "You need a knife."
- "cut {object} with {tool}" (wrong tool) → "That won't cut it."

**Context-sensitive:**
- **Rope cutting:** Rope (portal mechanism in future) can be cut by sharp tool. Mutation: rope → severed-rope (no longer climbs).
- **Cloth cutting:** Cloth → torn-cloth or cloth-scraps.
- **Paper cutting:** Paper → cut-paper or strips.
- **In darkness:** "You feel for the object and position your knife. With a sharp movement, you cut through. It separates." Tactile feedback.

**Design note:** CUT is similar to TEAR but requires a tool. MVP might not use CUT heavily, but it's useful for rope/cloth objects.

---

### SEW
**Canonical:** `sew {object}` — requires needle + thread; future: requires sewing skill  
**Synonyms:** stitch, mend  
**Aliases in code:** stitch (sew), mend (sew)

**Variations:**
- "sew {object}"
- "sew the {object}"
- "sew it"
- "stitch {object}"
- "stitch the {object}"
- "stitch it up"
- "mend {object}"
- "mend the {object}"
- "fix {object}" — thematic but might map to generic repair (not just sewing)
- "repair {object}" — generic
- "sew {object} with {needle}"
- "stitch using needle and thread"
- "repair the cloth"
- "patch the hole"
- "darn the sock"

**Edge cases:**
- "sew" (no object) → "Sew what?"
- "sew {non-sewable}" → "You can't sew that."
- "sew {object}" (no needle or thread) → "You need a needle and thread to sew."
- "sew {object}" (failed attempt) → failure state: tangled-thread (consumed), sewing attempt fails

**Context-sensitive (PUZZLE 002 CANDIDATE):**
- **Compound action:** SEW requires both needle AND thread. Both must be in inventory or accessible.
- **Skill gating (future):** Sewing without skill causes tangled-thread failure. With skill, success.
- **Mutations:** sew-fails-tangled-thread (consumes thread, doesn't fix object). sew-succeeds (fixes object, consumes thread or leaves needle).
- **In darkness:** "You work carefully with needle and thread. You feel the fabric under your fingers, following the seam." Tactile guidance.

**Design note:** SEW is a compound action like STRIKE. It requires finding needle + thread and having both accessible. Sewing failure teaches consequence (tangled thread is consumed). This enables a puzzle: "Fix the cloth to access hidden item."

---

### PRICK
**Canonical:** `prick {object}` or `prick self` — special case for blood  
**Synonyms:** (none — prick is specific)  
**Aliases in code:** (none — PRICK is primary)

**Variations:**
- "prick {object}"
- "prick the {object}"
- "prick it"
- "prick myself"
- "prick my finger"
- "prick myself with {needle}"
- "wound myself"
- "draw blood"
- "cut myself" — thematic but might map to PRICK
- "puncture {object}"
- "pierce {object}"

**Edge cases (CRITICAL FOR PUZZLE 003):**
- "prick" (no object) → "Prick what?"
- "prick self" → special case: player takes damage (5 HP?), enters bloody state, blood becomes writing_instrument capability
- "prick self" (already bloody) → "You're already bleeding." or allows re-pricking for more blood
- "prick {object}" (no prick tool) → "You need a sharp object to prick that."
- "prick self" (no needle or sharp object) → "You need something sharp to prick yourself with."

**Context-sensitive (PUZZLE 003: WRITE IN BLOOD):**
- **Self-pricking (PRICK SELF):** Costs 5 HP, enters "bloody" state, gives temporary writing_instrument capability.
- **Consequence teaching:** Blood writing is transgressive (health cost, permanent mark, unusual mechanic). This teaches: consequences are real, actions matter.
- **After prick self:** Player can WRITE using blood as tool. Blood-written text is permanent and vivid.
- **Duration:** Bloody state might persist for N commands (player can write multiple messages while bleeding) or clear after first WRITE.
- **Visual:** In darkness, player feels blood. In light, player sees it on hands/paper.

**Design note:** PRICK SELF is a transgressive mechanic that teaches consequence. It's not required to solve any puzzle (alternative exists: use pen + paper), but it's more impactful. Design philosophy: "Blood is the ultimate commitment to your message."

---

### WEAR
**Canonical:** `wear {object}` — equip to worn slot  
**Synonyms:** don  
**Aliases in code:** don (wear)

**Variations:**
- "wear {object}"
- "wear the {object}"
- "wear it"
- "put on {object}"
- "put the {object} on"
- "don {object}"
- "don the {object}"
- "equip {object}"
- "equip the {object}"
- "slip on {object}"
- "put {object} on"

**Edge cases:**
- "wear" (no object) → "Wear what?"
- "wear {non-wearable}" → "You can't wear that."
- "wear {already-worn}" → "You're already wearing that."
- "wear {object}" (worn slot full) → "You're already wearing something."

**Context-sensitive:**
- **Inventory model:** WEAR moves item from hand → worn slot. Worn items don't take hand slots but are still "carried." Future design: worn items might provide passive effects (armor, comfort, tool access).
- **In darkness:** "You feel the material and adjust it on your body." Tactile feedback.

**Design note:** WEAR is straightforward. MVP focus: just move item to worn slot. Future: worn items might provide capabilities or passives.

---

### REMOVE
**Canonical:** `remove {object}` — remove from worn slot  
**Synonyms:** take off  
**Aliases in code:** (none — REMOVE is primary; "take off" is parser job)

**Variations:**
- "remove {object}"
- "remove the {object}"
- "remove it"
- "take off {object}"
- "take the {object} off"
- "take off the {object}"
- "doff {object}"
- "slip off {object}"
- "un-wear {object}"

**Edge cases:**
- "remove" (no object) → "Remove what?"
- "remove {not-worn}" → "You're not wearing that."
- "remove it" (pronoun) → last mentioned worn item

**Context-sensitive:**
- **Inventory model:** REMOVE moves item from worn → hand slots. If hands full, fails.
- **In darkness:** "You peel off the material. It comes away in your hands." Tactile feedback.

**Design note:** REMOVE is the inverse of WEAR. Straightforward.

---

### EAT
**Canonical:** `eat {object}` — consume edible object  
**Synonyms:** consume, devour  
**Aliases in code:** consume (eat), devour (eat)

**Variations:**
- "eat {object}"
- "eat the {object}"
- "eat it"
- "consume {object}"
- "consume the {object}"
- "devour {object}"
- "devour the {object}"
- "chew {object}"
- "bite {object}"
- "take a bite"
- "taste and eat"
- "gobble {object}"
- "eat the food"
- "drink {water}" — special case for drinkable

**Edge cases:**
- "eat" (no object) → "Eat what?"
- "eat {non-edible}" → "That's not edible."
- "eat poison bottle" → "You shouldn't eat that." or allow and trigger poison death? (design choice: probably prevent or warn)
- "eat {already-eaten}" → "It's gone."

**Context-sensitive:**
- **Future feature:** Food/water restores HP or provides buffs. Not MVP.
- **Poisoned items:** Items can have poison tags that trigger on EAT. Poison bottle should NOT be eatable (even though it's tasteable). Different.
- **In darkness:** "You feel the food and eat it. It's... " + sensory description.

**Design note:** EAT is scaffolding for future survival mechanics. MVP might not use it heavily.

---

### BURN
**Canonical:** `burn {object}` — set to fire using fire source; related to LIGHT  
**Synonyms:** (none — burn is specific)  
**Aliases in code:** (none — BURN is primary)

**Variations:**
- "burn {object}"
- "burn the {object}"
- "burn it"
- "set {object} on fire"
- "set {object} alight"
- "ignite {object}" — delegates to LIGHT?
- "burn {object} with {flame}"
- "burn {object} in flame"
- "incinerate {object}"

**Edge cases:**
- "burn" (no object) → "Burn what?"
- "burn {non-burnable}" → "That won't burn."
- "burn {already-burnt}" → "It's already burnt."
- "burn {object}" (no fire) → "You need a fire source to burn that."

**Context-sensitive:**
- **Fire mechanics:** Objects can have burnable property. BURN consumes fire source and object (or both).
- **Mutation:** burn-able object → burnt-object (possibly with spawns like ash).
- **Related to LIGHT:** BURN might be an extended action or delayed effect of LIGHT.

**Design note:** BURN is less frequently used than LIGHT. Clarify design: Is BURN a separate action or shorthand for LIGHT + time? For MVP, probably both work identically.

---

## COMPOUND & FUTURE TOOL VERBS

### PICK LOCK
**Canonical:** `pick lock {object}` or `pick {lock}` — requires lockpicking skill + lockpick tool  
**Note:** This is NOT the PICK from PICK UP. Distinct verb in compound form.  
**Aliases in code:** (none — PICK LOCK is compound, not yet implemented)

**Variations:**
- "pick the lock"
- "pick the lock on {object}"
- "unlock with {pin}" — shorthand, thematic
- "pick lock" (directed at object)
- "unlock the {container}" (if player has pin) — context-sensitive shorthand
- "try to pick the lock"

**Edge cases:**
- "pick lock" (no target) → "Pick the lock on what?"
- "pick lock {unlocked-container}" → "It's not locked."
- "pick lock {object}" (no pin) → "You need a lockpick."
- "pick lock {object}" (no lockpicking skill) → "You have no idea how to do that." or allow prick-failure variant

**Context-sensitive:**
- **Skill requirement:** Lockpicking skill required for guaranteed success. Without skill, failure consumes pin.
- **Pin mutation:** On failed attempt, pin → bent-pin (consumed).
- **In darkness:** "You feel for the lock mechanism. You insert the pin... click! The lock gives way." or "The pin bends. You feel it snap." Tactile feedback of success/failure.

**Design note:** PICK LOCK is a future verb (not MVP). It combines tool (lockpick/pin) + skill (lockpicking) + target (locked object). Design is in player-skills.md.

---

### PUT ON / PUT IN
**Note:** These are variations of PUT, not separate verbs. Handled by PUT with prepositions.

---

## META & SYSTEM VERBS

### HELP
**Canonical:** `help [verb]`  
**Synonyms:** (none — help is primary)  
**Aliases in code:** (none — HELP is primary)

**Variations:**
- "help"
- "help me"
- "what can I do?"
- "help {verb}" — specific help for verb
- "help with {verb}"
- "how do I {verb}?"
- "show me commands"
- "show available verbs"
- "list verbs"
- "?" — meta shorthand

**Edge cases:**
- "help" (no verb) → list all verbs
- "help {verb}" (unknown verb) → "I don't know about that verb."
- "help help" → "HELP: ask for available verbs or specific verb documentation."

**Context-sensitive:**
- **Onboarding:** New player might use HELP early. Should list sensory verbs (FEEL, SMELL, TASTE) as priorities in darkness.
- **Accessibility:** HELP text should be clear and concise.

**Design note:** HELP is scaffolding for player onboarding. Keep help text short and action-oriented.

---

### QUIT
**Canonical:** `quit` or `exit`  
**Synonyms:** exit  
**Aliases in code:** exit (quit)

**Variations:**
- "quit"
- "exit"
- "quit game"
- "exit game"
- "leave"
- "goodbye"
- "bye"
- "q"

**Edge cases:**
- "quit" (mid-action) → "Are you sure you want to quit?" (future: allow with confirmation)
- "quit forever" → parsed as "quit", "forever" ignored

**Context-sensitive:**
- **Persistence:** Quitting saves game state. On re-entry, player resumes.

**Design note:** QUIT is straightforward system verb.

---

## MOVEMENT VERBS

### GO / DIRECTION SHORTHAND
**Note:** Movement is NOT a verb dispatch in the traditional sense. It's handled by exit traversal system (../architecture/room-exits.md).

**Canonical:** `go {direction}` or `{direction}` (shorthand)  
**Directions:** north, south, east, west, up, down, northeast, northwest, southeast, southwest  
**Aliases:** n, s, e, w, u, d, ne, nw, se, sw

**Variations:**
- "go north"
- "go to the {direction}"
- "head north"
- "walk north"
- "move north"
- "travel north"
- "exit north"
- "leave north"
- "north" — shorthand
- "n" — power-user abbreviation
- "go up"
- "go down"
- "climb up"
- "climb down"
- "descend"
- "ascend"
- "go northwest"

**Edge cases:**
- "go" (no direction) → "Go which way?"
- "go north" (no exit) → "You can't go north."
- "go north" (exit locked) → "The door is locked."
- "go north" (exit hidden) → "You don't see any way to go north."
- "go where {exit}" → depends on exit keywords
- "north" (shorthand, no exit) → "You can't go north."

**Context-sensitive:**
- **Exit visibility:** Hidden exits don't appear in LOOK or HELP. Player must discover them.
- **Exit constraints:** Player must fit through exit, carry weight/size constraints. Objects might not fit.
- **In darkness:** "You move cautiously into the darkness. (You arrive in [room]). The darkness here feels different." Sensory feedback of arrival.
- **Traversal validation:** Engine checks exit visibility, accessibility (locked/open), player fit, carry constraints (all five layers from ../architecture/room-exits.md).

**Design note:** Movement is core navigation. Variations are primarily direction shortcuts. Parser job to handle "go X" → extract direction X and validate exit.

---

## SENSORY & CONTEXT VARIATIONS

### DARKNESS CONTEXT (Critical for MVP)

Many verbs have **darkness variants** where visual descriptions are replaced with tactile/auditory equivalents.

| Verb | Normal (Light) | Darkness |
|------|---|---|
| LOOK | "You see a nightstand, small drawer, candle on top..." | "You can't see anything. Darkness fills the space." (after FEEL verb provides structure) |
| EXAMINE | "A wooden nightstand, 2 feet tall, drawer pull visible..." | "Too dark to see details. You could feel it." |
| FEEL | "Smooth wood, cool to touch. You find a drawer handle." | "Smooth wood, cool to touch. Your fingers find a drawer handle." (primary sense) |
| TASTE | "The poison bottle tastes bitter and chemical." | "BITTER! You spit it out." (same, no visual component) |
| READ | "You read: 'WARNING: POISON'" | "You can't read in the dark." |
| LIGHT | "You light the candle. A warm flame blooms." | (triggers puzzle solution, brings light) |
| WEAR | "You put on the backpack." | "You feel for the backpack and slip it on." |

**Key principle:** Darkness is not a wall. It's a different mode of play. Every verb works, but sensory channels change.

---

### TOOL CONTEXT (Critical for compound actions)

Verbs that require tools have **two variants**: with-tool and without-tool.

| Verb | With Tool | Without Tool |
|---|---|---|
| WRITE | "You write 'Hello' on the paper." | "You need a writing instrument." |
| CUT | "You cut the rope with your knife." | "You need a sharp tool." |
| LIGHT | "You light the candle with the match." | "You need a fire source and striker." |
| SEW | "You stitch the cloth closed." | "You need needle and thread." |
| STRIKE | "You strike the match on the matchbox. It ignites!" | "There's nowhere to strike it." |
| PRICK | "You prick yourself with the needle. Blood wells up." | "You need something sharp." |

**Key principle:** Verbs that require tools must have clear feedback about what tool is missing. This guides player exploration (search for the tool) and teaches the resource/capability system.

---

### CONTAINER CONTEXT (Critical for PUT/TAKE/OPEN/CLOSE)

Container states affect verb behavior.

| State | OPEN | CLOSE | PUT | TAKE |
|---|---|---|---|---|
| **Closed** | Works (opens container) | "Already closed." | Blocked (unless hatch/mailslot) | Can take container, not contents |
| **Open** | "Already open." | Works (closes) | Works (puts item inside) | Can take contents |
| **Locked** | "It's locked." | "Already closed and locked." | Blocked | Blocked |
| **Empty** | Shows "empty" or list of zones | N/A | Works, adds item | "There's nothing inside." |
| **Full** | Shows contents | N/A | "Container full." | Works for each item |

---

## EDGE CASES & AMBIGUITY RESOLUTION

### Pronoun Resolution
When player uses "it," "this," "that," the parser must resolve to the last-examined or last-mentioned object.

**Examples:**
- "look at the candle" ... "take it" → takes candle
- "feel around" ... "take it" → takes last-felt object (ambiguous if multiple felt, ask for clarification)
- "examine drawer" ... "open it" → opens drawer
- "take key" ... "drop it" ... "take it again" → takes key

**Implementation:** Track `ctx.last_object` and use for pronoun resolution.

---

### Bare Commands (No Object)
Several verbs require objects. When none is provided, prompt for clarification.

| Verb | Bare | Response |
|---|---|---|
| TAKE | "take" | "Take what?" |
| DROP | "drop" | "Drop what?" |
| EXAMINE | "examine" | "Examine what?" |
| FEEL | "feel" | (works: feel around) |
| SMELL | "smell" | (works: smell around) |
| OPEN | "open" | "Open what?" |
| LIGHT | "light" | "Light what?" |
| WRITE | "write" | "Write what on what?" |

**Implementation:** Check for nil noun in handler, prompt for clarification.

---

### Ambiguous Targets
When multiple objects match the target keyword, clarify.

**Example:**
- Room contains: two matches, matchbox
- "take match" → "Which match? (1) the first match, (2) the second match, (3) the matchbox"

**Implementation:** Parser collects all matches, if count > 1, ask for disambiguation.

---

### Non-Standard Phrasings
Players sometimes use non-standard syntax. Parser should be forgiving.

| Input | Parsed As | Notes |
|---|---|---|
| "I take the key" | TAKE key | "I" prefix ignored |
| "quickly take key" | TAKE key | Adverbs ignored |
| "take the big red key" | TAKE key | Descriptors parsed as part of keyword |
| "take and examine key" | TAKE key + EXAMINE key | Compound command, two turns |
| "take key from drawer" | TAKE key (from drawer) | Parser routes to containment |
| "write HELLO on paper" | WRITE "HELLO" on paper | Text parsed as STRING, not keyword |

---

## TESTING CHECKLIST

For QA phase, validate these variations map correctly to their verbs:

- [ ] **LOOK**: variations map to LOOK handler
- [ ] **EXAMINE**: "x" shorthand works
- [ ] **FEEL**: works in darkness, lists contents after description
- [ ] **SMELL**: safe sense, works in darkness
- [ ] **TASTE**: dangerous sense, triggers poison-bottle death
- [ ] **TAKE**: "grab", "pick up", "get" all work
- [ ] **PUT**: "put X in Y" routes correctly to PUT (not TAKE)
- [ ] **OPEN/CLOSE**: both containers and exits work
- [ ] **STRIKE**: compound action with two objects succeeds
- [ ] **WRITE**: generates file-per-state with player text
- [ ] **PRICK SELF**: enters bloody state, enables blood-write
- [ ] **Movement**: "go north", "n", "north" all route to traversal
- [ ] **Pronouns**: "it" resolves to last-examined object
- [ ] **Darkness**: feedback is sensory, not visual, in pitch-black room
- [ ] **Compound actions**: all two-object actions succeed when tools present, fail gracefully when missing

---

## DESIGN NOTES FOR FUTURE EXTENSIONS

### Commands Not Yet Designed
- **CLIMB** — for ropes, ladders (subsumed by GO + exit types?)
- **PUSH/PULL** — for heavy objects, doors with levers
- **TALK** — for NPC interaction (future)
- **CAST** — for magic spells (future)
- **GIVE** — for trading with NPCs (future)
- **KILL** — for combat (future, if any)
- **SLEEP** — for survival mechanics (future)
- **MEDITATE** — for introspection/lore (future)

### Prepositions & Particles
Current parser likely doesn't handle all prepositions. Future versions should support:
- "put X in/on/into Y"
- "take X from Y"
- "strike X on/against Y"
- "light X with Y"
- "write X with Y"

### Compound Commands
Some players try "take and examine key" or "go north and look around". Parser should either:
1. Queue commands and execute in sequence, or
2. Parse only the first verb

For MVP, option 2 (parse first verb) is simpler.

---

## CONCLUSION

This matrix documents 31 verbs and ~400+ natural language variations. The embedding parser will use these variations to train a model that maps player input to canonical verbs. The key design principles are:

1. **Darkness is playable.** Every verb works in darkness; sensory channels change.
2. **Tools unlock capabilities.** WRITE needs pen, CUT needs knife, LIGHT needs match + matchbox.
3. **Compound actions teach logic.** STRIKE + SEW teach tool combination; consequences (bent pin, tangled thread) teach resource scarcity.
4. **Consequences matter.** TASTE can kill. PRICK costs HP. These teach urgency and commitment.
5. **Pronouns and context matter.** Parser must track last-examined object for "it" resolution and understand container state.

The embedding matcher will validate that all these variations successfully parse back to their canonical verbs, enabling the Tier 2 parser to handle natural player language while staying true to the game's design intent: **a playable, consequence-driven text adventure that works in complete darkness.**


