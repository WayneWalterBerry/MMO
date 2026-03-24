### 2026-03-24T06-41-25Z: User directive — Meta Compiler is P0
**By:** Wayne (via Copilot)
**What:** The custom meta compiler is P0 for tomorrow — must ship before the project grows. It is basically a tool Lisa can use to test the syntax and structure of .lua code. This is not a nice-to-have; it gates further object/room creation at scale.
**Why:** Without compile-time validation, every new object/room is a potential runtime bug. Lisa needs this tool to validate Flanders' and Moe's work before it hits the engine.
