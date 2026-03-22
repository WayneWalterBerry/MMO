# Phase 3 Decisions — Smithers

**Author:** Smithers (UI Engineer)  
**Date:** 2026-03-23  
**Status:** Implemented

---

## D-HIT001: Hit verb is self-only in V1

Hit/punch/bash/bonk/thump only work as self-infliction in V1. "hit <object>" is not supported. Combat hitting is future work (Phase 2+). This mirrors the stab verb pattern.

## D-HIT002: Strike disambiguates body areas vs fire-making

`strike` is overloaded: if the noun resolves to a body area (`strike arm`, `strike head`), it routes to the hit handler. Otherwise it falls through to the existing fire-making handler (`strike match on matchbox`). The `parse_self_infliction` function handles disambiguation.

## D-HIT003: Smash NOT aliased to hit

`smash` remains aliased to `break` because it's used for the vanity mirror smash transition. Creating a hit alias would break existing furniture destruction gameplay.

## D-CONSC-GATE: Consciousness gate before input reading

The consciousness check runs at the top of the game loop, BEFORE the input-reading section. When unconscious, the loop ticks injuries and decrements the timer without consuming player input. Uses `goto continue` to re-enter the loop.

## D-APP-STATELESS: Appearance subsystem is stateless

`appearance.describe(player, registry)` is a pure function that reads player state and composes a string. It never modifies state. Takes any player state table — future-proofed for multiplayer `look at <player>`.

## D-SLEEP-INJURY: Sleep now ticks injuries (bug fix)

Sleep was missing `injury_mod.tick()` calls during its tick loop. Now each sleep tick calls the injury system, and death during sleep triggers "You never wake up" narration with `ctx.game_over = true`.
