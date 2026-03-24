# Comic Book Guy — History Archive (FSM Design & Container Model, 2026-03-22)

## FSM Object Lifecycle Design & Container Model Integration (2026-03-22T14:29:02Z)

**Status:** ✅ DESIGN COMPLETE & DOCUMENTED  
**Spawns:** 1 background (claude-haiku-4.5)  
**Outcome:** FSM section 2.3 added to fsm-object-lifecycle.md; container pattern unified

### What I Did

1. **Analyzed object inventory** (39 objects in src/meta/objects/)
   - Identified FSM candidates: match, candle, nightstand, wardrobe, window, vanity, curtains
   - Identified static objects: 32 no transitions needed

2. **Container Pattern Unified Across Furniture**
   - **Nightstand** — top surface (visible/feel-able) + drawer (compartment)
   - **Wardrobe** — hanging rod (container) + shelves (containers)
   - **Vanity** — drawer (compartment) + mirror surface
   - **Window** — interior compartments (blinds storage, frame interior)
   - Pattern: exterior surfaces (feel-able) + interior compartments (state-gated)

3. **Documented State Patterns**
   - **Terminal consumables:** match → lit → spent (can't re-light)
   - **Intermediate consumables:** candle → lit → stub (20 turns) → spent
   - **Reversible containers:** closed ↔ open (no consumption, information gates)
   - **Tick system:** fires before verb execution (prevents ambiguity on resource burn)

4. **Design Rules Established**
   - File-per-state for properties (descriptions); FSM definition for transitions
   - Accessibility gating: closed containers hide contents from FEEL/LOOK
   - Terminal states prevent impossible transitions

### Learning: Darkness Design Language

**Sensory hierarchy applied to containment:**
- FEEL (touch) → discovers containers by texture + handle
- SMELL → identifies container contents (dangerous/safe)
- LOOK → requires light (reward for solving darkness puzzle)
- TASTE → learn-by-dying sense (poison detection)

**Container as emotion pedagogy:**
- Drawers = secrets (hidden until opened)
- Locked containers = challenge (skill or tool required)
- Open containers = relief (visibility restored)

### Key Integration with Batch 2 Fixes

**Pronoun Resolution ↔ Container Design:**
- When player opens drawer and says "take it", pronoun resolver finds drawer (last-found object)
- Container accessibility gating (accessible flag) determines if contents are discoverable
- FEEL verb now enumerates accessible contents naturally

**Compound Commands ↔ Container Puzzles:**
- "open drawer and take match" splits into two; both succeed naturally
- Enables sequential container discovery: open → feel → take

**Em Dash Cleanup:**
- All sensory descriptions verified for ASCII-safe text
- No Unicode punctuation in player-visible container labels

### Decision Context

- User Directive (D-7): Nightstand as container model — approved for implementation
- Rationale: Surface-zone model fights player mental model; containers align with expectations
- Pattern Applied: Wardrobe, vanity, window all follow unified container design

### Files Changed
- `docs/design/fsm-object-lifecycle.md` — section 2.3 added (container pattern + implementation roadmap)

### Design Verification Checklist

- ✓ Nightstand discoverable by FEEL (handle texture)
- ✓ Drawer contents revealed only when opened (accessible gating)
- ✓ Pronoun resolution enables "open drawer and take it"
- ✓ Compound commands split naturally; both sub-commands resolve

---

## Cross-Agent Integration Points

**Bart → CBG:** Compound commands + pronoun resolution make container discovery feel natural

**CBG → Bart:** Container accessibility pattern (accessible flag) guides implementation

**Frink → CBG:** CYOA branching patterns suggest future state-aware sensory descriptions

---

## Next Steps for CBG

- Extend sensory descriptions for new container types (locked, sealed, concealed)
- Design state-aware flavor text (nightstand feels different if already explored)
- Coordinate with Bart on container mutation (open/close state transitions)
