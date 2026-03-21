# Flanders — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — dedicated specialist for real-world game objects

### Architecture Foundation
- 8 Core Principles govern all object design (`docs/architecture/objects/core-principles.md`)
- Principle 8: "The Engine Executes Metadata; Objects Declare Behavior" — the engine is generic, objects own ALL behavior
- Generic `mutate` field on FSM transitions: weight, keywords, categories, any property can change
- GOAP backward-chaining parser: objects declare prerequisites, engine resolves chains
- Dwarf Fortress property-bag architecture is the reference model
- All mutation is in-memory only; .lua files on disk never change at runtime

### Existing Objects (in src/meta/objects/)
- candle.lua — multi-state FSM (unlit → lit → half-burned → spent), timed burn, extinguishable
- match.lua — strike once, timed burn, no relight after spent
- matchbox.lua — container for matches, open/close FSM
- candle-holder.lua — composite object (holds candle), safe carrying
- wall-clock.lua — 24-state cyclic FSM, misset puzzle support
- window.lua — open/close FSM, single-file (merged from window-open.lua)
- wardrobe.lua — open/close FSM
- iron-door.lua — locked/unlocked, key-based progression
- iron-key.lua — unlock tool
- nightstand.lua, bed.lua, vanity.lua, rug.lua, curtains.lua, chamber-pot.lua — bedroom furniture
- sewing-manual.lua — READ verb, skill granting, burnable
- poison-bottle.lua — composite (bottle + cork)

### CBG Object Mutate Audit (Tier 1 priorities)
- Candle: weight decreases as it burns, keywords shift to "stub"
- Match: keywords change to "blackened" when spent
- Poison bottle: loses "dangerous" category when emptied
- Window/wardrobe: keyword ±"open", feel changes per state

## Learnings
