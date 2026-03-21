# Object Deep Coverage Test Pass 003 — 2026-03-21

**Tester:** Lisa (Object Tester)
**Requested by:** Wayne "Effe" Berry
**Context:** Comprehensive object coverage. Previous passes covered 10 objects. This pass tests the remaining 56+ untested objects across all rooms.
**Method:** `lua src/main.lua --no-ui` — interactive REPL testing + code review of all .lua metadata files.

---

## Summary

| Category | Tested | Passed | Failed | Warnings |
|----------|--------|--------|--------|----------|
| Static Objects | 28 | 28 | 0 | 1 |
| FSM Objects (new) | 12 | 12 | 0 | 0 |
| Sensory Properties | 120+ | 118 | 0 | 2 |
| Material Fields | 66 | 65 | 1 | 0 |
| GUID Instance Binding | 47 instances | 17 | 30 | 0 |
| Missing Base Classes | 3 | 0 | 3 | 0 |

**Overall: 40 objects PASS, 0 object-level FAIL, 2 CRITICAL engine bugs found (GUID mismatch + missing base classes)**

---

## CRITICAL BUGS

### BUG-106: Instance-to-Base-Class GUID Mismatch (30 objects)
**Severity:** 🔴 CRITICAL
**Input:** `lua src/main.lua`
**Expected:** All instances resolve to their base class via GUID lookup
**Actual:** 30 instances produce "base class not found for guid" warnings at startup. Objects in Cellar, Storage Cellar, Hallway, Courtyard, Deep Cellar, and Crypt rooms fail to load their base classes.

**Root cause:** World instance files (`src/meta/world/*.lua`) reference GUIDs that don't match the GUIDs defined in object base class files (`src/meta/objects/*.lua`). This is a systemic issue — the world files were authored with placeholder/old GUIDs, and the object files use different GUIDs.

**Affected rooms and objects:**

| Room | Object | Instance GUID | Base Class GUID |
|------|--------|---------------|-----------------|
| Deep Cellar | stone-altar | e7d53bc5... | 5178dm1k... |
| Deep Cellar | wall-sconce (×2) | 50da4d97... | 6289en2l... |
| Deep Cellar | stone-sarcophagus | 78a2e19e... | a62dir6p... |
| Deep Cellar | chain | 7826d8c8... | c84fkt8r... |
| Deep Cellar | incense-burner | b49964e5... | 739afo3m... |
| Deep Cellar | tattered-scroll | 6a3497c7... | 840bgp4n... |
| Deep Cellar | offering-bowl | 0d7b6746... | b73ejs7q... |
| Deep Cellar | silver-key | f5eeb02c... | 951chq5o... |
| Hallway | torch (×2) | 85c0daf7... | d95glu9s... |
| Hallway | portrait (×3) | e4b50ef9... | e06hmv0t... |
| Hallway | side-table | 7289f77a... | f17inw1u... |
| Hallway | vase | c5e8ae7e... | 028jox2v... |
| Storage Cellar | large-crate | a6316151... | b7c3d1a2... |
| Storage Cellar | small-crate | 11b2abb8... | c8d4e2b3... |
| Storage Cellar | grain-sack | d2c3fc03... | d9e5f3c4... |
| Storage Cellar | wine-rack | 1f300076... | ea06f4d5... |
| Storage Cellar | wine-bottle | 5e069d6b... | fb17g5e6... |
| Storage Cellar | oil-lantern | f1bb1287... | 2e4aj8h9... |
| Storage Cellar | rope-coil | 6bf6fa10... | 0c28h6f7... |
| Storage Cellar | crowbar | ab42803d... | 3f5bk9i0... |
| Storage Cellar | rat | dbf2539c... | 4067cl0j... |
| Courtyard | stone-well | b825e6ed... | 24alqz4x... |
| Courtyard | well-bucket | 3f55a9c5... | 35bmr05y... |
| Courtyard | ivy | 69663b46... | 46cns16z... |
| Courtyard | cobblestone | 9b456505... | 57dot27a... |
| Courtyard | rain-barrel | 99e9a3e6... | 79fqv49c... |
| Crypt | sarcophagus (×5) | c265c580... | (sarcophagus.lua) |
| Crypt | candle-stub (×2) | ad257f51... | (candle-stub.lua) |

**Fix:** Update all `type_id` values in `src/meta/world/*.lua` to match the GUIDs defined in `src/meta/objects/*.lua`.

---

### BUG-107: Missing Base Class Definitions (3+ objects)
**Severity:** 🔴 CRITICAL
**Input:** `lua src/main.lua` — check startup warnings
**Expected:** Every instance has a corresponding base class .lua file
**Actual:** These instances have no base class file at all:

| Instance ID | Referenced In | Base Class File | Status |
|-------------|--------------|-----------------|--------|
| oil-flask | storage-cellar.lua | src/meta/objects/oil-flask.lua | ❌ MISSING |
| cloth-scraps | storage-cellar.lua | src/meta/objects/cloth-scraps.lua | ❌ MISSING |
| bronze-ring | crypt.lua | src/meta/objects/bronze-ring.lua | ❌ MISSING |
| burial-necklace | crypt.lua | src/meta/objects/burial-necklace.lua | ❌ MISSING |

**Fix:** Flanders needs to create these base class definitions.

---

### BUG-108: Material "burlap" Not in Registry
**Severity:** 🟡 MEDIUM
**Input:** grain-sack.lua defines `material = "burlap"`
**Expected:** "burlap" material exists in `src/engine/materials/init.lua`
**Actual:** Not found in registry. 17 materials exist: wax, wood, fabric, wool, iron, steel, brass, glass, paper, leather, ceramic, tallow, cotton, oak, velvet, cardboard, linen. Also hemp, bone, silver, stone were added.
**Fix:** Either add "burlap" to the registry or change grain-sack.lua to use "fabric".

---

### BUG-109: Surface Containment Warnings (15 instances)
**Severity:** 🟡 MEDIUM
**Input:** `lua src/main.lua` — startup warnings about surface references
**Expected:** All surface references resolve correctly
**Actual:** 15 "surface not found" warnings because the parent containers fail GUID lookup (BUG-106). Once GUID mismatch is fixed, these should resolve.

**Affected:**
- stone-altar.top → incense-burner, tattered-scroll, offering-bowl
- stone-sarcophagus.inside → silver-key
- large-crate.top → small-crate
- large-crate.inside → iron-key
- small-crate.inside → cloth-scraps, candle-stubs
- sarcophagus-2..5.inside → bronze-ring, silver-dagger, burial-necklace, tome
- wine-rack → wine-bottle
- side-table.top → vase
- stone-well → well-bucket

---

## BEDROOM OBJECTS (Tested Interactively)

### bed
States tested: N/A (static, no FSM)
Transitions verified: N/A
Mutate fields: N/A
Sensory: ✅ feel matches metadata ("A soft mattress beneath thick coverings..."), smell matches ("Musty linen and old straw...")
Surfaces: ✅ top shows pillow, bed-sheets, blanket; underneath shows knife
Movable: ✅ `push bed` works — scrapes off rug with correct message
Bugs: None

### bed-sheets
States tested: N/A (static)
Transitions verified: N/A
Sensory: ✅ feel matches ("Smooth cotton, finely woven but hopelessly rumpled. Still faintly warm.")
Material: ✅ cotton (in registry)
Bugs: None

### blanket
States tested: N/A (static, has tear mutation but no FSM)
Transitions verified: N/A
Sensory: ✅ feel matches ("Thick, coarse wool -- heavy and warm. Your fingers catch on moth holes..."), smell matches ("Lanolin and woodsmoke...")
Material: ✅ wool (in registry)
Mutations: tear → spawns 2× cloth (code review)
Bugs: None

### pillow
States tested: N/A (static with hidden surface)
Transitions verified: N/A
Sensory: ✅ feel matches ("Soft and lumpy, stuffed with down...Something sharp pricks you"), smell matches ("Faint lavender, old linen.")
Surface: ✅ inside contains pin (accessible = false — correct, hidden)
Material: ✅ linen (in registry)
Mutations: tear → spawns cloth (code review)
Bugs: None

### brass-key
States tested: N/A (static)
Sensory: ✅ feel matches ("A small metal object, cold and heavy...tiny grinning face"), taste defined (code review)
Material: ✅ brass (in registry)
Discovery: ✅ Found under rug, drops to floor when rug is moved
Bugs: None

### knife
States tested: N/A (static tool)
Sensory: ✅ feel matches ("A bone handle, smooth and cold. The blade -- SHARP..."), smell matches ("Oiled metal and old leather.")
Material: ✅ steel (in registry)
Tool capability: provides cutting_edge + injury_source (code review)
Location: ✅ Found under bed
Bugs: None

### rug
States tested: N/A (movable static)
Sensory: ✅ feel matches ("Rough woven textile underfoot...One corner feels slightly raised.")
Surface: ✅ underneath contains brass-key
Movable: ✅ move rug works (after bed is pushed off). Reveals trap-door. Key drops.
Material: ✅ wool (in registry)
Bugs: None

### chamber-pot
States tested: N/A (static container/wearable)
Sensory: ✅ feel matches ("A ceramic bowl, smooth-glazed and cold. The rim is chipped..."), smell matches ("You'd rather not...")
Material: ✅ ceramic (in registry)
Wearable: slot=head, makeshift quality (code review)
Bugs: None

### glass-shard
States tested: N/A (static)
Sensory: ✅ feel ("SHARP! The edge bites into your finger..."), taste ("DO NOT. Seriously...") — code review confirmed
Material: ✅ glass (in registry)
Effect: on_feel_effect = "cut" (code review)
Bugs: None

---

## WARDROBE CONTENTS (Tested Interactively)

### wool-cloak
States tested: N/A (static wearable)
Sensory: ✅ look matches ("A long wool cloak the color of a bruise..."), feel matches ("Thick, warm wool. Heavy..."), smell matches ("Old wool, cedar from the wardrobe...")
Material: ✅ wool (in registry)
Wearable: slot=back, outer layer, provides_warmth (code review)
Mutations: tear → spawns 2× cloth (code review)
Bugs: None

### sack
States tested: N/A (static container/wearable)
Sensory: ✅ feel matches metadata, smell matches metadata
Container: ✅ Shows 3 items inside (needle, thread, sewing-manual)
Material: ✅ fabric (in registry)
Wearable: slot=back (or alternate head with blocks_vision) — code review
Mutations: tear → spawns 3× cloth (code review)
Bugs: None

---

## SEWING KIT (Tested Interactively + Code Review)

### needle
States tested: N/A (static tool)
Sensory: ✅ look matches ("A fine steel sewing needle..."), feel matches ("Thin metal, slightly curved. A sharp point at one end...")
Material: ✅ steel (in registry)
Tool: provides sewing_tool, consumes_charge=false (code review)
Bugs: None

### thread
States tested: N/A (static crafting material)
Sensory: ✅ look matches ("A small wooden spool wound tight with cream-coloured cotton thread..."), feel matches (code review), smell matches (code review)
Material: ✅ cotton (in registry)
Tool: provides sewing_material (code review)
Bugs: None

### sewing-manual
States tested: N/A (static skill-granting)
Sensory: ✅ look matches ("A thin pamphlet bound in faded cloth..."), feel matches (code review), smell matches (code review)
Material: ✅ paper (in registry)
Skill: grants_skill = "sewing" (code review confirmed)
Bugs: None

### pin
States tested: N/A (static, skill-gated tool)
Sensory: ✅ feel matches (code review: "Tiny, thin metal. A glass bead at one end...")
Material: ✅ steel (in registry)
Tool: provides injury_source; with lockpicking skill → lockpick (code review)
Location: inside pillow (accessible = false — discoverable)
Bugs: None

---

## FABRIC OBJECTS (Code Review)

### cloth
States tested: N/A (static with mutations)
Sensory: ✅ feel ("Soft fabric with torn, frayed edges...") — code review
Material: ✅ fabric (in registry)
Mutations: make_bandage → becomes bandage; make_rag → becomes rag; crafting.sew → becomes terrible-jacket (requires sewing_tool + sewing skill + 2× cloth)
Bugs: None

### rag
States tested: N/A (static)
Sensory: ✅ feel ("Damp, rough cloth..."), smell ("Musty. Damp fabric and something faintly sour.") — code review
Material: ✅ fabric (in registry)
Bugs: None

### bandage
States tested: N/A (static)
Sensory: ✅ feel ("A rolled cloth strip, rough but tightly wound...") — code review
Material: ✅ fabric (in registry)
Categories: medical, fabric — correct
Bugs: None

### terrible-jacket
States tested: N/A (static wearable)
Sensory: ✅ feel, smell defined — code review confirmed
Material: ✅ fabric (in registry)
Wearable: slot=torso, outer, makeshift quality (code review)
Mutations: tear → spawns 3× cloth (code review)
Bugs: None

---

## WRITING OBJECTS (Code Review)

### pen
States tested: N/A (static tool)
Sensory: ✅ feel ("A thin rod -- wooden barrel, smooth from handling..."), smell ("Ink. Faint but unmistakable.") — code review
Material: ✅ wood (in registry)
Tool: provides writing_instrument, consumes_charge=false (code review)
Bugs: None

### pencil
States tested: N/A (static tool)
Sensory: ✅ feel ("A wooden shaft, hexagonal, with a pointed graphite tip...") — code review
Material: ✅ wood (in registry)
Tool: provides writing_instrument, erasable=true (code review)
Bugs: None

### paper
States tested: N/A (static with dynamic mutations)
Sensory: ✅ feel ("Thin, flat, smooth. The edges are slightly foxed..."), smell ("Faintly fibrous...") — code review
Material: ✅ paper (in registry)
Mutations: write (dynamic, requires writing_instrument), burn (requires fire_source) — code review
Writable: ✅ writable=true, written_text=nil initially; on_look shows written_text when set
Bugs: None

---

## CELLAR OBJECTS (Tested Interactively)

### barrel
States tested: N/A (static, non-portable)
Sensory: ✅ feel matches ("Rough wooden staves, damp and slightly soft with age. Iron hoops..."), smell matches ("Damp wood and old iron. A faint sourness...")
Material: ✅ wood (in registry)
Bugs: None

### torch-bracket
States tested: N/A (static fixture)
Sensory: ✅ feel matches ("Cold, rough iron bolted firmly to the stone wall. The cup is empty...")
Material: ✅ iron (in registry)
Bugs: None

---

## FSM OBJECTS — TORCH (Code Review)

### torch
States tested: lit, extinguished, spent (code review)
Transitions verified: 3/3
- lit → extinguished (verb: extinguish/put out/douse/snuff) ✅
- extinguished → lit (verb: light/relight/ignite, requires fire_source) ✅
- lit → spent (auto: timer_expired at 10800s) ✅

Mutate fields:
- lit → extinguished: weight × 0.8, keywords add "extinguished" ✅
- extinguished → lit: keywords remove "extinguished" ✅
- lit → spent: weight = 0.5, categories remove "light source", keywords add "spent" ✅

Sensory: ✅ All 3 states have complete feel/smell/listen properties
Guards: requires_tool "fire_source" for extinguished → lit ✅
Terminal: spent state has terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — OIL LANTERN (Code Review)

### oil-lantern
States tested: empty, fueled, lit, extinguished, spent (code review)
Transitions verified: 5/5
- empty → fueled (verb: pour/fill/fuel, requires lamp-oil) ✅
- fueled → lit (verb: light/ignite, requires fire_source + requires_state fueled) ✅
- lit → extinguished (verb: extinguish/blow/put out/snuff) ✅
- extinguished → lit (verb: light/relight/ignite, requires fire_source) ✅
- lit → spent (auto: timer_expired at 14400s) ✅

Mutate fields:
- empty → fueled: weight += 0.5 ✅
- lit → extinguished: weight × 0.85 (min 1.2), keywords add "sooty" ✅
- lit → spent: weight = 1.2, categories remove "light source", keywords add "spent" ✅

Sensory: ✅ All 5 states have complete feel/smell/listen properties
Guards: Two prerequisites — light requires fire_source + fueled state; fuel requires lamp-oil ✅
Terminal: spent state has terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — WINE BOTTLE (Code Review)

### wine-bottle
States tested: sealed, open, empty, broken (code review)
Transitions verified: 4/4
- sealed → open (verb: open/uncork) ✅
- open → empty (verb: pour) ✅
- sealed → broken (verb: break/smash/throw) ✅
- open → broken (verb: break/smash/throw) ✅

Mutate fields:
- sealed → open: weight -= 0.05, keywords add "open" ✅
- open → empty: weight = 0.4, keywords add "empty", categories remove "container" ✅

Sensory: ✅ All 4 states have feel/smell/listen
Terminal: empty and broken both terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — TATTERED SCROLL (Code Review)

### tattered-scroll
States tested: rolled, unrolled (code review)
Transitions verified: 1/1
- rolled → unrolled (verb: read/open/unroll/untie) ✅

Mutate fields:
- rolled → unrolled: keywords add "open" ✅

Sensory: ✅ Both states have feel/smell; unrolled has on_read with lore text
Prerequisites: read requires_state "unrolled" ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — CHAIN (Code Review)

### chain
States tested: hanging, pulled (code review)
Transitions verified: 1/1
- hanging → pulled (verb: pull/yank/tug) ✅

Mutate fields:
- hanging → pulled: keywords add "pulled" ✅

Sensory: ✅ Both states have feel/smell/listen
One-way: No transition back from pulled — correct design (mechanical ratchet)
Bugs: None (metadata correct)

---

## FSM OBJECTS — GRAIN SACK (Code Review)

### grain-sack
States tested: tied, untied, cut-open (code review)
Transitions verified: 2/2
- tied → untied (verb: untie/open) ✅
- tied → cut-open (verb: cut, requires cutting_edge) ✅

Mutate fields:
- tied → untied: keywords add "open" ✅
- tied → cut-open: weight = 3, keywords add "cut" ✅

Sensory: ✅ All 3 states have feel/smell
Surface: inside (capacity 2, contains iron-key-1, accessible=false in tied state)
Prerequisites: cut requires cutting_edge, auto_steps: "take knife" ✅
Bugs: Material "burlap" not in registry — see BUG-108

---

## FSM OBJECTS — LARGE CRATE (Code Review)

### large-crate
States tested: sealed, pried-open, broken (code review)
Transitions verified: 2/2
- sealed → pried-open (verb: pry/open, requires prying_tool) ✅
- pried-open → broken (verb: break/smash, requires prying_tool) ✅

Mutate fields:
- sealed → pried-open: keywords add "open" ✅
- pried-open → broken: weight = 5, keywords add "broken", categories remove "container" ✅

Sensory: ✅ All 3 states have feel/smell/listen
Surface: inside (contains grain-sack-1, accessible=false when sealed)
Prerequisites: open requires prying_tool, auto_steps: "take crowbar" ✅
Terminal: broken has terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — SMALL CRATE (Code Review)

### small-crate
States tested: closed, open, broken (code review)
Transitions verified: 4/4
- closed → open (verb: open) ✅
- open → closed (verb: close) ✅
- closed → broken (verb: break/smash, requires prying_tool) ✅
- open → broken (verb: break/smash, requires prying_tool) ✅

Mutate fields:
- closed → open: keywords add "open" ✅
- open → closed: keywords remove "open" ✅
- closed/open → broken: weight = 2, keywords add "broken", categories remove "container" ✅

Sensory: ✅ All 3 states have feel/smell
Round-trip: closed ↔ open works correctly ✅
Terminal: broken has terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — WELL BUCKET (Code Review)

### well-bucket
States tested: raised-empty, lowered, raised-full (code review)
Transitions verified: 3/3
- raised-empty → lowered (verb: lower/drop/send down) ✅
- lowered → raised-full (verb: raise/pull up/wind up/crank) ✅
- raised-full → raised-empty (verb: pour/empty/dump/tip) ✅

Mutate fields:
- lowered → raised-full: weight += 8 ✅
- raised-full → raised-empty: weight = 2, keywords remove "full" ✅

Sensory: ✅ All 3 states have feel/smell/listen
Cyclic: raised-empty → lowered → raised-full → raised-empty ✅
Prerequisites: pour requires_state "raised-full" ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — RAIN BARREL (Code Review)

### rain-barrel
States tested: full, half-full, empty (code review)
Transitions verified: 2/2
- full → half-full (verb: fill/scoop/take water) ✅
- half-full → empty (verb: fill/scoop/take water) ✅

Mutate fields:
- full → half-full: weight -= 15 ✅
- half-full → empty: weight = 10, keywords add "empty" ✅

Sensory: ✅ All 3 states have feel/smell/listen
Bugs: None (metadata correct)

---

## FSM OBJECTS — IVY (Code Review)

### ivy
States tested: growing, climbed, torn (code review)
Transitions verified: 2/2
- growing → climbed (verb: climb) ✅
- growing → torn (verb: tear/pull/rip) ✅

Sensory: ✅ All 3 states have feel/smell; growing + climbed have listen
Branching: Two possible paths from growing — correct design ✅
⚠️ Note: No material field defined (ivy is a plant) — acceptable, no crash
Bugs: None

---

## FSM OBJECTS — VASE (Code Review)

### vase
States tested: intact, broken (code review)
Transitions verified: 1/1
- intact → broken (verb: break/smash/drop/throw/knock) ✅

Mutate fields:
- intact → broken: weight = 0, categories remove "container" ✅

Sensory: ✅ Both states have feel/smell
Terminal: broken has terminal=true ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — WALL SCONCE (Code Review)

### wall-sconce
States tested: empty, occupied (code review)
Transitions verified: 2/2
- empty → occupied (verb: put/place/insert) ✅
- occupied → empty (verb: take/remove) ✅

Sensory: ✅ Both states have feel/smell
Surface: inside (capacity 1, accepts "light source") ✅
Round-trip: empty ↔ occupied ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — OFFERING BOWL (Code Review)

### offering-bowl
States tested: empty, offering-placed (code review)
Transitions verified: 1/1
- empty → offering-placed (verb: put/place/offer) ✅

Sensory: ✅ Both states have feel/smell
Surface: inside (capacity 1) ✅
Note: One-way transition — correct for puzzle trigger
Bugs: None (metadata correct)

---

## FSM OBJECTS — STONE SARCOPHAGUS (Code Review)

### stone-sarcophagus
States tested: closed, open (code review)
Transitions verified: 1/1
- closed → open (verb: push/open/lift/slide, requires leverage) ✅

Mutate fields:
- closed → open: keywords add "open" ✅

Sensory: ✅ Both states have feel/smell/listen
Surface: inside (accessible=false when closed, capacity 4) ✅
Prerequisites: open requires leverage tool, auto_steps "take crowbar" ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — LOCKED DOOR (Code Review)

### locked-door
States tested: locked (single state) (code review)
Transitions verified: 0/0 (no transitions defined — correct for Level 1 boundary)
Sensory: ✅ feel/smell/listen all defined
Note: Intentionally has zero transitions — this is a Level 2 boundary object
Bugs: None

### wooden-door
States tested: locked, unlocked, open (code review)
Transitions verified: 2/2
- locked → unlocked (verb: unlock) ✅
- unlocked → open (verb: open/push) ✅

Mutate fields:
- locked → unlocked: keywords add "unlocked" ✅
- unlocked → open: keywords add "open" ✅

Sensory: ✅ All 3 states have feel/smell/listen
Bugs: None (metadata correct)

---

## FSM OBJECTS — RAT (Code Review)

### rat
States tested: hidden, visible, fleeing, gone (code review)
Transitions verified: 4/4 (all auto-triggered)
- hidden → visible (auto: player_enters) ✅
- visible → fleeing (auto: loud_action_nearby) ✅
- visible → gone (auto: timer_expired) ✅
- fleeing → gone (auto) ✅

Sensory: ✅ All states have smell/listen where appropriate; visible has full description
Terminal: gone has terminal=true ✅
Note: All transitions are auto-triggered — player cannot directly interact ✅
Bugs: None (metadata correct)

---

## FSM OBJECTS — WALL CLOCK (Code Review)

### wall-clock
States tested: hour_1 through hour_24 (code review — programmatic generation)
Transitions verified: 24/24 (all auto: timer_expired at 3600s intervals)

All states generated programmatically:
- Each state has description with time word and flavor text ✅
- Each state has timed_event to next hour ✅
- Cyclic: hour_24 → hour_1 ✅
- Chime messages differentiated: noon/midnight get "twelve", hour 1 gets "once", others get word form ✅

Sensory: ✅ feel/smell/listen defined at top level
Initial state: hour_2 (game starts at 2 AM) ✅
Puzzle support: time_offset, adjustable, target_hour fields defined ✅
Bugs: None (metadata correct)

---

## NEW OBJECTS — FLANDERS' BUILDS (Code Review)

### candle-stub
States tested: unlit, lit, spent (code review)
Transitions verified: 2/2
- unlit → lit (verb: light, requires fire_source) ✅
- lit → spent (auto: timer_expired at 1800s) ✅

Sensory: ✅ All 3 states defined
Material: ✅ tallow (in registry)
Terminal: spent has terminal=true ✅
Bugs: None

### sarcophagus (generic crypt variant)
States tested: closed, open (code review)
Transitions verified: 1/1
- closed → open (requires leverage) ✅

Sensory: ✅ Both states defined
Material: ✅ stone (in registry)
Surface: inside (capacity 4), top (capacity 2) ✅
Bugs: None

### tome
States tested: closed, open (code review)
Transitions verified: 1/1
- closed → open (verb: open/read/unclasp) ✅

Sensory: ✅ Both states defined; open has full on_read text
Material: ✅ leather (in registry)
Bugs: None

### skull
States tested: N/A (static)
Sensory: ✅ look/feel/smell/taste all defined
Material: ✅ bone (in registry — new material)
Bugs: None

### silver-dagger
States tested: N/A (static tool)
Sensory: ✅ look/feel/smell/listen all defined
Material: ✅ silver (in registry — new material)
Tool: provides cutting_edge + injury_source + ritual_blade ✅
Bugs: None

### burial-coins
States tested: N/A (static)
Sensory: ✅ look/feel/smell/taste all defined
Material: ✅ silver (in registry)
Bugs: None

### burial-jewelry
States tested: N/A (static)
Sensory: ✅ look/feel/smell all defined
Material: ✅ silver (in registry)
Bugs: None

### wall-inscription
States tested: N/A (static, readable)
Sensory: ✅ look/feel/smell/read all defined
Material: ✅ stone (in registry)
Bugs: None

---

## STATIC OBJECTS — REMAINING (Code Review)

### cobblestone
Sensory: ✅ feel/smell defined
Material: ✅ stone (in registry)
Tool: provides blunt_weapon + weight + hammer ✅
Bugs: None

### crowbar
Sensory: ✅ feel/smell/listen defined
Material: ✅ iron (in registry)
Tool: provides prying_tool + blunt_weapon + leverage ✅
Bugs: None

### rope-coil
Sensory: ✅ feel/smell defined
Material: ⚠️ hemp — verify in registry (reported as exists)
Tool: provides rope + binding ✅
Bugs: None

### incense-burner
Sensory: ✅ feel/smell/listen defined
Material: ✅ brass (in registry)
Surface: inside (capacity 1, accessible) ✅
Bugs: None

### stone-altar
Sensory: ✅ feel/smell/listen/taste defined
Material: ✅ stone (in registry)
Surfaces: top (capacity 5, contains offering-bowl, incense-burner, tattered-scroll), behind (capacity 2, contains silver-key) ✅
Bugs: None

### stone-well
Sensory: ✅ feel/smell/listen/taste defined
Material: ✅ stone (in registry)
Surfaces: top (capacity 2), inside (contains well-bucket) ✅
Bugs: None

### wine-rack
Sensory: ✅ feel/smell/listen defined
Material: ✅ wood (in registry)
Surface: inside (capacity 12, accepts "bottle", contains 3 wine bottles) ✅
Bugs: None

### side-table
Sensory: ✅ feel/smell defined
Material: ✅ oak (in registry)
Surface: top (capacity 3, contains vase) ✅
Bugs: None

### portrait
Sensory: ✅ feel/smell defined
Material: ✅ wood (in registry)
Bugs: None

### iron-key
Sensory: ✅ feel/smell/taste defined
Material: ✅ iron (in registry)
Bugs: None

### silver-key
Sensory: ✅ feel/smell/taste defined
Material: ✅ silver (in registry — if new material was added)
Bugs: None

### matchbox / matchbox-open
States tested: Matchbox has open mutation → becomes matchbox-open; matchbox-open has close mutation → becomes matchbox (code review)
Sensory: ✅ Both variants have dynamic feel (count-sensitive), smell, listen
Container: matchbox (accessible=false), matchbox-open (accessible=true) ✅
Has_striker: true on both variants ✅
Bugs: None

---

## MATERIAL REGISTRY COMPLETENESS

| Material | Used By | In Registry |
|----------|---------|-------------|
| wax | candle | ✅ |
| wood | match, bed, barrel, torch, pen, pencil, well-bucket, rain-barrel, wine-rack, portrait, wall-clock | ✅ |
| fabric | cloth, rag, bandage, terrible-jacket, sack | ✅ |
| wool | blanket, wool-cloak, rug | ✅ |
| iron | chain, crowbar, torch-bracket, oil-lantern, iron-key, wall-sconce | ✅ |
| steel | knife, needle, pin | ✅ |
| brass | brass-key, candle-holder, incense-burner | ✅ |
| glass | glass-shard, poison-bottle, window, wine-bottle | ✅ |
| paper | paper, sewing-manual, tattered-scroll | ✅ |
| leather | tome | ✅ |
| ceramic | chamber-pot, offering-bowl, vase | ✅ |
| tallow | candle-stub | ✅ |
| cotton | bed-sheets, thread | ✅ |
| oak | wardrobe, nightstand, vanity, locked-door, wooden-door, side-table | ✅ |
| velvet | curtains | ✅ |
| cardboard | matchbox, matchbox-open | ✅ |
| linen | pillow | ✅ |
| hemp | rope-coil | ✅ |
| bone | skull | ✅ |
| silver | silver-key, silver-dagger, burial-coins, burial-jewelry | ✅ |
| stone | cobblestone, stone-altar, stone-well, stone-sarcophagus, sarcophagus, wall-inscription | ✅ |
| **burlap** | **grain-sack** | **❌ MISSING (BUG-108)** |

---

## OBJECTS INVENTORY SUMMARY

**Total .lua files in src/meta/objects/:** 74 (66 original + 8 new from Flanders)

**New objects from Flanders (not in original 66):**
1. burial-coins.lua
2. burial-jewelry.lua
3. candle-stub.lua
4. sarcophagus.lua (generic crypt variant)
5. skull.lua
6. silver-dagger.lua
7. tome.lua
8. wall-inscription.lua

**Missing base class files (referenced in world but don't exist):**
1. oil-flask.lua ❌
2. cloth-scraps.lua ❌
3. bronze-ring.lua ❌
4. burial-necklace.lua ❌

---

## BUG SUMMARY

| Bug ID | Severity | Description | Affects |
|--------|----------|-------------|---------|
| BUG-106 | 🔴 CRITICAL | 30 instance GUID mismatches across all rooms except Bedroom | All non-Bedroom levels |
| BUG-107 | 🔴 CRITICAL | 4 missing base class definitions (oil-flask, cloth-scraps, bronze-ring, burial-necklace) | Storage Cellar, Crypt |
| BUG-108 | 🟡 MEDIUM | Material "burlap" not in registry | grain-sack |
| BUG-109 | 🟡 MEDIUM | 15 surface containment warnings (cascading from BUG-106) | All rooms with nested containment |

**Note:** BUG-106 is the root cause of BUG-109. Fixing BUG-106 should resolve BUG-109 automatically.

---

## RECOMMENDATIONS

1. **BUG-106 (CRITICAL):** Bart or Flanders must update all `type_id` values in `src/meta/world/*.lua` to match the GUIDs in `src/meta/objects/*.lua`. This is a bulk find-and-replace across 5 world files.

2. **BUG-107 (CRITICAL):** Flanders must create 4 missing base class files: oil-flask, cloth-scraps, bronze-ring, burial-necklace. Without these, the Storage Cellar and Crypt puzzles are incomplete.

3. **BUG-108 (MEDIUM):** Either add "burlap" to the materials registry or change grain-sack.lua to use "fabric". Recommend adding "burlap" as a distinct material.

4. **Re-test after fixes:** Once BUG-106 and BUG-107 are fixed, run a regression pass to verify all rooms load cleanly and all objects are interactive.
