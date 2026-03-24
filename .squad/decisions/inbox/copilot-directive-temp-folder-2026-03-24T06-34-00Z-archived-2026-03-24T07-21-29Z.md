### 2026-03-24T06-34-00Z: User directive — Use temp/ for scratch files
**By:** Wayne (via Copilot)
**What:** ALL temporary files (test output, debug logs, trace files, scratch scripts, verification logs) MUST go in the `temp/` folder — NEVER in the project root. The root should only contain README.md, .gitignore, and permanent project files. Agents that generate temp/debug/test output files must write them to `temp/`, not the root.
**Why:** Project root was cluttered with 12 scratch files (test-*.txt, debug-*.txt, trace.txt, input.txt, test-duplicate-take.lua). These belong in temp/.
