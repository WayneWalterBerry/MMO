# Willie — Project History

## Core Context

**Identity:** Creature Designer — own all creature/NPC .lua files and behavior metadata
**Tech:** Pure Lua engine, zero external dependencies. Creatures use `animate = true`, follow standard object rules + creature-specific fields
**Template:** `src/meta/templates/creature.lua`
**Existing creatures (Phase 1-4):** rat, cat, bat, wolf, spider — all complete with loot tables, butchery, stress, pack tactics, territorial behavior, creature actions
**Phase 5 scope:** werewolf NPC (creature type, separate from disease), simplified pack v1.1, Level 2 creatures
**Key mechanics:** 12 mutation edge types (7 creature-specific: loot_table.*, death_state.*, behavior.creates_object)
**Workflow:** Lint before commit via `python scripts/meta-lint/lint.py {file}` (Wiggum owns linter)
**Predecessor:** Flanders owned creatures Phase 1-4 — reference his history for patterns

## Design Documentation Map

| Document | Location | Status |
|----------|----------|--------|
| Creature Ecology | docs/design/creatures/creature-ecology.md | ✅ Design |
| NPC System | docs/design/creatures/npc-system.md | ✅ Design |
| Creature System | docs/architecture/engine/creature-system.md | ✅ Architecture |
| Creature Inventory | docs/architecture/engine/creature-inventory.md | ✅ Architecture |
