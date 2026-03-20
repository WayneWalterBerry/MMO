### 2026-03-20T20:03Z: User directive — Intelligent natural language input (beyond verb+noun)
**By:** Wayne Berry (via Copilot)
**What:**
Players expect more intelligent input than classic verb+noun MUD syntax. Because of modern LLM/AI interactions, users now expect natural language comprehension. The parser must handle:

1. **Multi-step compound commands:** "Get match from the matchbox and light the candle" should execute: open matchbox → take match → strike match → light candle (inferring intermediate steps)
2. **Contextual commands:** "Light the candle with a match" — if the player already has a match in hand, just light it. If they don't, infer they need to get one first.
3. **Implicit containers:** "Get match from the matchbox" — understands "from the matchbox" as a source container without requiring "open matchbox" first
4. **Goal-oriented input:** The player states their GOAL, not the individual steps. The engine figures out the steps.
5. **Context awareness:** If the player examined the matchbox and knows it has matches, "light the candle" should be enough context for the engine to figure out the chain.

**Old style (MUD-era):** get matchbox → open matchbox → get match → strike match → light candle (5 commands)
**New style (LLM-era):** "Get a match from the matchbox and light the candle" (1 command)
**Context style:** "Light the candle with a match" (1 command, engine infers the chain)

**Why:** User request — modern players trained on LLM interfaces expect natural language intelligence. The parser should feel conversational, not mechanical. This is a key differentiator from classic IF/MUD. This is NOT about adding an LLM to the parser — it's about building smarter NLP preprocessing that can decompose complex commands into action chains with context awareness.
