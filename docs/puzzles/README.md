# Puzzles

Puzzle documentation is organized in two locations:

1. **Level-specific puzzles** live in `docs/levels/NN/puzzles/` — these are assigned to a specific game level and may be 🟢 In Game or 🟡 Wanted.
2. **Theorized puzzles** (🔴) live here in `docs/puzzles/` — these are designed concepts awaiting Wayne's approval, not yet assigned to a level.

---

## Level 1 Puzzles (001–016)

See [`docs/levels/01/puzzles/`](../levels/01/puzzles/) for all Level 1 puzzle documentation.

| # | Puzzle | Status | Difficulty |
|---|--------|--------|-----------|
| 001 | [Light the Room](../levels/01/puzzles/001-light-the-room.md) | 🟢 In Game | ⭐⭐ |
| 002 | [Poison Bottle](../levels/01/puzzles/002-poison-bottle.md) | 🟡 Wanted | ⭐⭐ |
| 003 | [Write in Blood](../levels/01/puzzles/003-write-in-blood.md) | 🟡 Wanted | ⭐⭐⭐ |
| 004 | [Inventory Management](../levels/01/puzzles/004-inventory-management.md) | 🟡 Wanted | ⭐ |
| 005 | [Bedroom Escape](../levels/01/puzzles/005-bedroom-escape.md) | 🔴 Theorized | ⭐⭐⭐ |
| 006 | [Iron Door Unlock](../levels/01/puzzles/006-iron-door-unlock.md) | 🟢 In Game | ⭐⭐ |
| 007 | [Trap Door Discovery](../levels/01/puzzles/007-trap-door-discovery.md) | 🟢 In Game | ⭐⭐⭐ |
| 008 | [Window Escape](../levels/01/puzzles/008-window-escape.md) | 🟢 In Game | ⭐⭐⭐⭐ |
| 009 | [Crate Puzzle](../levels/01/puzzles/009-crate-puzzle.md) | 🔴 Theorized | ⭐⭐ |
| 010 | [Light Upgrade](../levels/01/puzzles/010-light-upgrade.md) | 🔴 Theorized | ⭐⭐ |
| 011 | [Ascent to Manor](../levels/01/puzzles/011-ascent-to-manor.md) | — | — |
| 012 | [Altar Puzzle](../levels/01/puzzles/012-altar-puzzle.md) | — | — |
| 013 | [Courtyard Entry](../levels/01/puzzles/013-courtyard-entry.md) | — | — |
| 014 | [Sarcophagus Puzzle](../levels/01/puzzles/014-sarcophagus-puzzle.md) | — | — |
| 015 | [Draft Extinguish](../levels/01/puzzles/puzzle-015-draft-extinguish.md) | — | — |
| 016 | [Wine Drink](../levels/01/puzzles/puzzle-016-wine-drink.md) | — | — |

---

## Theorized Puzzles — Real-World Object Interactions (020–031)

These puzzles use **real-world objects in realistic ways**. They are 🔴 Theorized — designed by Sideshow Bob, awaiting Wayne's approval. They are not assigned to a specific level yet.

### Index

| # | Puzzle | Difficulty | Effects Pipeline? | New Objects Needed? |
|---|--------|-----------|-------------------|---------------------|
| 020 | [Wine Wound Wash](020-wine-wound-wash.md) | ⭐⭐⭐ | ✅ Yes | ❌ No |
| 021 | [Improvised Torch](021-improvised-torch.md) | ⭐⭐⭐ | ✅ Yes | ❌ No |
| 022 | [Smoke Draft Reveal](022-smoke-draft-reveal.md) | ⭐⭐⭐⭐ | ❌ No | ✅ sealed-wall-section |
| 023 | [Counterweight Gate](023-counterweight-gate.md) | ⭐⭐⭐ | ✅ Yes | ✅ pressure-platform, portcullis |
| 024 | [Mirror Light Redirect](024-mirror-light-redirect.md) | ⭐⭐⭐⭐ | ❌ No | ✅ hand-mirror, light-beam |
| 027 | [Glass Edge Escape](027-glass-edge-escape.md) | ⭐⭐⭐ | ✅ Yes | ❌ No |
| 028 | [Wax Seal Secret](028-wax-seal-secret.md) | ⭐⭐⭐⭐ | ❌ No | ✅ wax-written-scroll, charcoal |
| 029 | [Bandage Before Climb](029-bandage-before-climb.md) | ⭐⭐⭐ | ✅ Yes | ❌ No |
| 030 | [Rag and Oil Molotov](030-rag-and-oil-molotov.md) | ⭐⭐⭐⭐ | ✅ Yes | ✅ wooden-barricade |
| 031 | [Triage Under Pressure](031-triage-under-pressure.md) | ⭐⭐⭐⭐⭐ | ✅ Yes | ❌ No |

### Summary by Category

**🔥 Fire Mastery Progression:** 021 → 030 (torch → firebomb — builds on fire-crafting knowledge)

**🩹 Injury System Puzzles:** 020, 029, 031 (wine wash → capability gating → triage — builds on injury treatment mastery)

**🔍 Environmental Physics:** 022, 024 (smoke reveals drafts, mirrors redirect light — observation-as-puzzle)

**🏋️ Weight & Mechanics:** 023 (counterweight system — objects have physical properties)

**✂️ Improvised Tools:** 027 (breaking objects creates new tools — destruction-as-creation)

**📜 Hidden Information:** 028 (invisible wax writing revealed by heat or soot — forensic investigation)

### Effects Pipeline Usage

6 of 10 puzzles use the Effects Pipeline for injury effects:
- **020** Wine Wound Wash — `add_status` for clean_wound bonus
- **021** Improvised Torch — `inflict_injury` burn on misuse
- **023** Counterweight Gate — `inflict_injury` crushing-wound when gate falls
- **027** Glass Edge Escape — `inflict_injury` minor-cut from glass handling
- **029** Bandage Before Climb — `inflict_injury` bruise from fall on failed climb
- **031** Triage Under Pressure — multiple simultaneous `inflict_injury` effects in atomic array

### New Objects Needed

These puzzles require objects that don't yet exist in `src/meta/objects/`. Flanders to build:

| Object | Needed By | Description |
|--------|-----------|-------------|
| sealed-wall-section | 022 | Room element with hidden draft; states: sealed → cracked → open |
| pressure-platform | 023 | Stone platform with weight threshold; connected to portcullis via chain |
| portcullis | 023 | Heavy iron gate; states: closed → partial → open. Counterweight-driven |
| hand-mirror | 024 | Portable mirror; `is_reflective: true`, `is_mirror: true` |
| light-beam | 024 | Environmental element; directional light that can be reflected |
| wax-written-scroll | 028 | Parchment with hidden wax writing; revealed by heat or soot |
| charcoal | 028 | Marking material from burnt wood; used for soot-rubbing technique |
| wooden-barricade | 030 | Flammable obstacle; `is_flammable: true`, `blocks_exit: true` |

---

## Naming Convention

**Files MUST use 3-digit zero-padded numbers:** `NNN-slug.md`

Examples: `001-light-the-room.md`, `020-wine-wound-wash.md`

**DO NOT use 1 or 2 digit prefixes** (e.g., `1-`, `01-`). Always pad to 3 digits so files sort correctly up to 999 puzzles.

**Numbering ranges:**
- 001–016: Level 1 puzzles (in `docs/levels/01/puzzles/`)
- 020–031: Theorized real-world object puzzles (in `docs/puzzles/`)
- 032+: Future theorized puzzles

---

## Puzzle Classification

| Status | Meaning | Location |
|--------|---------|----------|
| 🟢 In Game | Implemented, tested, and playable | `docs/levels/NN/puzzles/` |
| 🟡 Wanted | Designed and approved by Wayne; awaiting implementation | `docs/levels/NN/puzzles/` |
| 🔴 Theorized | Conceptualized; awaiting Wayne's approval | `docs/puzzles/` (here) |

See [`docs/design/puzzles/puzzle-classification-guide.md`](../design/puzzles/puzzle-classification-guide.md) for the full lifecycle.

---

## Design Philosophy

All puzzles in this game follow these core principles:

1. **Tools enable verbs** — Without the right tool (matchbox, pen, knife), certain actions are impossible.
2. **Code is state** — When a puzzle changes the world (candle lights, paper gains writing, object breaks), the object's definition is rewritten. This is not a flag flip — it's a true state mutation.
3. **Multiple paths to victory** — Most puzzles have alternative solutions. Exploration and creativity are rewarded.
4. **Consequences matter** — Failure states exist. Wasting resources has real costs. Wrong actions have real penalties.
5. **Teach through discovery** — Puzzles teach mechanics by requiring players to use them. The light puzzle teaches tools, darkness, and discovery.
6. **Real-world logic** — Puzzles should feel like things a real person would do. Wine cleans wounds. Smoke follows drafts. Glass cuts rope. If it makes sense in reality, it should work in the game.

---

## See Also

- **Puzzle Classification Guide:** [`docs/design/puzzles/puzzle-classification-guide.md`](../design/puzzles/puzzle-classification-guide.md)
- **Puzzle Rating System:** [`docs/design/puzzles/puzzle-rating-system.md`](../design/puzzles/puzzle-rating-system.md)
- **Puzzle Design Patterns:** [`docs/design/puzzles/puzzle-design-patterns.md`](../design/puzzles/puzzle-design-patterns.md)
- **Effects Pipeline:** [`docs/architecture/engine/effects-pipeline.md`](../architecture/engine/effects-pipeline.md)
- **Event Hooks:** [`docs/architecture/engine/event-hooks.md`](../architecture/engine/event-hooks.md)
- **Injury System:** [`docs/design/injuries/`](../design/injuries/)
- **Object Designs:** [`docs/design/objects/`](../design/objects/)

