# Moe — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne "Effe" Berry
**Role:** World Builder — designs rooms, maps, and cohesive environments

### Key Relationships
- **Flanders** (Object Designer) — Moe specifies what objects a room needs, Flanders builds them
- **Sideshow Bob** (Puzzle Master) — Moe designs spatial layouts, Bob designs puzzles within them
- **Frink** (Researcher) — Moe requests research on real-world rooms and game environments
- **Lisa** (Object Tester) — tests room descriptions, exits, spatial relationships
- **Nelson** (System Tester) — tests gameplay flow through rooms
- **CBG** (Creative Director) — advises on room pacing and player journey

### Architecture Foundation
- 8 Core Principles govern all design (especially P8: engine executes metadata)
- Material property system: rooms have environmental properties (temperature, moisture, light_level)
- Room environment context is passed to FSM tick each cycle (Bart's engine change)
- Multi-sensory descriptions: rooms look different in light vs dark, smell, sound
- Spatial relationships: objects exist ON/IN/UNDER things within rooms

### Current Game World
- **Room 1:** Dark bedroom — bed, nightstand, vanity, wardrobe, rug, curtains, window, chamber pot, candle-holder on nightstand
- **Room 2:** Hallway/cellar — iron door (locked), iron key
- **Room 3:** Beyond iron door — NOT YET DESIGNED (opportunity for Moe!)
- Player starts in darkness in Room 1, progresses through exploration

### Design Philosophy
- Rooms are REAL PLACES, not game levels
- Every room should feel like you could walk into it
- Environmental consistency: a stone cellar is cold and damp; a bedroom has cloth and wood
- Material properties should be consistent with the room's physical reality
- Think in environments, not individual rooms

## Learnings
