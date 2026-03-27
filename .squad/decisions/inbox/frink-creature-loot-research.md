# Creature Inventory & Loot Drop Research
**Researcher:** Frink  
**Date:** 2025-01-17  
**For:** Wayne Berry (NPC creature loot systems research)

---

## Executive Summary

Six major game systems analyzed. **Key findings:**
1. **Data-driven loot tables** (not hardcoded) are universal across all games
2. **All systems guarantee base drops** + optional randomized rewards
3. **Equipment affects combat** in every game studied
4. **Scattering vs. containers:** Dwarf Fortress auto-forbids; MUDs/roguelikes scatter on ground; Souls/ARPG use containers (corpses/chests)

---

## 1. Dwarf Fortress

### Inventory & Definition
- Creatures carry weapons, armor, tools defined by creature type
- Both Fortress Mode (NPC automanage) and Adventure Mode (manual looting)

### Equipment Effects on Combat
- Yes—armor provides defense, weapons have stats. Equipment quality directly affects survival.

### Death Mechanics
- **Drops all items at death site**
- **Auto-forbid safety feature:** All enemy loot marked "Forbidden" by default; dwarves won't loot during danger
- Player must manually unforbid items after combat ends
- Standing orders can adjust auto-forbid behavior

### Player Interaction
- Pick up manually, haul to stockpiles, or use "atom smasher" to destroy unwanted loot
- Can view NPC equipment/inventory via unit inspector

### Pattern for Text Adventure
✅ **Safety-first design:** Forbid dropped items by default so player doesn't auto-grab during combat
✅ **Manual unforbid workflow:** Natural game mechanic + prevents accidental trade-offs

---

## 2. NetHack

### Inventory & Definition
- Monsters have species-appropriate starting inventory (humanoids get weapons/armor, etc.)
- Inventory determined at spawn; not randomized per instance

### Equipment Effects on Combat
- Yes—monsters wield weapons, wear armor; affects their threat level

### Death Mechanics
- **Guaranteed drop:** All items in monster inventory
- **Bonus "death drop":** 1/6 chance (~17%) for random bonus item
- Death drops influenced by location (main dungeon, Gehennom, Rogue level)
- Death drops constrained by monster size (small monsters drop light items only)
- Some monsters have special themed drops (dragon scales, unicorn horns, golem parts)

### Player Interaction
- Automatic drop at death site, player picks up manually
- Can "search corpse" for specific items

### Pattern for Text Adventure
✅ **Dual-drop system:** Guaranteed inventory + bonus RNG creates discovery
✅ **Location-aware loot:** Different dungeon levels yield different drop tables
✅ **Monster-specific drops:** Thematic loot (dragon scales) feels organic

---

## 3. MUDs (Achaea, Discworld)

### Inventory & Definition
- NPCs have equipment slots similar to player characters
- Loot defined via community wikis/databases (not always official)
- Discworld maintains player-driven item databases (Kefka's database)

### Equipment Effects on Combat
- Yes—NPC equipment directly affects threat/survivability

### Death Mechanics
- **All equipped/worn items drop** at death site
- **Inventory items drop** separately
- Some quest NPCs have scripted loot tables
- Rare unique drops possible from specific mobs

### Player Interaction
- Pick up manually or search corpse
- Community wikis track which NPCs drop what for strategic farming

### Pattern for Text Adventure
✅ **Visible equipment slots:** What you see on NPC is what drops (predictability + immersion)
✅ **Community discovery:** Optional farming/hunting meta

---

## 4. Roguelikes (DCSS, Caves of Qud, Cataclysm DDA)

### Inventory & Definition
- **Data-driven loot tables:** Monster type + dungeon level → possible items
- Procedurally generated, not fixed per playthrough

### Equipment Effects on Combat
- Yes—worn equipment directly impacts monster survivability and danger

### Death Mechanics
- **Scatter items at death:** All inventory drops on ground
- **No auto-forbid:** Player must manually sort loot
- Some monsters drop themed items (e.g., specific faction gear)

### Player Interaction
- Manual pickup, inventory management is player responsibility
- High-level threats carry better loot (incentivizes dangerous combat)

### Pattern for Text Adventure
✅ **Risk/reward loot:** Dangerous creatures drop best loot; player choice whether to engage
✅ **Procedural loot tables:** Scales with dungeon difficulty automatically

---

## 5. Dark Souls / Soulslikes

### Inventory & Definition
- **Bosses: guaranteed unique drops** (boss souls + quest items)
- Regular enemies have random loot (influenced by item discovery stat)
- Loot tables vary by enemy type

### Equipment Effects on Combat
- Yes—player equipment drastically affects defense/survivability
- NPC armor/weapons similarly determine their threat level

### Death Mechanics
- **Bosses drop guaranteed boss soul** (special currency)
- Boss soul can be **consumed for currency** OR **transposed into unique weapon/spell/ring**
- Boss souls are limited (only 1 per playthrough per boss)
- Additional guaranteed items for quest progress
- Regular enemies: mostly random, ~1-5% drop rate unless modded

### Player Interaction
- Boss souls carried to NPC crafter for transposition
- Corpses remain on ground; player picks up drops
- High engagement: want to collect boss souls for crafting options

### Pattern for Text Adventure
✅ **Currency + crafting chain:** Boss loot opens crafting tree (strategic depth)
✅ **Guaranteed drops encourage replayability:** Players farm multiple playthroughs for all items
✅ **Quest items tied to loot:** Naturally gates progression

---

## 6. Diablo / ARPG

### Inventory & Definition
- **Rigid loot tables:** Monster type + area + difficulty → item pool
- Magic Find stat increases rare drop chances

### Equipment Effects on Combat
- Yes—player equipment is primary progression; NPC equipment affects their threat

### Death Mechanics
- Monsters drop loot based on difficulty tier
- **Difficulty gates item rarity:**
  - Normal → Common/Magic items only
  - Nightmare → Magic/Rare/Legendary possible
  - Hell/Torment → Rare/Unique/Ancestral/Mythic available
- Boss drops always have better tables than trash mobs
- Some loot locked to specific bosses or activities (Pit, Helltide)

### Player Interaction
- Auto-pickup or manual loot collection
- Corpses remain at death site temporarily
- High-level activities have exclusive loot pools

### Pattern for Text Adventure
✅ **Difficulty scaling loot:** Automatically balances challenge vs. reward
✅ **Boss-specific tables:** Creates farming targets
✅ **Tiered rarity system:** Gives sense of progression

---

## Design Patterns Worth Stealing

| Pattern | Source | Application to MMO |
|---------|--------|---------------------|
| **Dual-drop (guaranteed + bonus RNG)** | NetHack | Goblin drops dagger + 20% chance extra item |
| **Auto-forbid safety** | Dwarf Fortress | Creature corpses "locked" 1-2 turns after death |
| **Thematic loot** | NetHack, Roguelikes | Troll drops bones; skeleton drops rusted armor |
| **Location-aware tables** | NetHack, Diablo | Underground creatures drop minerals; surface = gold |
| **Equipment affects combat** | All | Armored ogre = harder fight; unarmored = easier |
| **Creature-specific unique drops** | Dark Souls | Boss creatures drop soul currency for crafting |
| **Difficulty gating** | Diablo | Rare items only from high-level creatures |
| **Visible inventory** | MUDs | Player sees what creature carries before looting |

---

## Recommendations for MMO (Text Adventure)

### Implementation Direction
1. **Data-driven loot tables:** Creature type defines base inventory + drop chances
2. **Visible equipment:** Describe creature equipment in `look` command (affects combat description)
3. **Guaranteed + random:** Every creature drops 1-2 items; maybe 30-50% for bonus item
4. **Thematic loot:** Troll ≠ wizard—loot matches creature archetype
5. **Location scaling:** Dungeon level 3 creatures drop better loot than level 1
6. **Corpse container:** Option to search corpse for specific items (vs. auto-scatter)

### Lua Pattern Suggestion
```lua
-- creature.lua
return {
    inventory = {
        { id = "leather-armor", equipped = true },
        { id = "iron-sword", equipped = true },
    },
    loot_table = {
        guaranteed = { { id = "gold-coins", qty = "1d6+2" } },
        rare = {
            { id = "elixir-of-life", weight = 0.2 },
            { id = "enchanted-ring", weight = 0.1 },
        }
    },
    combat_armor_class = 4, -- affected by equipped armor
    equipment_flavor = "wears dented leather" -- description text
}
```

---

## Key Takeaway
**Loot is not just items—it's game depth.** Every system uses loot as:
- Combat incentive (dangerous enemies → better rewards)
- Progression gate (hard areas drop rare gear)
- Crafting input (souls → weapons)
- Tactical decision (risk/reward looting mid-combat)

For MMO: Make creature equipment **visible**, **thematic**, and **consequential**. The player should want to fight that heavily-armored troll because the armor is useful—not just for XP.

---

**Status:** Research complete. Awaiting Bart (Architect) feedback on object mutation system compatibility.
