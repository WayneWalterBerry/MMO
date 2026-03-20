# Decision: Engine Conventions from Pass-002 Bugfixes

**Author:** Bart (Architect)  
**Date:** 2026-03-22  
**Status:** Proposed  
**Affects:** Object display functions, feel handler, game loop, CLI flags

## Conventions Established

### 1. `on_look(self, registry)` signature
Object `on_look` functions may now accept an optional second argument: the registry instance. This allows display functions to resolve child object IDs to display names. Existing functions that only accept `(self)` are unaffected — Lua silently drops extra arguments.

**Team impact:** Any new object with container/surface listings in `on_look` should use the registry parameter to show display names, not raw IDs.

### 2. `on_feel` can be string or function
The feel handler now dispatches based on `type(obj.on_feel)`. Functions receive `(self)` and return a string. This enables dynamic tactile descriptions (e.g., matchbox varying by match count).

**Team impact:** Content creators can use either `on_feel = "static text"` or `on_feel = function(self) ... end`. Both work transparently.

### 3. `ctx.game_over` flag for death/ending
Setting `ctx.game_over = true` from any verb handler causes the game loop to break after the current tick cycle. The loop prints a "Play again?" prompt and exits. Extensible for future death causes beyond poison.

**Team impact:** Any lethal interaction should set this flag. The death message should be printed by the verb handler before setting the flag.

### 4. `--debug` CLI flag
Parser diagnostic output is now off by default. Pass `--debug` to `lua src/main.lua` to re-enable `[Parser]` matching diagnostics on stderr/stdout. Keeps player experience clean during normal play.

**Team impact:** QA testing with parser analysis should use `lua src/main.lua --debug`.
