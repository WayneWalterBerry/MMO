# Containment Constraints

**Author:** Bart (Architect)  
**Date:** 2026-03-19  
**Status:** Proposed — awaiting team review  
**Related:** `docs/architecture/src-structure.md`, `.squad/decisions.md` (Decision 3)

---

## 1. The Problem Space

### Classic IF: Weight and Bulk

Every major IF engine — Zork, Inform 7, TADS — uses some form of weight and bulk limits. An object has a `weight` and a `size`; a container has a `max_weight` and a `max_size`. If either limit is exceeded, the move fails.

This is *necessary* but not *sufficient*.

Wayne's examples expose three distinct failure modes that weight/bulk alone cannot model:

| Attempted action | Why it fails | Is weight/bulk enough? |
|---|---|---|
| Put desk in sack | Desk is physically too large | **Yes** — bulk limit catches this |
| Put elephant in sack | Elephant is physically too large | **Yes** — bulk limit catches this |
| Put desk in elephant | Elephant is not a container at all | **No** — weight/bulk says nothing about whether a thing *can* contain |

The third case is the decisive one. The problem isn't "the elephant can't hold that much" — the problem is that *an elephant is not a container*. This is a category constraint, not a dimensional one.

### The Two Orthogonal Questions

Before any size calculation runs, two questions must be answered in order:

1. **Is the target a container?** (Can it hold anything at all?)
2. **Is the item physically compatible?** (Does it fit through the opening?)

Only if both answers are yes do we proceed to capacity and category checks. This ordering matters: we don't want to tell the player "the desk is too big for the elephant" — that implies the elephant *could* hold smaller things. The correct response is "you can't put things inside an elephant."

### Why Not Use an LLM at Runtime?

An LLM would answer this correctly every time — it understands that elephants aren't containers, that sacks have small openings, that bookshelves are for books. But:

- Per-interaction token cost is ruled out (team decision, Decision 19)
- Network latency would stall the game loop
- Non-deterministic answers break reproducibility (same action, different sessions → different result)

The system must be **fully deterministic**, **offline**, and **fast** (sub-millisecond per check). The LLM's role is upstream: it assigns containment properties when objects are *authored*, not when players *act*.

---

## 2. Proposed Architecture: Four-Layer Validation

Containment validation is a chain of four layers. Each layer can **reject with a reason**. If all layers pass, the move is valid.

```
validate(item, container)
  │
  ├─► Layer 1: Is container a container?     → "You can't put things inside an elephant."
  ├─► Layer 2: Does item fit physically?     → "The desk won't fit in the sack."
  ├─► Layer 3: Is there room left?           → "The sack is too full."
  └─► Layer 4: Category accept/reject?       → "The bookshelf is for books only."
```

### Layer 1 — Container Identity

Not every object is a container. An object is a container if and only if its Lua definition includes a `container` table. Absence of this field means "not a container" — full stop.

```
elephant  → no container field  → Layer 1 rejects
mirror    → no container field  → Layer 1 rejects
sack      → container = { … }   → Layer 1 passes
drawer    → container = { … }   → Layer 1 passes
room      → container = { … }   → Layer 1 passes
```

This is a deliberate design choice: the property is **structural, not flagged**. There is no `is_container = false` to misread or forget to set. If `container` is nil, the object is not a container.

### Layer 2 — Physical Size

Each object has a `size` tier (integer 1–6). Each container's `container` table has a `max_item_size` — the largest tier that fits through the opening.

**Size tiers:**

| Tier | Label | Example objects |
|------|-------|----------------|
| 1 | tiny | coin, key, ring, gem, small scroll |
| 2 | small | dagger, book, mirror, pouch, small tool |
| 3 | medium | sword, lantern, sack, vase, hat |
| 4 | large | chest, backpack, small shield, drawer |
| 5 | huge | desk, wardrobe, pony, large chest |
| 6 | massive | elephant, boulder, cart, wagon |

**Container opening sizes (examples):**

| Container | `max_item_size` | Rationale |
|-----------|-----------------|-----------|
| Pocket | 1 | Tiny only |
| Coin purse | 1 | Tiny only |
| Sack / bag | 3 | Medium and smaller — flexible opening |
| Desk drawer | 3 | Medium and smaller |
| Chest | 4 | Large and smaller — big opening |
| Wardrobe | 4 | Large and smaller |
| Room | 6 | Everything |

A desk (tier 5) against a sack (`max_item_size` = 3): `5 > 3` → Layer 2 rejects → *"The desk won't fit in the sack."*  
A mirror (tier 2) against a sack (`max_item_size` = 3): `2 ≤ 3` → Layer 2 passes.

The use of tiers rather than millimetre-precise dimensions is intentional. Precision would require authoring hundreds of exact measurements; tiers are fast to author, easy to reason about, and sufficient for the game's purposes.

### Layer 3 — Capacity

A container tracks how much it is currently holding (`used`) versus its maximum (`capacity`). Both values are in size-tier units.

When an item of size *S* is put in, `used + S` must not exceed `capacity`. When an item is removed, `used` decreases by *S*.

**Why size-tier units?** Because a sack holding three tiny coins should behave differently from a sack holding one medium vase. Counting items would be wrong (a coin shouldn't fill a sack). Weight alone is wrong (a feather pillow fills a sack before a cannonball). Size-tier units are a reasonable approximation.

Layer 3 is the only layer that **changes** after a successful put. Layers 1, 2, and 4 are stateless property lookups.

### Layer 4 — Category Accept/Reject

Some containers are logically constrained to certain types of items. A bookshelf is for books. A key ring is for keys. A potion rack is for potions. A holster is for weapons.

This is modelled with two optional fields on the container:

- `accepts`: a list of category strings. If present, the item must have at least one matching category. All others are rejected.
- `rejects`: a list of category strings. If any match, the item is rejected regardless of other checks.

`accepts` and `rejects` can coexist: a container might accept "weapon" but reject "two-handed" — representing a one-handed weapon rack.

Items have a `categories` list (e.g., `{"fragile", "reflective"}` for a mirror, `{"weapon", "bladed", "one-handed"}` for a dagger).

If neither `accepts` nor `rejects` is set on the container, Layer 4 passes unconditionally. Most containers (sacks, drawers, rooms) have no category restrictions.

---

## 3. How This Works with Code Rewrite

The mutation model means that when a mirror is placed in a sack, the sack's Lua definition is rewritten with the mirror in its `contents` list. The containment validator is a **pre-flight gate**: it runs before any rewrite. If it fails, no rewrite occurs and the player receives the rejection message.

The flow for `PUT MIRROR IN SACK`:

```
parser/verbs/put.lua
  │
  ├─ resolve noun "mirror"  → look up registry → item object
  ├─ resolve noun "sack"    → look up registry → container object
  │
  ├─ call engine/containment.validate(item, container)
  │     ├─ Layer 1: container.container exists?          YES
  │     ├─ Layer 2: item.size (2) ≤ max_item_size (3)?   YES
  │     ├─ Layer 3: used (0) + 2 ≤ capacity (10)?        YES
  │     └─ Layer 4: no accepts/rejects → pass
  │     returns: true, nil
  │
  ├─ validation passed → call engine/mutation to rewrite sack
  │     new sack.contents includes mirror
  │     new sack.container.used = 2
  │
  └─ output: "You put the mirror in the sack."
```

The flow for `PUT DESK IN SACK`:

```
parser/verbs/put.lua
  │
  ├─ resolve "desk" → item (size=5)
  ├─ resolve "sack" → container (max_item_size=3)
  │
  ├─ call engine/containment.validate(item, container)
  │     ├─ Layer 1: pass
  │     └─ Layer 2: item.size (5) > max_item_size (3) → FAIL
  │     returns: false, "The desk won't fit in the sack."
  │
  └─ no rewrite. output: "The desk won't fit in the sack."
```

The flow for `PUT DESK IN ELEPHANT`:

```
parser/verbs/put.lua
  │
  ├─ resolve "desk"     → item
  ├─ resolve "elephant" → container candidate
  │
  ├─ call engine/containment.validate(item, container)
  │     └─ Layer 1: container.container is nil → FAIL
  │     returns: false, "You can't put things inside the elephant."
  │
  └─ no rewrite. output: "You can't put things inside the elephant."
```

**Critical invariant:** the validator is the only entity that decides whether a rewrite happens. The mutation engine itself has no containment knowledge — it accepts any valid Lua source and performs the swap. This keeps mutation simple, auditable, and reusable.

---

## 4. Concrete Lua Sketch

### Object Definitions

```lua
-- src/meta/objects/mirror.lua
return {
  id          = "mirror",
  name        = "ornate mirror",
  description = "A tall mirror in a gilded frame. Your reflection stares back.",
  keywords    = { "mirror", "ornate mirror", "reflection" },
  size        = 2,           -- small
  categories  = { "fragile", "reflective" },
  -- no 'container' field → not a container
}

-- src/meta/objects/sack.lua
return {
  id          = "sack",
  name        = "canvas sack",
  description = "A sturdy canvas sack with a drawstring top.",
  keywords    = { "sack", "bag", "canvas sack" },
  size        = 3,           -- medium (the sack itself)
  categories  = { "flexible", "wearable" },
  container   = {
    max_item_size = 3,       -- medium and smaller fit through the opening
    capacity      = 10,      -- total size-tier units it can hold
    used          = 0,
    -- no 'accepts' → accepts any category
    -- no 'rejects' → rejects nothing by category
  },
  contents    = {},
}

-- src/meta/objects/desk.lua
return {
  id          = "desk",
  name        = "writing desk",
  description = "A heavy oak writing desk with a single drawer.",
  keywords    = { "desk", "writing desk" },
  size        = 5,           -- huge
  categories  = { "furniture" },
  container   = {            -- the desk itself IS a container (via its drawer)
    max_item_size = 3,
    capacity      = 6,
    used          = 0,
    -- drawer-style container: rejects large rigid items by size alone
  },
  contents    = {},
}

-- src/meta/objects/elephant.lua
return {
  id          = "elephant",
  name        = "grey elephant",
  description = "An enormous grey elephant. It regards you with mild suspicion.",
  keywords    = { "elephant" },
  size        = 6,           -- massive
  categories  = { "living", "animal", "massive" },
  -- no 'container' field → NOT a container
}

-- src/meta/objects/bookshelf.lua
return {
  id          = "bookshelf",
  name        = "tall bookshelf",
  description = "Shelves of dark wood, built for books.",
  keywords    = { "bookshelf", "shelf", "shelves" },
  size        = 5,
  categories  = { "furniture" },
  container   = {
    max_item_size = 2,       -- books are small; nothing large fits on a shelf
    capacity      = 20,
    used          = 0,
    accepts       = { "book", "scroll", "tome" },  -- category whitelist
  },
  contents    = {},
}
```

### The Validator

```lua
-- src/engine/containment/init.lua

local M = {}

local function table_contains(t, value)
  for _, v in ipairs(t) do
    if v == value then return true end
  end
  return false
end

local function item_matches_categories(item_cats, filter_cats)
  for _, f in ipairs(filter_cats) do
    if table_contains(item_cats, f) then return true end
  end
  return false
end

-- Returns: ok (bool), reason (string or nil)
-- reason is a player-facing message, ready to print.
function M.validate(item, container)
  -- Layer 1: Is the target actually a container?
  if not container.container then
    return false, string.format(
      "You can't put things inside %s.", container.name
    )
  end

  local c = container.container

  -- Layer 2: Physical size — does it fit through the opening?
  if item.size > c.max_item_size then
    return false, string.format(
      "%s won't fit in %s.", item.name, container.name
    )
  end

  -- Layer 3: Capacity — is there room?
  local used = c.used or 0
  if used + item.size > c.capacity then
    return false, string.format(
      "%s is too full.", container.name
    )
  end

  -- Layer 4: Category constraints
  local item_cats = item.categories or {}

  if c.rejects and item_matches_categories(item_cats, c.rejects) then
    return false, string.format(
      "%s can't go in %s.", item.name, container.name
    )
  end

  if c.accepts and not item_matches_categories(item_cats, c.accepts) then
    return false, string.format(
      "%s doesn't belong in %s.", item.name, container.name
    )
  end

  return true, nil
end

return M
```

### The PUT Verb Handler

```lua
-- src/parser/verbs/put.lua

local registry    = require("engine.registry")
local containment = require("engine.containment")
local mutation    = require("engine.mutation")

local M = {}

function M.handle(cmd, universe)
  -- cmd.noun1 = item to put, cmd.noun2 = destination container
  local item      = registry.get(universe, cmd.noun1)
  local container = registry.get(universe, cmd.noun2)

  if not item then
    return "You don't see that here."
  end
  if not container then
    return "Put it where, exactly?"
  end

  -- Check item is in scope (player can reach it)
  -- … (scope check omitted for brevity)

  -- Pre-flight containment validation
  local ok, reason = containment.validate(item, container)
  if not ok then
    return reason  -- player-facing rejection message
  end

  -- Validation passed — perform the rewrite
  -- Build new container source with item added to contents
  -- and used count updated
  local new_container_source = build_put_source(item, container)
  mutation.rewrite(universe, container.id, new_container_source)

  -- Also rewrite item's location
  local new_item_source = build_location_source(item, container.id)
  mutation.rewrite(universe, item.id, new_item_source)

  return string.format("You put %s in %s.", item.name, container.name)
end

return M
```

### Example Interactions

```
> put mirror in sack
  validate(mirror[size=2], sack[max=3, cap=10, used=0])
  L1: sack.container exists          ✓
  L2: 2 ≤ 3                          ✓
  L3: 0 + 2 ≤ 10                     ✓
  L4: no accepts/rejects             ✓
  → rewrite sack (contents+mirror, used=2)
  → rewrite mirror (location=sack)
  "You put the mirror in the sack."

> put desk in sack
  validate(desk[size=5], sack[max=3])
  L1: ✓
  L2: 5 > 3                          ✗
  "The writing desk won't fit in the canvas sack."
  [no rewrite]

> put desk in elephant
  validate(desk, elephant)
  L1: elephant.container is nil      ✗
  "You can't put things inside the grey elephant."
  [no rewrite]

> put elephant in sack
  validate(elephant[size=6], sack[max=3])
  L1: ✓
  L2: 6 > 3                          ✗
  "The grey elephant won't fit in the canvas sack."
  [no rewrite]

> put sword in bookshelf
  validate(sword[cats={weapon,bladed}], bookshelf[accepts={book,scroll,tome}])
  L1: ✓
  L2: 2 ≤ 2                          ✓
  L3: used + 2 ≤ 20                  ✓
  L4: accepts={book,scroll,tome}, sword has none  ✗
  "The sword doesn't belong in the bookshelf."
  [no rewrite]
```

---

## 5. Where This Lives in src/

```
src/
└── engine/
    └── containment/
        └── init.lua     — the validator (M.validate)
```

**Why `engine/containment/`, not `parser/`?**

Containment validation is an *engine concern*, not a *parsing concern*. The parser resolves "put mirror in sack" into `{noun1="mirror", noun2="sack"}`. What happens next is engine territory. By keeping the validator in `engine/containment/`, we ensure:

- It can be called from any verb that moves objects (PUT, DROP, FILL, LOAD, STOW…)
- It can be unit-tested without standing up a parser
- The parser remains thin — it only handles language, not physics

**Caller chain:**

```
parser/verbs/put.lua
  └── engine/containment/init.lua   ← pure validation, no side effects
  └── engine/mutation/init.lua      ← rewrite only if validation passed
      └── engine/loader/init.lua
      └── engine/registry/init.lua
```

The containment module has **no knowledge of** the mutation engine, the registry, or the parser. It takes two tables and returns a boolean and a string. This makes it trivially testable and composable.

---

## 6. The Authoring Workflow

The LLM's role here is important. When a new object is authored (via the LLM content pipeline), the LLM assigns:

- `size` tier (1–6)
- `categories` list
- `container` table (if the object can hold things), with `max_item_size`, `capacity`, and optional `accepts`/`rejects`

This is the *only* point where LLM judgment enters the containment system. At runtime, everything is deterministic table lookups. The LLM makes the semantic decisions once at authoring time; the engine enforces them mechanically at play time.

**Guidance for LLM authors:**

| Object type | Typical size | Has container? |
|---|---|---|
| Coin, key, ring | 1 (tiny) | No |
| Book, dagger, mirror | 2 (small) | No |
| Sack, sword, lantern | 3 (medium) | Sack: yes |
| Chest, drawer, backpack | 4 (large) | Yes |
| Desk, wardrobe | 5 (huge) | If it has storage: yes |
| Elephant, boulder | 6 (massive) | No (living/inanimate) |

---

## 7. Edge Cases

**Nested containment** (mirror in sack in desk drawer):  
Each PUT is validated independently against its direct container. "Mirror in sack" validates against the sack. "Sack in drawer" validates against the drawer. The engine does not validate the transitive chain. This is correct behaviour — the player chose to nest them.

**Taking from a nested container:**  
A TAKE from a nested container is the inverse path. The `GET` verb must resolve the full containment path (walk `.location` links), then validate that the item is reachable (not inside a locked container). This is a separate concern from put-validation.

**Circular containment:**  
"Put sack in sack" — the item and container are the same object. The PUT verb handler should check `item.id == container.id` before calling validate, and reject with "You can't put something inside itself." This is a pre-validate guard, not a validator layer (it's not a physics question, it's a logic error).

**Living containers (stomach, mouth):**  
For objects like a stomach or bag-of-holding (if the game ever goes there), `container` is simply populated with appropriate values. No special-casing needed. The tier system handles the physics; `accepts`/`rejects` handles the biology ("stomach" accepts "food", "drink"; rejects "metal", "weapon").

---

*Bart — Architect*
