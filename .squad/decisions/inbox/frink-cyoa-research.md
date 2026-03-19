# Decision: CYOA Branching Patterns for Engine Design

**Filed by:** Frink (Researcher)
**Date:** 2026-07-24
**Status:** PROPOSED
**Context:** Choose Your Own Adventure book series research

## Decision

The text adventure engine should use **bottleneck/diamond branching** as its primary narrative structure, with **time-cave branching** reserved for critical story moments only. Hidden/unreachable content should be implemented as a first-class feature.

## Rationale

Analysis of 13 CYOA books (1979–1984) reveals that pure time-cave branching (every choice unique) creates exponential content requirements — unsustainable for any non-trivial game. The best CYOA books use convergent paths (bottleneck/diamond) to manage scope while preserving player agency.

Our Lua engine has an advantage CYOA books never had: **state tracking**. We can make reconvergent paths feel personalized by having the world remember prior choices — flavor text, NPC reactions, available objects all change based on history.

## Key Design Principles from CYOA Research

1. **Bottleneck convergence** — key rooms/events all paths must pass through
2. **Hidden nodes** — secret content discoverable through unconventional interaction (UFO 54-40 pattern)
3. **Quick failure cycles** — cheap death/restart encourages experimentation
4. **Depth as commitment** — going deeper = harder to return (Underground Kingdom pattern)
5. **Risk/reward proportionality** — boldest choices lead to best AND worst outcomes

## Files

`resources/research/choose-your-own-adventure/` — 14 research files covering series overview and 13 individual books.
