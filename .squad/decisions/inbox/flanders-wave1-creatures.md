# Decision: WAVE-1 Creature Data Delivered

**Author:** Flanders
**Date:** 2026-07-20
**Affects:** Nelson (tests), Moe (room placement), Bart (engine creature support)

## Decision

WAVE-1 creature data files are committed on `main` (c770b74). Four creatures (cat, wolf, spider, bat) and chitin material are ready for GATE-1 validation.

## Details

### Files Created
| File | GUID | Size | HP | Key Feature |
|------|------|------|----|-------------|
| `src/meta/creatures/cat.lua` | `{46c2583c-...}` | small | 15 | Prey: rat |
| `src/meta/creatures/wolf.lua` | `{e69fc5e8-...}` | medium | 40 | Territorial, hide armor |
| `src/meta/creatures/spider.lua` | `{f67e3d8b-...}` | tiny | 3 | Venom bite (60%), chitin armor |
| `src/meta/creatures/bat.lua` | `{52e32931-...}` | tiny | 3 | Light-reactive, speed 9 |
| `src/meta/materials/chitin.lua` | `{fc0f2712-...}` | — | — | Insect exoskeleton material |

### Structure Notes for Downstream
- Spider uses **non-standard body_tree zones**: `cephalothorax`, `abdomen`, `legs` — engine must support arbitrary zone names
- Wolf is the first creature with **natural_armor** array — Bart should verify armor lookup in combat engine
- Bat starts in `alive-roosting` (not `alive-idle`) — FSM must handle creature-specific initial states
- All creatures follow rat.lua template structure exactly

### Action Required
- **Nelson:** Create test files (test-cat, test-wolf, test-spider, test-bat) per WAVE-1 test plan
- **Moe:** Place creatures in rooms (cat→courtyard, wolf→hallway, spider→deep-cellar, bat→crypt)
- **Bart:** Verify body_tree zone flexibility and natural_armor support before WAVE-2
