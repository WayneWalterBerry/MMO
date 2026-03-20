# Son of Hunky Punk — Android IF Interpreter

## Overview

| Field | Details |
|-------|---------|
| **Game** | Son of Hunky Punk (fork of Hunky Punk) |
| **Developer** | Community/open source (andglkmod) |
| **Platforms** | Android only (Google Play + F-Droid) |
| **Price** | Free, open source |
| **Category** | IF interpreter — plays Z-machine and TADS games |

## What It Is

Son of Hunky Punk is the Android counterpart to Frotz — an interpreter for playing classic interactive fiction. It supports Z-code (Frotz engine) and TADS formats, with IFDB metadata integration, cover art display, and a clean mobile UI. It's one of the best-known Android IF players alongside Fabularium.

## Ratings & Reviews

| Platform | Rating | Reviews |
|----------|--------|---------|
| Google Play | ⭐ 4.0/5 | ~200+ ratings |
| F-Droid | N/A (no ratings system) | Positive community feedback |

## What Players LOVE

- **Tap-to-input** — tap words in the text to use them as input; reduces typing
- **Shortcut buttons** — common commands (look, inventory, etc.) available as buttons
- **Night mode** — dark theme for comfortable reading
- **IFDB metadata** — automatically fetches cover art and game details
- **Clean interface** — simple, functional, gets out of the way
- **Open source** — no tracking, no ads, community-maintained
- **Font customization** — adjustable text size and fonts

## What Players HATE

- **Compatibility issues** — some story files don't work correctly
- **UI quirks** — scrolling and tap controls can be finicky
- **Limited format support** — no Glulx support (unlike Fabularium)
- **Keyboard issues** — third-party keyboards sometimes cause problems
- **Dated design patterns** — doesn't follow modern Android Material Design
- **No authoring** — strictly a player, no creation tools

## Key Features

| Feature | Details |
|---------|---------|
| Parser type | Traditional parser (game-dependent) |
| Graphics | Text-only with cover art |
| Multiplayer | None |
| Save system | Game-dependent save/restore |
| Offline play | Full offline |
| Accessibility | Basic |
| Unique | Word-tap input, metadata from IFDB |

## How It Compares to Our Project

### What it does that we don't
- Plays existing Z-machine/TADS game library
- Word-tap input reduces typing friction (clever UX for mobile parser IF)

### What we do that it doesn't
- **Original content** — we're building a game, not an interpreter
- **Smart parser** — embedding-based intent matching vs rigid verb-noun
- **Cross-platform PWA** — works on iOS, Android, and desktop browsers
- **Multiplayer** — shared multiverse
- **Self-modifying world** — dynamic game state as mutable Lua code
- **Modern web deployment** — no app store needed

### Strategic Insight

The word-tap input UX is worth studying — it's an elegant mobile solution to the "typing on phone" problem. Our hybrid parser could incorporate a similar tap-to-suggest system where visible nouns in the text are tappable to auto-fill commands.

Also worth noting: Fabularium (4.2 stars, supports more formats including Glulx, includes a basic IDE) is the more capable Android alternative. Between Frotz (iOS) and Fabularium (Android), the interpreter market is covered but fragmented.
