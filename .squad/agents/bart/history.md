# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context

**Agent Role:** Architect responsible for engine design, verb systems, mutation mechanics, and tool resolution patterns.

**Work Summary (2026-03-18 to 2026-03-19):**
- Designed and built src/ tree structure (engine/, meta/, parser/, multiverse/, persistence/)
- Implemented four foundational engine modules: loader (sandboxed code execution), registry (object storage), mutation (object rewriting), loop (REPL)
- Established containment constraint architecture (4-layer validator: identity, size, capacity, categories)
- Designed template system + weight/categories + multi-surface containment for complex objects
- Implemented V2 verb system: sensory verbs (FEEL, SMELL, TASTE, LISTEN) all work in darkness
- Designed tool resolution pattern: verb-layer concern, supports virtual tools (blood), capability-based resolution
- Moved game start time from 6 AM → 2 AM for true darkness mechanic

**Architecture Decisions Established:**
- D-14: True code mutation (objects rewritten, not flagged)
- D-16: Lua for both engine and meta-code (loadstring enables self-modification)
- D-17: Universe templates (build-time LLM + procedural variation)
- D-37 to D-41: Sensory verb convention, tool resolution, blood as virtual tool, CUT vs PRICK capability split

**Latest Spawns (2026-03-19):**
1. Sensory verbs + start time fix (6 AM → 2 AM, FEEL/SMELL/TASTE/LISTEN implemented)
2. V2 tool pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK verbs, tool resolution helpers, dynamic mutation via string.format)

**Key Patterns Established:**
- `engine/mutation/` is ONLY code that hot-swaps objects via loadstring()
- Mutation rules separate from object definitions (composable, clean)
- Registry uses instance pattern (not singleton) — enables simultaneous multiverse registries
- Tool resolution uses capabilities (not tool IDs) — supports complex interactions
- Blood is a virtual tool: generated on-demand when `player.state.bloody == true`, not an inventory item

## Recent Updates

### Session Update: V2 Verb System & Tool Pipeline (2026-03-19T13-22)
**Status:** ✅ COMPLETE  
**Parallel Spawns:** 2 successful background spawns

**Spawn 1: Sensory Verbs + Start Time Fix**
- Moved game start from 6 AM → 2 AM (true darkness)
- Implemented FEEL, SMELL, TASTE, LISTEN verbs for sensory navigation
- All sensory verbs work in complete darkness
- Poison mechanic: TASTE → death (immediate consequence)
- Decision D-37: Sensory verb convention established

**Spawn 2: V2 Tool Pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK)**
- Decision D-38: Tool resolution as verb-layer concern
- Decision D-39: Blood as virtual tool
- Decision D-40: CUT vs PRICK capability split
- Decision D-41: Future verb stubs (SEW, PICK LOCK)
- Implemented: Dynamic mutation via string.format + %q (sanitizes player input)
- Tool resolver now supports:
  - find_tool_in_inventory()
  - provides_capability()
  - consume_tool_charge()

**Architecture Insight:** Tool resolution is tightly coupled to verb dispatch — stays in engine/verbs/init.lua, not separate module.

**Next:** Cross-agent impact on Comic Book Guy (sensory descriptions on 37 objects) and design verification.
