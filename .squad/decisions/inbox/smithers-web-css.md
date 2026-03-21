# Decision: Web Output Rendering Uses innerHTML with HTML Escaping

**Date:** 2026-07-24  
**Author:** Smithers (Senior Engineer)  
**Status:** Implemented  

## Context

The web bootstrapper's `appendOutput()` function used `textContent` to render game output, which is safe but cannot render any markup. The engine now emits `**...**` markdown-style bold markers for room titles, and the UX doc recommends distinct styling for echoed player commands (cyan text, gray prompt character).

## Decision

Switched `appendOutput()` from `textContent` to `innerHTML`, with an `escapeHtml()` pass applied first to prevent injection. Bold markers are converted via regex after escaping. Input echo lines are built with direct DOM construction (separate `<span>` for the prompt character) to allow independent styling.

## Rationale

- `textContent` cannot render `<strong>` tags — `innerHTML` is required.
- HTML escaping before markdown conversion ensures safety. The only text source is Lua `print()` output from the game engine, not user-controlled HTML.
- Separating the prompt `>` into its own span follows the UX doc's Option B+C recommendation and allows gray prompt + cyan command text independently.
- The CSS variable `--echo` was changed from `#7a7a8a` to `#00e0e0` (bright cyan) per `docs/architecture/ui/web-presentation.md`.

## Risk

Low. The escapeHtml function neutralizes `<`, `>`, `&`, `"` before any regex replacement. The bold regex uses non-greedy matching (`+?`) to correctly handle multiple bold spans per line.

## Files Changed

- `web/bootstrapper.js` — `appendOutput()` refactored, `escapeHtml()` added, input echo DOM construction
- `web/index.html` — CSS: `--echo` color, `.input-prompt`, `.output-line strong`
