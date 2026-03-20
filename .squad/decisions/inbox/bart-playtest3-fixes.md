# Decision: FSM Transition Alias Pattern

**Author:** Bart (Architect)  
**Date:** 2026-03-23  
**Status:** Implemented  
**Context:** Play Test Bug Fixes — Batch 3

## Decision

FSM transition definitions can carry an `aliases` array field (e.g., `aliases = {"light", "ignite"}`). The FSM engine itself does NOT interpret this field — verb handlers are responsible for checking it when deciding whether to delegate to another verb's handler.

## Rationale

The match FSM defines a `strike` transition. Players naturally say "light match" not "strike match". Rather than:
- (a) Duplicating FSM transitions for each synonym verb, or
- (b) Adding synonym resolution to the FSM engine itself

We chose (c): verb handlers check for FSM transitions matching their verb or its known aliases, then delegate to the canonical verb handler. This keeps the FSM engine simple and puts synonym knowledge in the verb layer where it belongs.

## Implications

- New FSM objects that need verb synonym support should add `aliases` arrays to their transitions
- The verb handler (not the FSM engine) is the authority on verb synonyms
- This pattern scales: any verb handler can check any FSM transition's aliases before falling back to "can't do that"
