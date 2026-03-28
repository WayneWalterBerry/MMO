# Level 1 → Level 2 Inventory Audit

**Issue:** #127  
**Auditor:** Nelson (QA Engineer)  
**Date:** 2026-03-24  
**Status:** ✅ COMPLETE

## Purpose

Catalog every object in Level 1 and determine what a player can carry into Level 2. This report is for Bob (Puzzle Design) and CBG (Game Design) to know what items may be available when Level 2 begins.

## Level 1 Structure

**Rooms (7):** start-room (Bedroom), cellar, storage-cellar, deep-cellar, crypt (optional), hallway, courtyard (alternate path)

**Critical path:** Bedroom → Cellar (trap door) → Storage Cellar → Deep Cellar → Hallway (north staircase = Level 2 exit)

**Alternate path:** Bedroom → Courtyard (window) → (blocked — kitchen door locked/breakable)

**Level 2 exit:** Hallway north exit (grand staircase)
- `max_carry_size = 5`
- `max_carry_weight = 50`
- `requires_hands_free = false`
- No key required, always open

## Inventory System Constraints

- **2 hand slots** — player can hold at most 2 items in hands
- **Worn items** don't occupy hand slots (cloak on back, pot/spittoon on head, ring on finger, etc.)
- **Containers in hand** (sack, matchbox) carry nested items
- **Exit constraints** at Level 2 boundary: size ≤ 5, weight ≤ 50

---

## Complete Object Inventory — Level 1

### Bedroom (start-room) — 22 objects

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| bed | furniture | 10 | 80 | ❌ | No | Fixed furniture |
| pillow | sheet | 2 | 1 | ✅ | Tearable → cloth | Contains hidden pin |
| pin | small-item | 1 | 0.05 | ✅ | No | Lockpick tool (skill-gated) |
| bed-sheets | sheet | 3 | 2 | ✅ | Tearable → cloth | Fabric source |
| blanket | sheet | 3 | 3 | ✅ | Tearable → cloth | Fabric source |
| knife | small-item | 1 | 0.3 | ✅ | No | Multi-tool: cutting + weapon |
| nightstand | furniture | — | — | ❌ | No | Fixed furniture |
| candle-holder | small-item | 2 | 1.5 | ✅ | No | Holds candle |
| candle | small-item | 1 | 1 | ✅ | Yes — burns down to spent | FSM: unlit → lit → spent |
| poison-bottle | small-item | 1 | 0.4 | ✅ | Yes — drink = death, pour = empty | Lethal if consumed |
| drawer | furniture | 3 | 2 | ✅ | No | Detachable from nightstand |
| matchbox | small-item | 1 | 0.3 | ✅ | No (contents are consumable) | Container: holds 7 matches |
| match ×7 | small-item | 1 | 0.01 | ✅ | Yes — single use, burns out | FSM: unlit → lit → spent |
| paper | small-item | 1 | 0.1 | ✅ | Burnable | Writable surface |
| pen | small-item | 1 | 0.1 | ✅ | No | Writing tool |
| pencil | small-item | 1 | 0.1 | ✅ | No | Writing tool |
| wool-cloak | sheet | 3 | 3 | ✅ | Tearable → cloth | **Wearable** (back slot, warmth) |
| sack | container | 1 | 0.3 | ✅ | Tearable → cloth | **Wearable** (back/head), container |
| needle | small-item | 1 | 0.05 | ✅ | No | Sewing tool |
| thread | small-item | 1 | 0.05 | ✅ | No | Sewing material |
| sewing-manual | small-item | 1 | 0.1 | ✅ | No | Grants sewing skill on read |
| rug | sheet | 5 | 8 | ❌ | No | Covers trap door |
| brass-key | small-item | 1 | 1 | ✅ | No | Unlocks cellar→storage door |
| trap-door | furniture | 6 | 100 | ❌ | No | Reveals cellar stairway |
| window | furniture | 5 | 20 | ❌ | Breakable → glass shards | Exit to courtyard |
| curtains | sheet | 4 | 4 | ❌ | Tearable → cloth + rag | Light filter |
| chamber-pot | container | 2 | 3 | ✅ | Shatterable (ceramic) | **Wearable** (head slot, helmet) |
| bedroom-door | furniture | 6 | 120 | ❌ | Breakable | North exit (locked from other side) |

### Cellar — 2 objects

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| barrel | furniture | 5 | 60 | ❌ | No | Sealed, static |
| torch-bracket | furniture | 2 | 5 | ❌ | No | Wall-mounted, empty |

### Storage Cellar — 8 objects (+ contents)

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| large-crate | furniture | 5 | 25 | ❌ | Breakable (pry with crowbar) | Contains iron key |
| small-crate | container | 3 | 8 | ✅ | Breakable | Contains cloth scraps + candle stub |
| cloth-scraps | sheet | 1 | 0.15 | ✅ | No | Craftable material |
| candle-stub | small-item | 1 | 0.1 | ✅ | Yes — burns down (shorter than candle) | Light source |
| iron-key | small-item | 1 | 0.5 | ✅ | No | Unlocks storage→deep-cellar door |
| wine-rack | furniture | 5 | 30 | ❌ | No | Fixed furniture |
| wine-bottle | small-item | 2 | 1.5 | ✅ | Yes — drink/pour = empty, break = shards | FSM: sealed → open → empty |
| grain-sack | container | 3 | 15 | ✅ | No | Openable (cut with knife) |
| oil-lantern | small-item | 2 | 1.2 | ✅ | Yes — burns down to spent | Wind-resistant light, 4hr burn |
| rope-coil | small-item | 3 | 3 | ✅ | No | Rope + binding tool |
| crowbar | small-item | 3 | 3 | ✅ | No | Prying tool + weapon |
| oil-flask | small-item | 1 | 0.8 | ✅ | Yes — consumed to fuel lantern | Lamp oil fuel |
| brass-spittoon | container | 2 | 4 | ✅ | No (dents cosmetically) | **Wearable** (head slot, helmet) |

### Deep Cellar — 6 objects (+ contents)

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| stone-altar | furniture | 6 | 200 | ❌ | No | Fixed furniture |
| incense-burner | container | 2 | 1.5 | ✅ | No | Holds ash |
| tattered-scroll | small-item | 1 | 0.1 | ✅ | No | Lore object, puzzle hint |
| offering-bowl | container | 2 | 2 | ✅ | No | Puzzle trigger |
| wall-sconce ×2 | furniture | 2 | 2 | ❌ | No | Wall-mounted |
| stone-sarcophagus | furniture | 6 | 500 | ❌ | No | Contains silver key |
| silver-key | small-item | 1 | 0.3 | ✅ | No | Opens crypt gate |
| chain | furniture | 4 | 5 | ❌ | No | Puzzle mechanism |

### Crypt (optional) — 8 objects (+ sarcophagus contents)

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| sarcophagus ×5 | furniture | 6 | 500 | ❌ | No | Burial containers |
| bronze-ring | small-item | 1 | 0.04 | ✅ | No | **Wearable** (finger), treasure |
| silver-dagger | small-item | 2 | 0.5 | ✅ | No | Weapon (stab, cut, slash) |
| burial-necklace | small-item | 1 | 0.08 | ✅ | No | **Wearable** (neck), treasure |
| tome | small-item | 3 | 2 | ✅ | No | Critical lore, readable |
| candle-stub ×2 | small-item | 1 | 0.1 | ✅ | Yes — burns down | Short-burn light source |
| burial-coins | small-item | 1 | 0.3 | ✅ | No | Treasure |
| wall-inscription | furniture | 6 | — | ❌ | No | Static, readable |

### Hallway — 6 objects

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| torch ×2 (lit) | small-item | 3 | 1.5 | ✅ | Yes — burns down to spent | 3hr burn, starts lit |
| portrait ×3 | furniture | 4 | 5 | ❌ | No | Bolted to wall |
| side-table | furniture | 4 | 20 | ❌ | No | Fixed furniture |
| vase | small-item | 2 | 2 | ✅ | Yes — breakable (ceramic) | Decorative |

### Courtyard (alternate path) — 4 objects

| Object | Template | Size | Weight | Portable | Consumable/Destructible | Notes |
|--------|----------|------|--------|----------|------------------------|-------|
| stone-well | furniture | 6 | — | ❌ | No | Water source |
| well-bucket | container | 3 | 2 | ✅ | No | Water retrieval |
| ivy | furniture | 6 | — | ❌ | Tearable | Climbable |
| cobblestone | small-item | 2 | 2 | ✅ | No | Blunt weapon + weight |
| rain-barrel | furniture | 5 | 40 | ❌ | No | Water source |

### Spawned Objects (conditional)

| Object | Template | Size | Weight | Portable | Source | Notes |
|--------|----------|------|--------|----------|--------|-------|
| glass-shard ×2 | small-item | 1 | 0.1 | ✅ | Breaking window | Sharp tool, injures on feel |
| cloth ×N | sheet | 1 | 0.2 | ✅ | Tearing fabric | Craftable → bandage, terrible-jacket |
| terrible-jacket | sheet | 2 | 0.5 | ✅ | Crafting (2× cloth + sew) | **Wearable** (torso) |

---

## Summary: All Portable Objects (43 base + 3 conditional)

| # | Object | Room | Size | Weight | Wearable | Consumable | Key/Tool |
|---|--------|------|------|--------|----------|------------|----------|
| 1 | pillow | bedroom | 2 | 1 | — | tearable | — |
| 2 | pin | bedroom | 1 | 0.05 | — | — | lockpick |
| 3 | bed-sheets | bedroom | 3 | 2 | — | tearable | — |
| 4 | blanket | bedroom | 3 | 3 | — | tearable | — |
| 5 | knife | bedroom | 1 | 0.3 | — | — | cutting + weapon |
| 6 | candle-holder | bedroom | 2 | 1.5 | — | — | holds candle |
| 7 | candle | bedroom | 1 | 1 | — | burns out | light source |
| 8 | poison-bottle | bedroom | 1 | 0.4 | — | drink=death | lethal |
| 9 | drawer | bedroom | 3 | 2 | — | — | container |
| 10 | matchbox | bedroom | 1 | 0.3 | — | — | container + striker |
| 11 | match ×7 | bedroom | 1 | 0.01 | — | single-use | fire source |
| 12 | paper | bedroom | 1 | 0.1 | — | burnable | writable |
| 13 | pen | bedroom | 1 | 0.1 | — | — | writing tool |
| 14 | pencil | bedroom | 1 | 0.1 | — | — | writing tool |
| 15 | wool-cloak | bedroom | 3 | 3 | **back** | tearable | warmth |
| 16 | sack | bedroom | 1 | 0.3 | **back/head** | tearable | container (cap 4) |
| 17 | needle | bedroom | 1 | 0.05 | — | — | sewing tool |
| 18 | thread | bedroom | 1 | 0.05 | — | — | sewing material |
| 19 | sewing-manual | bedroom | 1 | 0.1 | — | — | grants skill |
| 20 | brass-key | bedroom | 1 | 1 | — | — | **key** (cellar door) |
| 21 | chamber-pot | bedroom | 2 | 3 | **head** | shatters (ceramic) | helmet |
| 22 | cloth-scraps | storage | 1 | 0.15 | — | — | crafting material |
| 23 | candle-stub | storage | 1 | 0.1 | — | burns out (short) | light source |
| 24 | iron-key | storage | 1 | 0.5 | — | — | **key** (deep cellar door) |
| 25 | wine-bottle | storage | 2 | 1.5 | — | drink/break | beverage/weapon |
| 26 | small-crate | storage | 3 | 8 | — | breakable | container |
| 27 | grain-sack | storage | 3 | 15 | — | — | container |
| 28 | oil-lantern | storage | 2 | 1.2 | — | burns out (4hr) | wind-resistant light |
| 29 | rope-coil | storage | 3 | 3 | — | — | rope + binding |
| 30 | crowbar | storage | 3 | 3 | — | — | prying + weapon |
| 31 | oil-flask | storage | 1 | 0.8 | — | consumed (fuel) | lantern fuel |
| 32 | brass-spittoon | storage | 2 | 4 | **head** | — | durable helmet |
| 33 | incense-burner | deep cellar | 2 | 1.5 | — | — | container |
| 34 | tattered-scroll | deep cellar | 1 | 0.1 | — | — | lore/puzzle hint |
| 35 | offering-bowl | deep cellar | 2 | 2 | — | — | puzzle trigger |
| 36 | silver-key | deep cellar | 1 | 0.3 | — | — | **key** (crypt gate) |
| 37 | bronze-ring | crypt | 1 | 0.04 | **finger** | — | treasure |
| 38 | silver-dagger | crypt | 2 | 0.5 | — | — | weapon |
| 39 | burial-necklace | crypt | 1 | 0.08 | **neck** | — | treasure |
| 40 | tome | crypt | 3 | 2 | — | — | lore object |
| 41 | candle-stub ×2 | crypt | 1 | 0.1 | — | burns out | light source |
| 42 | burial-coins | crypt | 1 | 0.3 | — | — | treasure |
| 43 | vase | hallway | 2 | 2 | — | shatters (ceramic) | decorative |
| 44 | torch ×2 | hallway | 3 | 1.5 | — | burns out (3hr) | light source |
| 45 | well-bucket | courtyard | 3 | 2 | — | — | water tool |
| 46 | cobblestone | courtyard | 2 | 2 | — | — | blunt weapon |
| — | glass-shard ×2 | bedroom* | 1 | 0.1 | — | — | sharp tool |
| — | cloth ×N | anywhere* | 1 | 0.2 | — | — | crafting material |
| — | terrible-jacket | crafted* | 2 | 0.5 | **torso** | tearable | armor |

*Spawned/crafted objects — conditional on player actions

---

## What the Player Likely Carries to Level 2

### The Two-Hand Problem

The player has **2 hand slots**. With 46 portable objects available, the bottleneck is what fits in 2 hands + worn slots + container contents.

**Worn items (don't use hands):**
- Wool-cloak (back)
- Chamber-pot OR brass-spittoon (head) — but not both
- Bronze-ring (finger)
- Burial-necklace (neck)
- Terrible-jacket (torso) — if crafted

**Container strategy:** If the player carries the sack (capacity 4, worn on back or held), they can pack small items inside it.

### Maximum Theoretical Carry

**Hands (2 slots):**
- Hand 1: sack (containing up to 4 small items: e.g., brass-key, iron-key, silver-key, pin)
- Hand 2: oil-lantern (lit, fueled — reliable light source)

**Worn (no hand cost):**
- Back: wool-cloak (warmth)
- Head: brass-spittoon (durable helmet)
- Finger: bronze-ring
- Neck: burial-necklace
- Torso: terrible-jacket (if crafted)

**Sack contents (4 slots, max item size fits):**
- knife (size 1, weight 0.3)
- brass-key (size 1, weight 1)
- iron-key (size 1, weight 0.5)
- silver-key (size 1, weight 0.3)

**Total items crossing to Level 2: up to ~11** (2 held + 4 in sack + 5 worn)

### Most Likely Carry-Forward (Typical Player)

Based on critical-path gameplay and natural play patterns:

| Item | Likelihood | Rationale |
|------|-----------|-----------|
| **knife** | 🟢 Very High | Found early, versatile multi-tool, tiny (size 1) |
| **brass-key** | 🟡 Medium | Used to unlock cellar door — may drop after use |
| **iron-key** | 🟡 Medium | Used to unlock deep-cellar door — may drop after use |
| **silver-key** | 🟡 Medium | Only useful if crypt explored — optional path |
| **oil-lantern** (fueled) | 🟢 Very High | Best light source — wind-resistant, long burn |
| **crowbar** | 🟡 Medium | Used to open crate — bulky (size 3), may drop |
| **wool-cloak** | 🟢 Very High | Worn, no hand cost, warmth benefit |
| **matchbox** | 🟡 Medium | Useful but matches may be spent |
| **rope-coil** | 🟡 Medium | Versatile tool, but bulky (size 3) |
| **tome** | 🔴 Low | Lore object — only if crypt explored and player is curious |
| **silver-dagger** | 🔴 Low | Crypt-only, optional — weapon collectors |
| **burial-coins** | 🔴 Low | Crypt treasure — value unclear to player |
| **bronze-ring** | 🔴 Low | Crypt treasure, wearable — low priority |
| **burial-necklace** | 🔴 Low | Crypt treasure, wearable — low priority |
| **chamber-pot** | 🔴 Low | Novelty helmet — most players won't bother |
| **brass-spittoon** | 🔴 Low | Better helmet than pot — if player finds it |
| **candle-holder** | 🟡 Medium | Holds candle, but candle likely spent |
| **poison-bottle** | 🔴 Very Low | Suicidal to drink — most players avoid it |

### Realistic "Most Common" Loadout at Level 2 Entry

**Hands:** knife + oil-lantern (or matchbox)  
**Worn:** wool-cloak  
**Pockets/dropped nearby:** brass-key, iron-key  

---

## Consumables Destroyed During Level 1

These objects are consumed, spent, or destroyed during normal Level 1 gameplay and will NOT cross to Level 2:

| Object | How Consumed | When |
|--------|-------------|------|
| match ×7 | Single-use burn (lit → spent) | Lighting candle/objects — all 7 likely spent |
| candle | Burn timer (lit → spent) | ~expires mid-Level 1 (around storage cellar) |
| candle-stub ×3 | Short burn timer → spent | If found and lit — very short duration |
| oil-flask | Consumed when fueling lantern | Poured into lantern — empty shell remains |
| wine-bottle | Drink → empty, or break → shards | If player drinks or smashes it |
| poison-bottle | Drink → player death | Fatal — resets game, not carried |
| paper | Burnable if ignited | Unlikely but possible |
| chamber-pot | Shatters if dropped on stone | Ceramic fragility — breaks on hard surfaces |
| vase | Shatters if dropped | Ceramic — breaks on impact |

**Note on matches:** The 7 matches are the most critical consumable. A skilled player uses 1-2 (light candle, maybe light lantern). An inexperienced player may burn through all 7 before finding the lantern. Once all matches and the candle are spent, the oil lantern (if fueled) is the only remaining light source.

---

## Passage Constraints Summary

The critical path passes through several exits with carry restrictions:

| Passage | Max Size | Max Weight | Hands Free? |
|---------|----------|------------|-------------|
| Bedroom → Cellar (trap door) | 3 | 30 | No |
| Cellar → Storage (iron door) | 4 | 50 | No |
| Storage → Deep Cellar (iron door) | 4 | 50 | No |
| Deep Cellar → Hallway (stairway) | 4 | 50 | No |
| Deep Cellar → Crypt (archway) | 3 | 30 | No |
| **Hallway → Level 2 (grand staircase)** | **5** | **50** | **No** |
| Bedroom → Courtyard (window) | 2 | 10 | **Yes** |

**Bottleneck:** The trap door (size ≤ 3) is the tightest on the critical path. Objects of size 4+ cannot pass through the bedroom→cellar trap door. This blocks: rug (5), curtains (4), bed-sheets (3 — fits), blanket (3 — fits).

The hallway→Level 2 staircase is the most generous (size ≤ 5, weight ≤ 50). Everything that reached the hallway can go to Level 2.

**Wind effect:** The deep-cellar→hallway stairway extinguishes candles (not lanterns). Players carrying a lit candle lose their light source at this transition. The oil lantern (wind-resistant) survives.

---

## Recommendations for Level 2 Design

1. **Expect the knife.** It's the most universally carried tool — small, useful, found early. Design puzzles that either leverage or neutralize it.

2. **Expect the oil lantern** as the primary light source entering Level 2. The hallway has torches (light_level 3), so players might not carry a light — but cautious players will.

3. **Don't assume keys are carried.** Players may drop brass-key and iron-key after using them. Design Level 2 locks with new keys or make old keys optionally useful.

4. **The crypt path is optional.** Assume most first-time players skip the crypt entirely. The tome, silver-dagger, bronze-ring, burial-necklace, and burial-coins are bonus items. Don't gate Level 2 progress on them.

5. **The crowbar is the wildcard.** Bulky (size 3) but powerful (prying + weapon). Some players keep it, most drop it after opening the crate.

6. **The wool-cloak is a freebie.** Worn on back, no hand cost, provides warmth. Nearly every player will have it. Consider cold environments in Level 2 that reward it.

7. **The sack multiplies carry capacity.** A savvy player can carry 4 extra small items in the sack. Consider whether Level 2 puzzles should reward or penalize hoarding.

8. **`restricted_objects` in level-01.lua is empty.** Currently no items are blocked from crossing levels. If any items should NOT enter Level 2, add them to this list with diegetic removal (e.g., a guard confiscates weapons, a gate is too narrow for the crowbar).

9. **Worst-case: player arrives empty-handed.** It's possible (if unlikely) for a player to drop everything in the hallway before ascending. Level 2 should have basic tools available early.

10. **The spittoon is NOT yet placed** (BUG-147). If placed before Level 2 ships, add it to this audit.

---

## Audit Metadata

- **Objects scanned:** 56 unique types across 7 rooms + 3 conditional spawns
- **Portable objects:** 46 (43 base + 3 conditional)
- **Non-portable (fixed):** 25
- **Wearable:** 6 (wool-cloak, sack, chamber-pot, brass-spittoon, bronze-ring, burial-necklace) + 1 crafted (terrible-jacket)
- **Keys:** 3 (brass-key, iron-key, silver-key)
- **Light sources:** 6 types (match, candle, candle-stub, oil-lantern, torch, candle-holder w/ candle)
- **Weapons:** 4 (knife, crowbar, silver-dagger, cobblestone)
- **Consumables:** 9 types destroyed during normal play
