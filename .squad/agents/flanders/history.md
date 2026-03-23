# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, lua src/main.lua)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as .lua files in src/meta/objects/.

### Team Relationships
- **Bart** = Engine Architect — builds FSM engine, verbs, parser, containment system. My objects DECLARE behavior; Bart's engine EXECUTES it.
- **CBG (Comic Book Guy)** = Game Designer — audits objects for design quality, proposes mutate opportunities, writes design docs. He reviews my work.
- **Nelson** = Test Engineer — tests objects in the engine, catches regressions.
- **Frink** = Researcher — provides CS foundations (ECS, Harel statecharts, DF architecture analysis).
- **Brockman** = Documentation — writes architecture docs.
- **Wayne** = Owner — sets directives, approves designs. References Dwarf Fortress as the gold standard.

### Key Directives
- Dwarf Fortress property-bag architecture is the reference model (D-DF-ARCHITECTURE)
- All mutation is in-memory only; .lua files on disk never change at runtime
- No LLM at runtime (D-19) — everything deterministic and offline
- Each command tick = 360 game seconds (10 ticks per game hour)
- Game starts at hour 2 (2 AM), darkness is default starting condition

---

## Archived Sessions Summary (Cumulative Achievements)

This section summarizes 50+ prior sessions covering object design, FSM architecture, injury systems, and Level 1 object specification. For detailed session logs, see .squad/log/.

**Key Accomplishments:**
- Designed & built 37+ Level 1 objects across 5 rooms
- Implemented 5 injury templates (minor-cut, bleeding, bruised, burn, poisoned-nightshade)
- Built bandage FSM treatment object with injury targeting architecture
- Standardized 78 objects with proper GUID format
- Created comprehensive object & injury documentation (45+ design docs)
- Established patterns: composite objects, nested containers, FSM injury progression
- Built poison-bottle upgrade with structured effects & readable parts

**Object Architecture Mastered:**
- Code-derived mutable objects (Principle 1) — objects are live Lua tables from immutable source
- FSM behavior (Principle 3) — all state transitions declared in transitions table
- Composite objects (Principle 4) — single file defines parent + nested inner objects
- Sensory space (Principle 6) — state determines perception (dark ≠ lit, blind ≠ seeing)
- Engine executes metadata (Principle 8) — objects are pure data, engine is generic interpreter

**Injury System Architecture:**
- 7 injury types with self-healing, worsening, and treatment mechanics
- Dual-binding injury targeting (injury ↔ treatment item linkage)
- Healing interactions per injury type (bandage, poultice, antidote, etc.)
- Severity-based state progression (active → worsened → critical → fatal/healed)
- Restriction system (injuries restrict capabilities: climb, run, fight)

**Materials & Templates:**
- 4 new materials needed in registry: stone, silver, hemp, bone
- Template system: container, small-item, furniture, sheet (all documented)
- Creature objects as pure FSM (rat pattern: hidden→visible→fleeing→gone)

---

## Learnings

### 2026-03-23: Wave2 — Decision Documentation & Cross-Agent Propagation

**Wave2 Spawn:** Scribe merged all decision documents into decisions.md

**Decisions Documented:**
- **D-INJURY001:** Structured effect tables over legacy strings (impacts Bart's effect processing pipeline)
- **D-INJURY002:** Crushing wound as new injury type (distinct from bleeding/bruised — hybrid immediate+ongoing damage)
- **D-INJURY003:** Label as non-detachable readable part (enables proper ead label verb support via composite object system)
- **D-INJURY004:** Bear trap disarm uses guard function (runtime context checks for skill validation, not just tool requirements)
- **D-INJURY005:** Bear trap self-transitions for safe take (enables custom messages and property mutations in safe states)

**Cross-Agent Context:**
- Marge verified all object implementations and injured-system patterns
- Smithers' parser handles complex multi-step interactions (disarm requires lockpicking + thin tool)
- Bart will integrate structured effects into effect processing pipeline
- All 5 injury-system decisions are now canonical and merge-ready

**Impact Summary:**
- 3 new objects + 1 new injury type now documented
- Effect pipeline ready for Bart's integration phase
- Injury targeting architecture documented in decisions
- Ready for cross-team execution phase
