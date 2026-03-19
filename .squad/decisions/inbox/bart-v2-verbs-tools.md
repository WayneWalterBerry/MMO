# Decision: V2 Verb Handlers — Tool Pipeline & Dynamic Mutation

**Author:** Bart (Architect)  
**Date:** 2026-03-20  
**Status:** IMPLEMENTED

## Context

V1 REPL had 12 verbs but no tool-capability resolution. Comic Book Guy created tool objects (pen, knife, pin, needle, matchbox, paper) with `provides_tool`/`requires_tool` convention. Engine needed verb handlers that resolve tools by capability, consume charges, and — critically — perform the first dynamic mutation (WRITE on paper).

## Decisions

### D-37: Tool Resolution is a Verb-Layer Concern
Tool-finding helpers (`find_tool_in_inventory`, `provides_capability`, `consume_tool_charge`) live in `engine/verbs/init.lua` as local functions, not in a separate engine module. Rationale: tool resolution is tightly coupled to verb dispatch logic. If tool resolution becomes needed outside verbs (e.g., NPC actions), extract then.

### D-38: Dynamic Mutation via string.format + %q
The WRITE verb generates Lua source at runtime using `string.format()` with `%q` for player-provided text. This sanitizes arbitrary player input through Lua's own string escaper. The generated source includes a runtime `on_look` function (reads `self.written_text` at call time) and preserves the `write` mutation entry for appending more text. Generated source is stored back in `object_sources` for future mutation chains.

### D-39: Blood as Virtual Tool
When `player.state.bloody == true`, the tool resolver returns a synthetic tool object (not registered, not in inventory) that provides `writing_instrument`. This keeps the world model clean — blood isn't an inventory item, it's a player state that enables a capability.

### D-40: CUT vs PRICK Capability Split
CUT SELF requires `cutting_edge` (knife only). PRICK SELF requires `injury_source` (pin or knife). Both produce the same `bloody` state. This gives the player two paths to the same result with different tools and different narrative weight.

### D-41: Future Verb Stubs (SEW, PICK LOCK)
Stubbed with "you don't know how to" messages that hint at a learnable skill system. When the skill system ships, these stubs become the integration points.

## Impact
- Enables the full chain: find knife → cut self → write in blood on paper → read paper
- Enables: find matchbox → light candle (with charge tracking)
- Sets pattern for all future tool-gated verbs
