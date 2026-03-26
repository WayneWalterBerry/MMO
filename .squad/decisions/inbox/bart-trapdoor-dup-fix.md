# Decision: Fix #276 trapdoor duplication

**Author:** Bart (Architect)  
**Date:** 2026-03-26

## Decision
Route rug coverage to the existing portal trapdoor and remove the duplicate trap-door instance from the bedroom. Also allow covering reveals to transition any hidden-state object (not just hidden→revealed) so portal trapdoors reveal correctly.

## Rationale
The bedroom rug was spawning a separate trap-door object, while the down exit used the portal trapdoor. Moving the rug must reveal the portal object already tied to the exit, avoiding duplicate trapdoors and blocked traversal.

## Impact
- **Moe (World):** Bedroom rug no longer nests a trap-door instance.
- **Flanders (Objects):** Rug now covers the portal trapdoor; portal keywords include “iron ring.”
- **Bart (Engine):** Covering reveal logic now transitions any hidden-state object.
