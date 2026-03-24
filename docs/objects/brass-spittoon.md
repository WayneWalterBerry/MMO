# Brass Spittoon — Object Design

## Description

A tarnished brass vessel with a wide rim and deep bowl, darkened by years of accumulated tobacco stains. The inside still bears the olfactory scars of its former purpose. Weathered and heavy, it makes an unconventional but surprisingly effective piece of armor — a durable, dent-resistant alternative to the fragile ceramic chamber pot.

**Material:** `brass` (hardness 6, density 8500, fragility 0.1)

**Physical Properties:**
- Size: 2
- Weight: 2.5 (brass is heavy — density 8500 kg/m³)
- Portable: Yes
- Categories: brass, container, wearable, durable, unorthodox-armor

## States

### FSM Lifecycle: `intact` → `stained` → `dented`

**Design Note:** Brass doesn't shatter (fragility 0.1). It dents. The spittoon accumulates cosmetic damage through wear, but structural failure is not in its playbook.

| State | Trigger | Description | Smell Changed? |
|-------|---------|-------------|----------------|
| `intact` | Initial state | Tarnished but unblemished brass | No |
| `stained` | (Optional: first wear, or event_output) | Interior stains become more pronounced after use | Intensifies tobacco aroma |
| `dented` | Impact during combat (armor degradation FSM) | Surface accumulates dents and dings from repeated hits | No (same smell) |

## Sensory Descriptions

| Sense | Description |
|-------|-------------|
| **Look** | A tarnished brass bowl with a wide rim, darkened by tarnish and time. The interior bears brown tobacco stains. It's clearly old, clearly used, and clearly inappropriate as a hat. |
| **Feel** | Cool, heavy brass—smooth in places, dented in others. The rim is slightly rough where tarnish has built up. Weighs considerably more than you'd expect. |
| **Smell** | A faint but unmistakable tobacco aroma, aged and stale. Reminiscent of old cigar lounges and regrettable life choices. |
| **Listen** | **(Ambient)** Quiet. **(When tapped/struck)** Rings with a clear brass bell note that echoes slightly. |
| **Taste** | **(Do not lick this)** Bitter, metallic, with undertones of old tobacco tar. Your mouth coats with a thin metallic film. This is not food. |

### Worn State (When Equipped as Helmet)

**Smell (worn):** `"The inside still smells of old tobacco. You catch whiffs of it every time you move. This was clearly a spittoon in a previous life, and your head is now experiencing that history."`

**Appearance (mirror):** `"A heavy brass spittoon sits incongruously atop your head, rims just above your eyes. You look ridiculous, heavy, and vaguely brass-colored."`

**Feel (worn):** `"The brass rim digs slightly into your forehead—the fit is loose and awkward. It's clearly not designed to be head armor."`

**Listen (worn, during movement):** `"The spittoon shifts slightly as you move, occasionally scraping against your hair or shoulders with tiny metallic sounds."`

## Wearable — Durable Makeshift Head Armor

### Equip Metadata

| Property | Value | Notes |
|----------|-------|-------|
| `wear.slot` | `head` | Equips to head slot |
| `wear.layer` | `outer` | Outer layer (conflicts with other outer headgear) |
| `wear.coverage` | `0.9` | Nearly complete head coverage; back of neck exposed |
| `wear.fit` | `makeshift` | Not designed for head wear; clumsy but functional (×0.5 protection multiplier) |
| `is_helmet` | `true` | Engine helmet detection (armor + concussion reduction) |
| `wear_slot` | `head` | Legacy field for engine helmet detection |

### Protection & Durability

**Armor Profile (vs Chamber Pot):**

| Factor | Brass Spittoon | Ceramic Pot | Winner |
|--------|---|---|---|
| **Material hardness** | 6 | 7 | Pot (+1) |
| **Density** | 8500 | 2300 | Spittoon (3.7× denser) |
| **Coverage** | 0.9 | 0.8 | Spittoon |
| **Base protection** | ~4.0–4.5 | ~3.5–4.0 | Spittoon |
| **Adjusted (makeshift)** | ~1.8–2.0 | ~1.4–1.6 | Spittoon |
| **Fragility** | 0.1 | 0.7 | Spittoon (98% more durable) |
| **Narrative durability** | Takes 20+ hits | Cracks in 2–3 hits | Spittoon (cosmic difference) |

**Key Insight:** The spittoon trades slight protection for incredible durability. A pot breaks quickly. A spittoon just gets uglier.

### Behavior

- **Wear:** `wear spittoon` / `put spittoon on head` → equips to head slot
  - Engine narration (makeshift armor): *"You place the heavy brass spittoon on your head. It settles awkwardly, and the smell of old tobacco immediately hits you. This is ridiculous, but surprisingly solid."*
  - First-time flavor: *"The inside still smells of old tobacco. You catch whiffs of it every time you move."*
- **Remove:** `remove spittoon` / `take off spittoon` → frees head slot
- **Conflict:** Can't wear spittoon if another outer-layer headgear is equipped. Player must remove existing headgear first.

### Combat Degradation

The spittoon does NOT shatter when hit. It dents. The FSM follows this progression:

1. **Intact:** Tarnished but unblemished
2. **Stained (cosmetic):** Interior stains darken further (smell unchanged)
3. **Dented (cosmetic):** Surface accumulates visible dents and dings after repeated impacts

After 20+ hits, the spittoon looks "thoroughly battered" but remains structurally sound and fully protective.

**Narration Examples:**

```
[Enemy swings at your head]
Your brass spittoon rings like a bell and dents inward slightly, 
but holds firm.

[After several more hits]
Your spittoon is now covered in dents and scratches, but 
structurally sound. It's clearly seen combat.

[Even after 20+ hits]
Your spittoon absorbs the impact with a dull THUD and doesn't 
break. The damage accumulates, but it endures.
```

## Container

The brass spittoon also functions as a container for small items and liquids—it is, after all, an actual spittoon.

- **Capacity:** 2
- **Size class:** Small
- **Restrictions:** No large items. Reasonable for coins, scrolls, vials, small food items, etc.
- **Flavor:** Putting items in the spittoon is gross. The smell intensifies. Items that absorb liquids (like cloth) will smell of tobacco for days.

## Keywords & Aliases

- `spittoon` (primary)
- `brass spittoon`
- `brass bowl`
- `vessel`
- `cuspidor` (formal term)
- `spit bowl`
- `tobacco bowl`
- `brass vessel`
- `helmet` (when worn)
- `hat` (when worn, colloquial)

## Weight & Physical Impact

**Weight = 2.5** (relative to typical object weight of ~1.0 for a ceramic pot)

Brass is DENSE. This matters for:

1. **Carrying:** Player can still carry it as a normal item, but it's noticeably heavy
2. **Dropping on foot:** **(Future integration)** If dropped on player's own foot, causes pain proportional to brass density
3. **Movement penalty:** **(Future stamina system)** Wearing the spittoon as armor costs stamina faster than lighter helmets due to neck strain

## Design Principles: Brass vs Ceramic

### Ceramic Chamber Pot (Contrast)

- **Narrative:** "It's a pot. You put it on your head. It breaks."
- **Durability:** Fragile (0.7) — cracks in 2–3 hits, shatters soon after
- **Aesthetic:** Comedic desperation — you're using dishware as armor
- **Weight:** Light (appropriate to the object)
- **Best use case:** Early-game makeshift, survival comedy, story beat of improvisation
- **Smell when worn:** Faint (ceramic is porous but sealed by glaze)

### Brass Spittoon (This Object)

- **Narrative:** "It's an old bar vessel. You put it on your head. It endures."
- **Durability:** Tough (0.1) — accumulates dents over 20+ hits, essentially never shatters
- **Aesthetic:** Grotesque but functional — you're wearing actual bar furniture as armor, and it's working
- **Weight:** Heavy (2.5) — you feel the burden
- **Best use case:** Mid-game discovery, unexpectedly effective armor, persistent reminder of poor life choices
- **Smell when worn:** Intense (open bowl structure; tobacco aroma fills your nostrils constantly)

### Design Insight

Both are wearable containers that happen to fit a head. Both are "wrong" armor in a funny way. But they tell opposite stories through material properties alone:

- Ceramic says: "You found a tool for a desperate moment. Use it now, before it breaks."
- Brass says: "You found a tool that will outlast your need for it. Wear it, and feel the weight of every dent."

This is emergent gameplay from material properties. The engine doesn't hardcode "pot breaks fast, spittoon lasts long." The hardness and fragility values make this inevitable.

## Gameplay Tradeoff

**Why choose spittoon over pot?**

| Reason | Pot | Spittoon |
|--------|-----|----------|
| Durability | Breaks quickly (story beat) | Lasts forever (utility) |
| Smell | Faint | Overpowering |
| Weight | Light | Heavy (future stamina penalty) |
| Comedy | Peak absurdity | Grim endurance |
| Protection | 1.4–1.6 | 1.8–2.0 |
| Narrative Arc | "This won't last" | "Why am I still wearing this?" |

## Properties

- **Size:** 2
- **Weight:** 2.5
- **Portable:** Yes
- **Categories:** brass, container, wearable, durable, unorthodox-armor, improvised, furniture
- **Value:** 15 (brass is moderately valuable; spittoon is cultural artifact)

## Sensory Deep Dive

### On Feel

**Unequipped:** `"Cool, heavy brass. The rim is smooth in some places, rough with tarnish in others. It's clearly old—dents and dings dot the exterior. Weighs considerably more than it looks."`

**Worn:** `"The brass rim digs slightly into your forehead, and the weight settles uncomfortably on your skull. Your neck muscles are already complaining. This is not head armor; this is a heavy bowl. But it's a *protective* heavy bowl."`

### On Smell

**Unequipped:** `"Stale tobacco, aged and bitter. The kind of smell you find in old bars where people made life choices they regret. The brass itself has that faint metallic undertone—not unpleasant, just old."`

**Worn:** `"Oh god. With your nose *inside* the rim, the tobacco aroma is overwhelming. Every breath carries notes of old cigars, spit, and resignation. This was definitely used for its intended purpose. Repeatedly. By many people."`

### On Listen

**Ambient (unequipped):** Quiet.

**Struck:** `"It rings with a clear, high brass note—the kind of sound that echoes in a bar and signals someone's had too much to drink."`

**Worn during movement:** `"The spittoon shifts slightly with each step, scraping against your shoulders and hair with tiny, irritating metallic sounds."`

### On Taste

**Why would you lick it?** But if you do: `"Bitter. Metallic. A thin film coats your tongue—old brass oxidation mixed with centuries-old tobacco tar residue. Your mouth recoils. This is not a snack."`

## Related Objects

- **Chamber Pot** (`docs/objects/chamber-pot.md`) — The fragile ceramic counterpart. Compare protection (pot 1.4–1.6, spittoon 1.8–2.0) and durability (pot shatters in hits, spittoon dents forever).
- **Steel Helm** (not yet documented) — The "correct" armor. Compare protection (steel 6.0–7.0 vs spittoon 1.8–2.0) and aesthetic (professional vs ridiculous).

## Changelog

### 2026-03-24 — Initial Design Document (Phase D1)
- Comprehensive design doc covering physical description, sensory properties, wearable mechanics, and design philosophy
- Established brass vs ceramic contrast as core design principle
- Documented FSM states (intact → stained → dented) with durability guarantee (never shatters)
- Included weight specifications (2.5, relative to ceramic pot 1.0) for future stamina system integration
- Added all sensory descriptions (feel, smell, listen, taste) as required
- Provided gameplay tradeoff table (pot vs spittoon) and design insights
- Emphasized material properties as source of truth: brass (hardness 6, density 8500, fragility 0.1) is the single source from which all durability behavior emerges

## Implementation Notes

**For Flanders (Phase D2):**

```lua
-- src/meta/objects/brass-spittoon.lua
return {
    id = "brass-spittoon",
    name = "a tarnished brass spittoon",
    material = "brass",           -- hardness 6, density 8500, fragility 0.1
    
    wear = {
        slot = "head",
        layer = "outer",
        coverage = 0.9,           -- nearly complete head coverage
        fit = "makeshift",        -- × 0.5 protection multiplier
    },
    
    is_helmet = true,
    wear_slot = "head",           -- legacy field
    
    -- Container capacity
    capacity = 2,
    
    -- Weight specification
    weight = 2.5,
    
    -- Keywords for search/identification
    keywords = {
        "spittoon", "brass spittoon", "brass bowl", "vessel", 
        "cuspidor", "spit bowl", "tobacco bowl"
    },
    
    -- Sensory callbacks (all required)
    on_feel = "Cool, heavy brass. The rim is smooth in some places, rough with tarnish in others. It weighs considerably more than it looks.",
    on_smell = "Stale tobacco, aged and bitter. The kind of smell you find in old bars where people made regrettable choices.",
    on_listen = "Quiet by default. If struck, it rings with a clear brass note.",
    on_taste = "Bitter. Metallic. Your mouth recoils. Not a snack.",
    
    -- Worn-state sensory descriptions
    on_feel_worn = "The brass rim digs slightly into your forehead. The weight settles uncomfortably. Your neck muscles are already complaining.",
    on_smell_worn = "The inside still smells of old tobacco. Every breath carries whiffs of aged cigars and resignation. This was clearly used many times for its intended purpose.",
    
    -- Mirror appearance when worn
    appearance = {
        worn_description = "A heavy brass spittoon sits incongruously atop your head, rim just above your eyes. You look ridiculous, heavy, and vaguely brass-colored."
    },
    
    -- FSM states (degradation is cosmetic only)
    states = {
        intact = "Tarnished but unblemished brass",
        stained = "Interior stains darken after use",
        dented = "Surface accumulates dents from repeated impacts"
    }
}
```

**Design Philosophy Summary:**

- Brass spittoon = durable alternative to ceramic pot
- Protection value: 1.8–2.0 (vs pot's 1.4–1.6)
- Durability: fragility 0.1 (dents forever, never shatters)
- Smell penalty: intense tobacco aroma when worn (narrative consequence)
- Weight penalty: 2.5 (will interact with future stamina system)
- Container: holds 2 small items (fits its purpose)
- Keywords: "spittoon", "cuspidor", "spit bowl", "brass bowl"
