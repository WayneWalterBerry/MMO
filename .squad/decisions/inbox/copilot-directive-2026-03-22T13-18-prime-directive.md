### 2026-03-22T13:18: Prime Directive — Natural Language Feel Without AI Tokens
**By:** Wayne (Effe) Berry (via Copilot)
**What:** PRIME DIRECTIVE FOR GAME DESIGN: The game input should feel like interacting with an AI agent (like Copilot) — natural, forgiving, conversational — NOT a rigid noun-verb engine like classic Zork. However, we do NOT want to spend tokens (i.e., make API calls to an AI model at runtime). We want that AI-like feel using only local parsing, pattern matching, and smart engineering. Zero runtime AI cost.

This means:
- Parser must accept natural English phrasing ("find something to light the candle", "search the nightstand for matches")
- Flexible synonym handling, fuzzy matching, article stripping, preposition tolerance
- Helpful error messages that guide the player ("Try 'search for matchbox' or 'find light'")
- GOAP-style goal resolution done locally, not via LLM
- The illusion of intelligence through robust engineering, not actual inference

**Why:** Core product vision — the game should feel modern and intelligent, but run entirely on the client with zero API costs per player interaction.
