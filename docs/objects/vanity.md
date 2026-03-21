# Vanity — Object Design

## Description
A solid oak vanity with ornate mirror, drawer, and surfaces. Mirror can be broken (spawns glass-shard). Four FSM states: closed/open × intact/broken.

**Material:** `oak`

## FSM States

```
closed ↔ open
  ↓ (break)   ↓ (break)
closed_broken ↔ open_broken
```

- **closed** — Drawer closed, mirror intact. Reflection stares back.
- **open** — Drawer open, mirror intact. Inside accessible.
- **closed_broken** — Mirror shattered, drawer closed. Glass shards on surface. Weight drops to 38 (from 40). "reflective" category removed.
- **open_broken** — Mirror shattered, drawer open. Weight 38.

## Sensory Descriptions

| State | Look | Feel | Smell |
|-------|------|------|-------|
| closed | Oak vanity, ornate gilt mirror, drawer closed | Smooth oak, cold mirror glass, brass pull | Rosewater and powder |
| open | Oak vanity, drawer open, mirror reflects | Smooth oak, mirror glass, drawer open | Rosewater, musty drawer air |
| closed_broken | Gilt frame with jagged glass teeth, shards on surface | CAREFUL — glass shards, jagged edges | Perfume and mineral broken glass |
| open_broken | Broken mirror, open drawer, glass glinting | Glass shards everywhere, drawer open | Perfume and mineral tang |

## Surfaces

- **top:** capacity 6, max_item_size 4
- **inside (drawer):** capacity 4, max_item_size 2. Accessible only when open.
- **mirror_shelf:** capacity 2, max_item_size 1 (only when mirror intact)

## Transitions

| From | To | Verb | Mutate |
|------|-----|------|--------|
| closed | open | open | `keywords = { add = "open" }` |
| open | closed | close | `keywords = { remove = "open" }` |
| closed_broken | open_broken | open | `keywords = { add = "open" }` |
| open_broken | closed_broken | close | `keywords = { remove = "open" }` |
| closed | closed_broken | break | `keywords = { add = "broken" }` — spawns glass-shard |
| open | open_broken | break | `keywords = { add = "broken" }` — spawns glass-shard |

## Properties

- **Size:** 8, **Weight:** 40 (38 when broken), **Portable:** No
- **Categories:** furniture, wooden, reflective (intact) / furniture, wooden (broken)
- **Keywords:** vanity, mirror, vanity mirror, dressing table, desk, table, looking glass, oak vanity

## What Changed (2026-07-20)

- Added `material = "oak"` metadata field
- Added `mutate` fields: keywords ±open for drawer, +broken for mirror break
