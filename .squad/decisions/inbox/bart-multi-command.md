# D-MULTICOMMAND: Multi-command input splitting (Issue #1)

**Author:** Bart (Architect)
**Date:** 2026-07-24
**Status:** Implemented
**Affects:** engine/parser/preprocess.lua, engine/loop/init.lua

## Decision

Players can type multiple commands separated by commas (`,`), semicolons (`;`), or the word `then`. The parser splits these into individual commands before any other preprocessing. Each command executes sequentially; failures don't abort the sequence.

## Rationale

Text adventure convention — players expect `move bed, open trapdoor` to work. Three separator styles cover common patterns:
- **Commas** — natural language ("do this, then that")
- **Semicolons** — classic IF convention (Inform, Zork)
- **"then"** — plain English ("move bed then open trapdoor")

## Implementation

1. `preprocess.split_commands(input)` — new function, character-by-character scan respecting double-quoted text
2. Game loop calls `split_commands` BEFORE the existing `" and "` compound split (layered: outer separators, then inner " and ")
3. Fast path: inputs with no separators skip the scan entirely
4. Edge cases handled: empty segments, trailing separators, nil/empty input

## Tests

13 new unit tests in `test/parser/test-preprocess.lua` covering all separator types, edge cases, quoted text protection, and word-boundary safety ("thenardier" doesn't split).
