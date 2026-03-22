# Decision: Parser Modifier Stripping and Conditional Handling

**Author:** Smithers (UI Engineer)
**Date:** 2026-03-23
**Status:** Implemented
**Affects:** preprocess.lua, loop/init.lua, verbs/init.lua, goal_planner.lua

## D-MODSTRIP: Noun Modifier Stripping is a Separate Pipeline Stage

Quantifier modifiers ("whole", "entire", "every", "all of the") are stripped in their own pipeline stage (`strip_noun_modifiers`), NOT folded into `strip_filler`. Rationale: filler stripping operates on sentence-level prefixes/suffixes, but modifiers appear _inside_ noun phrases ("the **whole** room"). Separate stage keeps concerns clean and is independently testable.

## D-ALREADY-LIT: FSM State Detection for Already-Lit Objects

The `light` handler checks `obj.states[obj._state].casts_light` to detect already-lit objects. This is property-based (works for any FSM object with casts_light) rather than string-matching state names. Follows the Prime Directive: describes the world state ("A tallow candle burns with a steady flame...") instead of telling the player what they can't do.

## D-CONDITIONAL: Conditional Clauses Detected in Loop, Not Parser

Conditional clause detection ("if you find X", "when you see X") lives in `loop/init.lua` during sub-command execution, not in `preprocess.split_commands`. Rationale: the parser's job is to split text faithfully; the loop's job is to decide what to execute. Moving it to the loop keeps the parser pure and gives the loop control over how many sub-commands to skip.

## D-GOAP-NARRATE: GOAP Steps Narrate via Verb-Keyed Table

GOAP `execute()` uses a `STEP_NARRATION` table mapping verbs to narration functions. This is extensible (add new verbs by adding table entries) and keeps narration separate from handler logic. Each GOAP step gets a brief prefix message before the handler runs.
