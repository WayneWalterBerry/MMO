### 2026-03-19T125500Z: User directive — Compound Tool Interactions
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Some skills require TWO tools used together. This is a "compound tool" pattern:
- Lighting a match = a skill everyone knows, but requires match + matchbox (striker) together
- Sewing = a learned skill that requires needle + thread together
- The engine needs to support: SKILL + TOOL A + TOOL B → action

This reframes the tool system:
- Single-tool actions: LIGHT candle WITH match-lit (one tool)
- Compound-tool actions: STRIKE match ON matchbox (two tools, innate skill)
- Compound-tool + learned skill: SEW cloth WITH needle AND thread (two tools + learned skill)

The complexity isn't in HAVING a skill — lighting a match is innate. The complexity is in HAVING BOTH required objects. This is the puzzle: find the match AND the matchbox. Find the needle AND the thread.

**Implications:**
- Tool convention needs a `requires_tools` (plural) field — array of required capabilities
- Skills can be innate (everyone knows) or learned (lockpicking, sewing)
- Thread is a new object needed for sewing (needle alone isn't enough)
- The STRIKE verb is a compound-tool verb

**Why:** User request — major game mechanic. Compound tools add realistic puzzle depth. Every crafting/interaction becomes: do you have ALL the pieces?
