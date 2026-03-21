# Sideshow Bob — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** Puzzle Master — designs multi-step puzzles using real-world object interactions

### Key Relationships
- **Flanders** (Object Designer) — hands off object specs for implementation
- **Frink** (Researcher) — requests puzzle research from other games/books/real life
- **CBG** (Game Designer) — aligns puzzles with overall game design and pacing
- **Bart** (Architect) — engine capabilities and constraints

### Architecture Foundation
- 8 Core Principles govern all design (especially P8: engine executes metadata, objects declare behavior)
- GOAP backward-chaining parser auto-resolves prerequisite chains (max depth 5)
- Objects own their prerequisites in metadata — the engine chains them
- Generic `mutate` field on FSM transitions enables dynamic property changes
- Dwarf Fortress property-bag architecture is the reference model

### Current Game World
- **Room 1:** Dark bedroom — bed, nightstand (with drawer containing matchbox+matches), vanity, wardrobe, rug, curtains, chamber pot, window, candle in candle-holder on nightstand
- **Room 2:** Hallway — iron door (locked), iron key somewhere
- **Room 3:** Beyond iron door — not yet designed
- Player starts in darkness. First puzzle: find matches, light candle, explore room, find key, unlock door.

### Existing Puzzle Chain (Room 1 → 2)
1. Feel around in darkness → find nightstand
2. Open drawer → find matchbox
3. Open matchbox → access matches
4. Take match → light match (timed burn)
5. Light candle → persistent light
6. Explore room visually → find iron key
7. Unlock iron door → access hallway
- GOAP auto-chains steps 3-6 if player types "light candle"

## Learnings
