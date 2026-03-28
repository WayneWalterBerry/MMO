# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context (Summarized)

**Role:** Architect — engine design, verb systems, FSM mechanics, mutation patterns, puzzle systems

**Major Systems Built:**
- **Engine Foundation:** Loader (sandboxed execution), Registry (object storage), Mutation (via loadstring), Loop (REPL)
- **Verb System:** 31 verbs across 4 categories (sensory, inventory, object interaction, meta); tool resolution (capabilities-based, supports virtual tools like blood)
- **FSM Architecture:** Inline state machines for all objects; timer tracking (two-phase tick), room pause/resume, cyclic states
- **Containment:** 4-layer validation (identity, size, capacity, categories)
- **Composite Objects:** Single-file pattern with detachable parts; two-hand carry system
- **Skill System:** Binary table lookup; skill gates; crafting recipes on materials
- **GOAP Planner:** Tier 3 backward-chaining; prerequisite resolution; in-place container handling
- **Terminal UI:** Split-screen (status bar + scrollable output + input); pure Lua; ANSI support
- **Multi-Room Engine:** All rooms loaded at startup; shared registry; per-room FSM ticking

**Architectural Patterns (Foundational):**
- Objects use FSM states with sensory text; mutation is code-level only
- `engine/mutation/` is ONLY code that hot-swaps objects
- Tool resolution: capabilities (not tool IDs)
- Sensory verbs work in darkness
- Skills: double-dispatch gating (skill gate + tool gate)
