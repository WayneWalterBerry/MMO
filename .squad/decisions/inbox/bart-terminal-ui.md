# Decision: Split-Screen Terminal UI Architecture

**Author:** Bart (Architect)  
**Date:** 2026-07-18  
**Status:** IMPLEMENTED  

## Context

Wayne requested a classic IF split-screen terminal interface (Frotz-style) to replace the simple print/read REPL. Requirements: pure Lua + ANSI escape codes, no C libraries, Windows compatible, graceful fallback.

## Decisions

### D-UI-1: Manual redraw from scrollback buffer (not ANSI auto-scroll)

ANSI scroll regions are used only to prevent the input line from scrolling the status bar. All output rendering is done by redrawing the visible portion of a 500-line scrollback buffer. This avoids terminal-specific scroll region quirks and gives us full control over scrollback navigation.

### D-UI-2: Print interception via display.ui hook

The UI hooks into `display.ui` rather than patching `print()` a second time. The existing `display.install()` wrapper checks `display.ui.is_enabled()` and routes through `ui.output()` when active. This means all 390+ print() calls in verb handlers route through the UI with zero code changes.

### D-UI-3: Scroll commands instead of key capture

Pure Lua `io.read()` cannot capture Page Up/Down without C extensions. Scrollback uses `/up`, `/down`, `/bottom` commands intercepted in the game loop before verb dispatch. Any normal game command auto-scrolls to bottom. Pragmatic tradeoff: works everywhere, no dependencies.

### D-UI-4: --no-ui flag for graceful fallback

`--no-ui` command-line flag bypasses UI initialization entirely. Falls back to original print/read behavior. Essential for piped input, automated testing, and terminals without ANSI support.

### D-UI-5: pcall-wrapped game loop for terminal cleanup

`loop.run()` is wrapped in `pcall` in main.lua so `ui.cleanup()` always executes — even on Lua errors. Terminal state (scroll region, cursor visibility, attributes) is always restored.

## Files

- **Created:** `src/engine/ui/init.lua` — terminal UI module (status bar, output window, input line, scrollback)
- **Modified:** `src/engine/display.lua` — added `display.ui` hook for print routing
- **Modified:** `src/engine/loop/init.lua` — UI-aware input, scroll command handling, status bar updates
- **Modified:** `src/main.lua` — UI init, status bar callback, cleanup, --no-ui flag
- **Modified:** `src/engine/verbs/init.lua` — WRITE verb uses `context.ui.prompt()` when available

## Impact

- All existing game logic unchanged. Only the I/O layer changed.
- Browser entry point (`main_browser.lua`) unaffected — UI module is CLI-only.
- Parser pipeline, FSM, mutation, containment — all untouched.
