# Writing & Paper System

**Last updated:** 2026-03-21  
**Audience:** Game Designers  
**Purpose:** Reference for paper objects, writing mechanics, and player-generated content through code mutation.

*This section was extracted from `design-directives.md` for better organization.*

---

## Paper Object

**Core Mechanic:** Sheet of paper is a writable object. Writing on paper requires a writing tool: pen, pencil, or blood. The paper mutates when written on to include the written words.

| Directive | Details | Source |
|-----------|---------|--------|
| **Paper Object** | `sheet-paper.lua` or similar | Wayne (2026-03-19T014604Z) |
| **Writing Tools** | Pen, pencil, or blood | Wayne (2026-03-19T014604Z) |
| **Interaction Pattern** | WRITE ON {paper} WITH {pen\|pencil\|blood} | Wayne (2026-03-19T014604Z) |
| **Mutation Behavior** | When words are written, the paper object's code MUTATES to include those words. The paper literally becomes a different object (paper-with-writing) via the mutation engine. | Wayne (2026-03-19T014629Z) |
| **Reading** | LOOK AT paper shows what was written | Wayne (2026-03-19T014629Z) |

**Implementation Note:** The paper is a beautiful application of the true code rewrite mutation model (D-14) to player-generated content. The paper's code IS its state, including whatever the player wrote.

---

## Injury & Blood

### Blood as Writing Instrument

**Core Mechanic:** Players can injure themselves to draw blood, which can be used as a writing instrument on paper.

| Tool | Method | Verb | Result |
|------|--------|------|--------|
| **Knife** | Cut self | CUT SELF WITH knife | Draw blood; provides writing capability |
| **Pin** | Prick self | PRICK SELF WITH pin | Draw blood; provides writing capability |

**Constraint:** Blood is a dark, consequential resource. Players must actively choose to injure themselves to get this writing material. This creates moral/physical stakes around writing.

**Design Note:** Pin and knife are in the `injury_source` tool category. They are also in other categories (pin is a lock-picking tool with the right skill; knife is a cutting/weapon tool).

---

## See Also

- **Design Directives:** `design-directives.md`
- **Tools System:** `tools-system.md`
- **Mutation Model:** `design-directives.md#Mutation-Model`
- **Sensory System:** `design-directives.md#Sensory-System`
- **Player Skills System:** `player-skills-system.md`
