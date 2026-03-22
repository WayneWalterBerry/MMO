# Verb Design Catalog

This directory contains detailed design documentation for each **main verb** in the MMO engine. Each file documents the verb's sensory requirements, syntax, behavior, and design principles.

> **Key Design Principle:** Sensory mode is now a first-class design distinction. All verbs must document whether they require light (vision only) or work in darkness (multi-sense).

## Verb Categories

### 🔍 Vision Verbs (Light Required)
- **[look](look.md)** — Vision-only observation
- **[examine](examine.md)** — Close inspection (vision-focused, touch fallback in darkness)

### 🔎 Discovery Verbs (All Senses)
- **[search](search.md)** — All-sense discovery and exploration
- **[find](find.md)** — Universal search verb using all senses

### 👆 Touch & Tactile Verbs
- **[feel](feel.md)** — Grope around or feel specific objects
- **[touch](touch.md)** — Direct tactile interaction

### 📖 Sensory Observation
- **[listen](listen.md)** — Hearing-based observation
- **[smell](smell.md)** — Olfactory exploration
- **[taste](taste.md)** — Taste testing (risky)
- **[read](read.md)** — Reading text (may teach skills)

### 🎒 Item Acquisition
- **[take](take.md)** — Pick up an object (acquire)
- **[grab](grab.md)** — Alias for take
- **[get](get.md)** — Alias for take; also "get X from Y"
- **[pick](pick.md)** — Pick up or pick lock (attempts)

### 🚪 Container & Object Interaction
- **[open](open.md)** — Open a container or door
- **[close](close.md)** — Close a container or door
- **[put](put.md)** — Place an object in/on a container
- **[drop](drop.md)** — Release an object
- **[pull](pull.md)** — Detach parts or move objects
- **[push](push.md)** — Move heavy objects aside
- **[move](move.md)** — General spatial movement
- **[lift](lift.md)** — Lift objects or reveal what's underneath
- **[unlock](unlock.md)** — Unlock locked containers/doors

### 🧥 Equipment & Wearing
- **[wear](wear.md)** — Put on wearable items
- **[remove](remove.md)** — Take off worn items
- **[inventory](inventory.md)** — Check what you're carrying

### 🔥 Fire & Light Verbs
- **[light](light.md)** — Light a fire or flame
- **[extinguish](extinguish.md)** — Put out a flame
- **[burn](burn.md)** — Set something on fire
- **[strike](strike.md)** — Strike a match

### 🗡️ Damage & Destruction
- **[break](break.md)** — Break something breakable
- **[tear](tear.md)** — Tear fabric apart
- **[stab](stab.md)** — Stabbing attack or self-infliction
- **[cut](cut.md)** — Cut something with a tool
- **[slash](slash.md)** — Slashing attack or self-harm

### 🍽️ Consumption
- **[eat](eat.md)** — Eat edible objects
- **[drink](drink.md)** — Drink from containers
- **[pour](pour.md)** — Pour out liquids

### 🧵 Crafting & Creation
- **[sew](sew.md)** — Sew materials together (requires skill)
- **[write](write.md)** — Write text on surfaces
- **[apply](apply.md)** — Apply healing items to wounds

### 🏃 Movement
- **[go](go.md)** — Move in a direction
- **[walk](walk.md)** — Walk in a direction
- **[run](run.md)** — Run in a direction
- **[head](head.md)** — Head in a direction
- **[climb](climb.md)** — Climb stairs or obstacles
- **[enter](enter.md)** — Enter through an exit
- **[direction](direction.md)** — Cardinal (n/s/e/w) and vertical (u/d) movement

### 😴 Rest & Time
- **[sleep](sleep.md)** — Sleep for extended periods
- **[rest](rest.md)** — Alias for sleep

### 📊 Status & Information
- **[inventory](inventory.md)** — Check carrying status, health, injuries, time, help

### 🐛 Meta
- **[report-bug](report-bug.md)** — Report a bug

---

## Design Principles

### 1. Sensory Mode is Central
Every verb must document its sensory requirements:
- **Vision only** — Requires light (look, examine in daylight)
- **All senses** — Works in darkness (search, find, feel)
- **Fallback** — Adaptive behavior based on light (examine uses touch in dark)

### 2. Verb Synonyms Belong in the Main Verb File
- `take`, `get`, `grab`, `pick up` → documented in **take.md**
- `search`, `find` → distinct verbs with nuances
- Aliases listed under **Synonyms** section in each file

### 3. Behavior Documentation
Each file includes:
- Syntax variations (all ways to invoke)
- Sensory mode (vision/touch/hearing/smell/taste/all)
- Hand/inventory requirements
- Search order (hands-first for interaction verbs, room-first for acquisition)
- Edge cases and error states

### 4. Design Notes Section
Captures Wayne's directives and architectural decisions that affect verb behavior.

---

## Verb Implementation Hierarchy

1. **Main verbs** — Have their own dedicated handlers
2. **Aliases** — Point to main verb handler (e.g., `get → take`)
3. **Compound phrases** — Converted by preprocessor (e.g., "search around" → search "")
4. **Question patterns** — Normalized by natural language preprocessing

See `src/engine/parser/preprocess.lua` for phrase → verb mappings.

---

## Related Documentation

- **[verb-system.md](../verb-system.md)** — Overview of the verb system architecture
- **[parser-tier-1-basic.md](../../architecture/engine/parser-tier-1-basic.md)** — How verbs are dispatched
- **[parser-tier-2-compound.md](../../architecture/engine/parser-tier-2-compound.md)** — Phrase similarity fallback
- **[player-sensory.md](../../architecture/player/player-sensory.md)** — Light/dark system and sensory perception
- **[inventory.md](../../architecture/player/inventory.md)** — Hands, bags, worn items, search order

---

## Quick Reference: Sensory Modes

| Mode | Works in Dark? | Use | Examples |
|------|---|---|---|
| **Vision only** | ❌ | Observation requiring light | look, examine (daylight), read |
| **All senses** | ✅ | Discovery in any condition | search, find, feel, listen, smell |
| **Adaptive** | ✅ | Context-aware fallback | examine (dark→touch, light→vision) |

---

**Last updated:** 2026-03-22  
**Ownership:** Brockman (Documentation Lead) with Smithers (UI) and Bart (Architecture)
