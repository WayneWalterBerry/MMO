# Decision: Feel Verb Enumerates Container/Surface Contents

**Author:** Bart (Architect)  
**Date:** 2026  
**Status:** Implemented  
**Impact:** Verb system, gameplay progression  

## Context

The "feel {object}" verb handler printed only the object's `on_feel` text but never enumerated accessible contents of containers or surfaces. This broke the darkness gameplay loop — players couldn't discover the matchbox inside the open nightstand drawer by touch.

## Decision

After printing the sensory description, the feel handler now enumerates:

1. **Surface zones** (`obj.surfaces`) — each zone where `accessible ~= false` and contents exist. Prefix: "Your fingers find {zone_name}:"
2. **Simple containers** (`obj.container` + `obj.contents`) — if container has contents. Prefix: "Inside you feel:"

Both use `ctx.registry:get(id)` to resolve item names, falling back to raw ID.

## Rationale

- Matches the progressive disclosure design: "feel around" = summary (object names), "feel {object}" = detail + accessible contents.
- Tactile language ("Your fingers find", "Inside you feel") stays consistent with darkness atmosphere.
- Respects the `accessible == false` gate — closed drawers hide contents from touch, same as from sight.
- Follows the same enumeration pattern already established in the LOOK handler.

## Files Changed

- `src/engine/verbs/init.lua` — feel handler (~20 lines added after line 841)
