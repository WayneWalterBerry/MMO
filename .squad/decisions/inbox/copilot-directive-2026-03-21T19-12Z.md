### 2026-03-21T19:12Z: User directive
**By:** Wayne Berry (via Copilot)
**What:** Engine Event Handlers (Engine Hooks) are a core architecture principle of the game engine. They are not just a feature — they are a foundational design pattern alongside FSM, the parser, and the JIT loader. All future game mechanics that fire on game events should be built as registered hooks. This should be reflected in the top-level architecture docs.
**Why:** User request — elevates hooks from "a thing we built for puzzle 015" to a first-class engine concept that shapes how the entire game is extended.
