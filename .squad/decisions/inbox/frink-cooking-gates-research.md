# Research: How Games Gate Food Edibility Behind Cooking/Crafting

**Author:** Frink (Researcher) · **Date:** 2025-07-17  
**Requested by:** Wayne Berry  
**Scope:** Targeted survey of 7 games for cooking-as-prerequisite mechanics

---

## 1. Dwarf Fortress

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Most meat, fish, plants, eggs — all can be eaten raw |
| **Requires cooking** | Nothing strictly requires it, but raw food rots fast; cooking preserves |
| **Tool/station** | Kitchen workshop (+ Butcher's Shop for carcass → meat) |
| **Verb model** | Craft order — player queues "Cook Easy/Fine/Lavish Meal" at workshop |
| **Communication** | Rot & miasma teach the lesson; dwarves get happy thoughts from cooked meals |
| **Steal-worthy** | **Ingredient-count tiers** (2/3/4 ingredients → biscuit/stew/roast). Cooking *destroys seeds* — a preservation-vs-farming trade-off. Kitchen menu lets you forbid cooking certain resources. |

## 2. Valheim

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Berries, mushrooms, carrots — foraged plants are raw-edible |
| **Requires cooking** | All raw meat is **completely inedible** until cooked |
| **Tool/station** | Cooking Station placed over a Campfire (or Hearth/Brazier) |
| **Verb model** | Interaction — press E to place meat on hooks, press E again to retrieve |
| **Communication** | Raw meat has no "Eat" option in inventory. Audio sizzle + color change = done |
| **Steal-worthy** | **Burned food mechanic** — leave it too long and meat turns to Coal (inedible but useful for smelting). Creates a real-time attention skill. Timer is ~25s cook, ~25s to burn. Up to 4 items on station simultaneously. |

## 3. Don't Starve

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Almost everything — but raw Monster Meat damages health/sanity |
| **Requires cooking** | Nothing is strictly inedible raw, but raw food is inferior |
| **Tool/station** | Fire Pit (basic cook) or Crock Pot (4-ingredient recipes); also Drying Rack for jerky |
| **Verb model** | Two tiers: fire-cook is a simple interaction; Crock Pot is a craft (combine 4 items) |
| **Communication** | Cooked items show higher stat values in tooltip. Monster Meat hurts when eaten raw |
| **Steal-worthy** | **Crock Pot combinatorics** — 4 ingredient slots, 50+ recipes, filler ingredients (twigs, ice). Dangerous ingredients become safe when cooked into recipes (1 Monster Meat + 3 fillers = safe Meatballs). **Food left in Crock Pot doesn't spoil** until removed. |

## 4. Minecraft

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | All raw meat *can* be eaten, but raw chicken causes food poisoning (30% chance) |
| **Requires cooking** | Nothing is truly inedible, but cooked versions restore 2–3× more hunger/saturation |
| **Tool/station** | Furnace (10s, general), Smoker (5s, food-only), Campfire (30s, no fuel, 4 slots) |
| **Verb model** | Craft/smelt — place in station UI slot, wait for progress bar |
| **Communication** | Raw items named "Raw Beef" → "Steak"; different item icons; hunger bar feedback |
| **Steal-worthy** | **Tiered cooking stations** with different speeds/trade-offs. Fire Aspect sword kills drop pre-cooked meat (environmental cooking). Smoker is a food-specific upgrade. Automation via hoppers. |

## 5. NetHack

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Yes — all corpses can be eaten raw; it's the primary food source |
| **Requires cooking** | No cooking system exists. Tinning Kit is the closest analog |
| **Tool/station** | Tinning Kit (tool, uses charges) — converts corpse → preserved tin |
| **Verb model** | `a` (apply) tinning kit on corpse = craft action |
| **Communication** | "This <corpse> smells terrible!" — age messages warn of rot. Eating old corpse → "You feel deathly sick" (fatal food poisoning unless cured) |
| **Steal-worthy** | **Risk-reward corpse eating** — fresh corpses grant intrinsics (poison resistance, telepathy) but old ones kill you. Tinning preserves safely but reduces nutrition. Blessed kit = never rotten; cursed = always rotten. **The game doesn't tell you "cook this" — it punishes you for eating wrong, and you learn.** |

## 6. Caves of Qud

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Basic snacks provide calories; raw meat must be **preserved** at campfire first |
| **Requires cooking** | Raw food needs preservation step before it becomes a cooking ingredient |
| **Tool/station** | Lit Campfire or Clay Oven; can create campfires from flammable materials |
| **Verb model** | Menu interaction — "Cook from recipe" or "Cook with ingredients" (freestyle) |
| **Communication** | Campfire menu shows preservation and cooking as separate options |
| **Steal-worthy** | **Recipe discovery system** — recipes learned via experimentation, NPC meals, books, quests. Cooking skill tree (Meal Prep → Spicer → Carbide Chef). **Ingredient combo effects** — two ingredients can create triggered buffs ("whenever afraid, emit frost ray"). **Preservation as a gate** — raw → preserved → cookable is a clear pipeline. |

## 7. Classic Text IF (Zork-era)

| Aspect | Detail |
|--------|--------|
| **Raw-edible** | Food items are usually eat-or-use, no raw/cooked distinction |
| **Requires cooking** | No multi-step cooking mechanics in Infocom-era games |
| **Tool/station** | N/A — food is inventory puzzle items (give bread to NPC, bait traps) |
| **Verb model** | Single verb: `EAT LUNCH` — consumes for points or solves a puzzle |
| **Communication** | N/A |
| **Steal-worthy** | Classic IF treats food as **puzzle keys, not survival resources**. The lesson: in a text game, cooking should be a *puzzle verb* ("COOK MEAT ON FIRE") not a crafting menu. Modern parser IF has explored cooking more (IFDB tag: "cooking"), but no Infocom classic did it. |

---

## Synthesis: Patterns for MMO

### The Edibility Spectrum (across all games)
```
INEDIBLE ──── EDIBLE-BUT-HARMFUL ──── EDIBLE-BUT-WEAK ──── COOKED/PREPARED
  (Valheim)      (Minecraft chicken)     (Dwarf Fortress)     (all games)
```

### Three Gating Models

1. **Hard gate** (Valheim): Raw meat has no EAT action. You literally cannot consume it. Clearest communication but least interesting.
2. **Soft gate** (Minecraft/Don't Starve): You *can* eat raw, but suffer penalties (food poisoning, low nutrition, sanity loss). Teaches through consequence.
3. **Risk-reward** (NetHack): Eating raw is powerful but dangerous. Fresh = great, old = death. No explicit gate — the game teaches through punishment.

### Recommended Approach for MMO

Given our text adventure format and mutation-based engine:

- **Use the soft gate + mutation model.** Raw meat exists as an object with `edible = true` but `on_eat` triggers harmful effects (nausea, food poisoning injury). Cooking mutates `raw-meat.lua` → `cooked-meat.lua` where `on_eat` provides nourishment.
- **COOK is a verb**, not a menu. `COOK MEAT ON FIRE` — parser resolves tool (fire source) + target (raw food). This fits our text IF heritage and Principle 8 (objects declare behavior).
- **Objects declare cookability.** Add `cookable = { becomes = "cooked-meat", requires_tool = "fire_source", message = "The meat sizzles and browns." }` to raw food objects. Engine handles the mutation generically.
- **Steal the burned food mechanic** from Valheim via FSM: `raw → cooking → cooked → burned` with time-based transitions if we add timed states.
- **Steal preservation-as-gate** from Caves of Qud: `raw_carcass → (BUTCHER) → raw_meat → (COOK) → cooked_meat` is a natural two-step pipeline.
- **Steal "dangerous ingredients become safe in recipes"** from Don't Starve: Monster meat that hurts raw but feeds when cooked with other ingredients.

### Communication in Text

The player types `EAT RAW MEAT` and gets:
> "You tear into the raw flesh. It's tough, gamey, and your stomach immediately rebels. You feel nauseous."

The player types `COOK MEAT ON FIRE` and gets:
> "You hold the meat over the flames. Fat sizzles and drips. After a few minutes, the meat is browned and fragrant."

Then `EAT MEAT`:
> "The cooked meat is tough but nourishing. You feel strength returning."

This teaches through natural feedback — no tutorial needed.
