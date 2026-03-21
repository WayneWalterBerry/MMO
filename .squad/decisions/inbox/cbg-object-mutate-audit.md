# Object `mutate` Field Audit

**Author:** Comic Book Guy (Game Designer)
**Date:** 2026-03-27
**Context:** Bart's `mutate` field on FSM transitions (commit d6c66d9) enables property changes during state transitions — weight, size, keywords, categories, portable — all declared in .lua metadata, zero engine changes.

**Scope:** All 37 objects in `src/meta/objects/`. Evaluated for transition-level mutations that improve player immersion.

---

## How `mutate` Works (Quick Reference)

Applied by `apply_mutations()` in `src/engine/fsm/init.lua` AFTER `apply_state()` sets the new state properties. Three forms:

1. **Direct value:** `weight = 0.05` — sets the property
2. **Function:** `weight = function(w) return w * 0.5 end` — computed from current value
3. **List ops:** `keywords = { add = "stub" }` or `keywords = { remove = "tall" }` — add/remove from lists

Mutations modify **base-level instance properties** that persist across states (weight, size, keywords, categories, portable) — properties the state system doesn't touch.

---

## TIER 1: HIGH-IMPACT MUTATIONS (Dramatically improves immersion)

### 🕯️ candle.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `lit → extinguished` | Weight decreases (wax melted away). Keywords gain "half-burned", "stub". | `mutate = { weight = function(w) return math.max(w * 0.7, 0.1) end, keywords = { add = "half-burned" } }` |
| `lit → spent` (auto, timer_expired) | Weight drops to near zero. Size drops. Keywords become "nub", "spent". Categories lose "light source". | `mutate = { weight = 0.05, size = 0, keywords = { add = "nub" }, categories = { remove = "light source" } }` |
| `extinguished → lit` | No mutation needed — weight already decreased, keywords already shifted. State handles descriptions. | *(none)* |

**Player Experience:** You carry the candle for an hour, extinguish it, pick it up again — *it's lighter*. You FEEL the wax has been consumed. When it burns out completely, it's barely there. A "spent candle nub" in your inventory weighing almost nothing. The game rewards attentive players who notice details.

**Note:** The `mutate` on `lit → extinguished` uses a function because the weight depends on how much has already burned. If a player lights and extinguishes multiple times, each cycle reduces weight further. The `lit → spent` auto-transition sets absolute values because the candle is fully consumed regardless.

**Concrete code for candle.lua transitions:**

```lua
-- lit → extinguished
{
    from = "lit", to = "extinguished", verb = "extinguish",
    aliases = {"blow", "put out", "snuff"},
    message = "You blow out the candle. A thin trail of smoke rises from the wick. Darkness closes in.",
    mutate = {
        weight = function(w) return math.max(w * 0.7, 0.1) end,
        keywords = { add = "half-burned" },
    },
},

-- lit → spent (auto)
{
    from = "lit", to = "spent", trigger = "auto",
    condition = "timer_expired",
    message = "The candle flame gutters, sputters, and dies with a final hiss. The last of the tallow is consumed. Darkness returns, absolute and complete.",
    mutate = {
        weight = 0.05,
        size = 0,
        keywords = { add = "nub" },
        categories = { remove = "light source" },
    },
},
```

---

### 🔥 match.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `unlit → lit` | Keywords gain "lit", "burning". | `mutate = { keywords = { add = "burning" } }` |
| `lit → spent` (manual or auto) | Keywords gain "spent", "blackened". Categories gain "useless". Weight drops. | `mutate = { weight = 0.005, keywords = { add = "spent" }, categories = { add = "useless" } }` |

**Player Experience:** A spent match isn't just a state change — it's a *different object* in the player's hands. It weighs almost nothing. It's a "blackened matchstick" now. If they try to FEEL it, the weight tells the story. When they EXAMINE their inventory, "a spent match" weighs 0.005 — basically nothing. The game world has mass, and consuming things reduces it.

**Concrete code for match.lua transitions:**

```lua
-- unlit → lit
{
    from = "unlit", to = "lit", verb = "strike",
    aliases = {"light", "ignite"},
    requires_property = "has_striker",
    message = "You drag the match head across the striker strip. It sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke. A tiny flame dances at the tip.",
    fail_message = "You need a rough surface to strike it on. A matchbox striker, perhaps.",
    mutate = {
        keywords = { add = "burning" },
    },
},

-- lit → spent (manual)
{
    from = "lit", to = "spent", verb = "extinguish",
    aliases = {"blow", "put out"},
    message = "You blow out the match. The blackened head crumbles. It's useless now.",
    mutate = {
        weight = 0.005,
        keywords = { add = "blackened" },
        categories = { add = "useless" },
    },
},

-- lit → spent (auto)
{
    from = "lit", to = "spent", trigger = "auto",
    condition = "timer_expired",
    message = "The match flame reaches your fingers and dies. You drop the blackened stub.",
    mutate = {
        weight = 0.005,
        keywords = { add = "blackened" },
        categories = { add = "useless" },
    },
},
```

---

### 🧪 poison-bottle.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `sealed → open` (uncork) | Weight decreases slightly (cork removed). Keywords gain "uncorked", "open". | `mutate = { weight = function(w) return w - 0.05 end, keywords = { add = "uncorked" } }` |
| `open → empty` (drink) | Weight drops dramatically (liquid consumed). Categories lose "dangerous". Keywords gain "empty". | `mutate = { weight = 0.1, categories = { remove = "dangerous" }, keywords = { add = "empty" } }` |
| `open → empty` (pour) | Same as drink — liquid is gone either way. | `mutate = { weight = 0.1, categories = { remove = "dangerous" }, keywords = { add = "empty" } }` |

**Player Experience:** The sealed bottle is heavy with liquid (0.4). Open it — slightly lighter (cork gone). Pour it out or drink it — suddenly it's just 0.1, empty glass. The "dangerous" category dropping means the engine no longer flags it as a hazard. The keyword "empty" means `SEARCH FOR EMPTY BOTTLE` or `GET EMPTY BOTTLE` now resolves. A player who says "take the empty bottle" after pouring out the poison — it just works.

**Concrete code for poison-bottle.lua transitions:**

```lua
-- sealed → open
{
    from = "sealed", to = "open", verb = "open",
    aliases = {"uncork", "unstop"},
    message = "You pry the cork free with a soft pop. A wisp of sickly green vapor curls from the bottle's mouth.",
    mutate = {
        weight = function(w) return w - 0.05 end,
        keywords = { add = "uncorked" },
    },
},

-- open → empty (drink)
{
    from = "open", to = "empty", verb = "drink",
    aliases = {"quaff", "sip", "gulp"},
    message = "You raise the bottle to your lips. The liquid burns like liquid fire. Your vision swims, your knees buckle, and the world goes dark...",
    effect = "poison",
    mutate = {
        weight = 0.1,
        categories = { remove = "dangerous" },
        keywords = { add = "empty" },
    },
},

-- open → empty (pour)
{
    from = "open", to = "empty", verb = "pour",
    aliases = {"spill", "dump"},
    message = "You tip the bottle. The green liquid pours out, hissing where it touches the stone floor. A thin vapor rises, and then it is gone.",
    mutate = {
        weight = 0.1,
        categories = { remove = "dangerous" },
        keywords = { add = "empty" },
    },
},
```

---

### 🪟 window.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `closed → open` | Keywords gain "open". Categories gain "ventilation". | `mutate = { keywords = { add = "open" }, categories = { add = "ventilation" } }` |
| `open → closed` | Keywords remove "open". Categories remove "ventilation". | `mutate = { keywords = { remove = "open" }, categories = { remove = "ventilation" } }` |

**Player Experience:** "CLOSE THE OPEN WINDOW" — the parser can now resolve "open window" as a keyword match. And "ventilation" as a category means other systems (smell propagation, temperature) can query whether the room has airflow. A cold wind from an open window could affect candle flicker or player warmth.

**Concrete code for window.lua transitions:**

```lua
{
    from = "closed", to = "open", verb = "open",
    message = "You unlatch the iron catch and push the window open. Cool air rushes in, carrying the smell of rain and chimney smoke.",
    mutate = {
        keywords = { add = "open" },
        categories = { add = "ventilation" },
    },
},
{
    from = "open", to = "closed", verb = "close",
    message = "You pull the window shut and latch it. The sounds of the outside world are muffled once more.",
    mutate = {
        keywords = { remove = "open" },
        categories = { remove = "ventilation" },
    },
},
```

---

## TIER 2: MEDIUM-IMPACT MUTATIONS (Adds polish and consistency)

### 🧥 wardrobe.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `closed → open` | Keywords gain "open". | `mutate = { keywords = { add = "open" } }` |
| `open → closed` | Keywords remove "open". | `mutate = { keywords = { remove = "open" } }` |

**Player Experience:** "LOOK IN OPEN WARDROBE" resolves via keyword. Consistent with window pattern.

---

### 🪞 vanity.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `closed → open` | Keywords gain "open". | `mutate = { keywords = { add = "open" } }` |
| `open → closed` | Keywords remove "open". | `mutate = { keywords = { remove = "open" } }` |
| `closed → closed_broken` (break mirror) | Keywords gain "broken", "shattered". Keywords remove "mirror", "looking glass". | `mutate = { keywords = { add = "broken" } }` |
| `open → open_broken` (break mirror) | Same as above. | `mutate = { keywords = { add = "broken" } }` |

**Player Experience:** After smashing the mirror, "LOOK AT BROKEN VANITY" works as a keyword. The vanity state already changes `categories` (removes "reflective") and `weight` (38 vs 40) in the state definition — `mutate` reinforces this at the keyword level for parser resolution.

**Note:** Since `mutate` currently supports single add/remove per call, the mirror-break transitions would need the most critical keyword change. "broken" is the highest-value addition. If multi-op list mutations are added later, also remove "mirror" and "looking glass".

---

### 🛏️ candle-holder.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `with_candle → empty` (detach) | Weight decreases by candle weight (~1). | `mutate = { weight = function(w) return w - 1 end }` |
| `empty → with_candle` (reattach) | Weight increases by candle weight (~1). | `mutate = { weight = function(w) return w + 1 end }` |

**Player Experience:** Pick up the candle holder — it's 1.5. Remove the candle — it's 0.5. Simple physics that makes the world feel real.

---

### 🪑 nightstand.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `open_with_drawer → open_without_drawer` (detach drawer) | Weight decreases by ~2 (drawer weight). | `mutate = { weight = function(w) return w - 2 end }` |
| `*_without_drawer → *_with_drawer` (reattach) | Weight increases by ~2. | `mutate = { weight = function(w) return w + 2 end }` |

**Player Experience:** The nightstand gets lighter when you yank its drawer out. Subtle, but the kind of detail that makes attentive players feel the world is real.

---

### 🚪 trap-door.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `revealed → open` | Keywords gain "open", "stairway". | `mutate = { keywords = { add = "open" } }` |

**Player Experience:** "GO THROUGH OPEN TRAP DOOR" resolves. "LOOK AT OPEN HATCH" resolves. Minor but consistent with the open/closed keyword pattern.

---

### 🪯 curtains.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| `closed → open` | Keywords gain "open". | `mutate = { keywords = { add = "open" } }` |
| `open → closed` | Keywords remove "open". | `mutate = { keywords = { remove = "open" } }` |

**Player Experience:** Consistent with window and wardrobe. "CLOSE THE OPEN CURTAINS" resolves.

---

## TIER 3: LOW-IMPACT / FUTURE CONSIDERATIONS

### ⏰ wall-clock.lua

| Transition | Properties That Should Mutate | Proposed `mutate` Metadata |
|---|---|---|
| Hour transitions (any) | Could add a `time_period` base property ("night", "dawn", "day", "dusk") that changes at key hours. | *Deferred — requires multi-value mutate or custom on_transition logic. Better as a computed property.* |

**Assessment:** The clock's 24 auto-transitions already update descriptions per state. Adding `mutate` to all 24 transitions for a `time_period` property is verbose. Better handled as a computed property: `time_period = function(self) ... end` based on `_state`. **Not recommended for `mutate`.**

---

### 🛢️ barrel.lua, 🛏️ bed.lua, 🧶 rug.lua, 🏺 chamber-pot.lua

These are non-FSM objects or have no transitions where property mutation would add immersion. The bed, rug, and barrel are static furniture. Chamber pot has no state changes.

**Assessment:** No `mutate` opportunities. These objects are complete as-is.

---

### 🔑 brass-key.lua, 🪡 needle.lua, 🧵 thread.lua, 📌 pin.lua, ✏️ pencil.lua, 🖊️ pen.lua, 📖 sewing-manual.lua, 🩹 bandage.lua, 🔪 knife.lua, 🥼 terrible-jacket.lua, 🧣 wool-cloak.lua, 🎒 sack.lua, 📄 paper.lua, 🧻 cloth.lua, 🧹 rag.lua, 🛏️ bed-sheets.lua, 🛏️ blanket.lua, 🔲 glass-shard.lua, 💊 torch-bracket.lua, 📦 matchbox.lua, 📦 matchbox-open.lua

These objects either:
- Have no FSM transitions (static objects)
- Use the old `mutations` system (becomes/spawns) which is a different mechanism
- Are consumable/crafting materials that transform entirely rather than mutating properties

**Assessment:** No transition-level `mutate` opportunities. The old `mutations` system (becomes/spawns) handles their transformation needs.

---

## SUMMARY TABLE

| Object | Has FSM? | Transitions | Mutate Opportunities | Priority |
|--------|----------|-------------|---------------------|----------|
| **candle** | ✅ | unlit→lit→extinguished→spent | weight↓, size↓, keywords+nub, categories−light source | 🔴 HIGH |
| **match** | ✅ | unlit→lit→spent | weight↓, keywords+blackened/spent, categories+useless | 🔴 HIGH |
| **poison-bottle** | ✅ | sealed→open→empty | weight↓↓, keywords+empty/uncorked, categories−dangerous | 🔴 HIGH |
| **window** | ✅ | closed↔open | keywords±open, categories±ventilation | 🔴 HIGH |
| **wardrobe** | ✅ | closed↔open | keywords±open | 🟡 MEDIUM |
| **vanity** | ✅ | closed/open × intact/broken | keywords+broken/open | 🟡 MEDIUM |
| **candle-holder** | ✅ | with_candle↔empty | weight±1 (candle mass) | 🟡 MEDIUM |
| **nightstand** | ✅ | 4 states (drawer/open) | weight±2 (drawer mass) | 🟡 MEDIUM |
| **trap-door** | ✅ | hidden→revealed→open | keywords+open | 🟡 MEDIUM |
| **curtains** | ✅ | closed↔open | keywords±open | 🟡 MEDIUM |
| **wall-clock** | ✅ | 24 hourly cycles | time_period (deferred — computed property better) | 🟢 LOW |
| **bed** | ❌ | — | — | ⚪ NONE |
| **rug** | ❌ | — | — | ⚪ NONE |
| **barrel** | ❌ | — | — | ⚪ NONE |
| **chamber-pot** | ❌ | — | — | ⚪ NONE |
| **torch-bracket** | ❌ | — | — | ⚪ NONE |
| *16 static items* | ❌ | — | — | ⚪ NONE |

---

## DESIGN PRINCIPLES APPLIED

1. **Weight tells the story.** A candle that gets lighter as it burns. A poison bottle that becomes featherlight when empty. A nightstand that shifts when its drawer is yanked out. Weight is the most universally-felt mutation — it affects FEEL, carrying capacity, and surface weight calculations.

2. **Keywords are for parser resolution.** Adding "open" to open containers means "GET THE OPEN WARDROBE" resolves. Adding "spent" to a burned match means "DROP SPENT MATCH" resolves. Keywords are how the parser finds objects — they must reflect the object's current reality.

3. **Categories are for system queries.** "dangerous" on the poison bottle means the engine can warn players. "ventilation" on an open window means temperature/smell systems can query room airflow. "useless" on a spent match means the engine could auto-suggest dropping it.

4. **Functions for proportional changes, absolutes for terminal states.** A candle's weight decreases *proportionally* each time it's extinguished (you don't know how long it burned). A spent candle's weight is always 0.05 (it's fully consumed, period).

5. **Don't duplicate what states already handle.** States already change `name`, `description`, `on_feel`, `on_smell`, etc. `mutate` is for properties that states *don't* manage — the base-level numerical and categorical properties.

---

## RECOMMENDATION

Implement Tier 1 mutations immediately — candle, match, poison-bottle, and window. These four objects demonstrate the full power of `mutate` (weight functions, keyword list ops, category changes) and the player will *feel* the difference. Tier 2 can follow as a consistency pass.
