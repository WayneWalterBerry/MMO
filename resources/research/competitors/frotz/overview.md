# Frotz — Z-Machine Interpreter

## Overview

| Field | Details |
|-------|---------|
| **Game** | Frotz |
| **Developer** | Craig Smith (iOS); community ports elsewhere |
| **Platforms** | iOS (primary); no official Android app. Android users use Fabularium or Son of Hunky Punk |
| **Price** | Free, open source |
| **Category** | IF interpreter — plays Z-machine, TADS, Glulx games (Zork, Planetfall, etc.) |

## What It Is

Frotz is not a game itself but an **interpreter** that plays thousands of classic and modern interactive fiction titles written for the Z-machine virtual machine (the engine behind Infocom's games like Zork). It also supports TADS and Glulx formats. The app provides access to the IFDB library and is the gold standard for playing parser-based IF on mobile.

## Ratings & Reviews

| Platform | Rating | Reviews |
|----------|--------|---------|
| iOS App Store | ⭐ 4.8/5 | ~250 ratings |
| Android | N/A | No official app |

## What Players LOVE (5-Star Reviews)

- **Massive library access** — instant connection to thousands of free IF games from IFDB
- **Nostalgia factor** — "brings back Infocom memories perfectly"
- **Reliable gameplay** — smooth text input, stable performance across iOS versions
- **Clean interface** — minimal design that lets the text shine
- **Free and open source** — no ads, no IAP, no strings attached
- **Format breadth** — Z-machine + TADS + Glulx in one app

## What Players HATE (1-2 Star Reviews)

- **Library organization** — no folders, poor sorting/filtering for large game collections
- **Minor display bugs** — occasional issues with custom game icons
- **No Android version** — Android users are left looking for alternatives
- **Dated UI** — functional but not "modern" feeling
- **Keyboard friction** — typing commands on a phone touchscreen is clunky (inherent to parser IF on mobile)

## Key Features

| Feature | Details |
|---------|---------|
| Parser type | Full traditional parser (verb-noun, depends on game) |
| Graphics | Text-only (some Glulx games have images) |
| Multiplayer | None |
| Save system | Per-game save/restore |
| Offline play | Full offline |
| Game creation | No (interpreter only) |
| Accessibility | VoiceOver support |

## How It Compares to Our Project

### What Frotz does that we don't
- Access to 10,000+ existing IF games — enormous content library from 40+ years of community creation
- Multi-format support (Z-machine, TADS, Glulx) — plays almost everything
- Established community trust — decades of reputation

### What we do that Frotz doesn't
- **Original game content** — Frotz is a player, not a game; we're building an actual experience
- **Modern parser** — our Tier 2 embedding parser understands natural language; Frotz games rely on rigid verb-noun parsing
- **Multiplayer/MMO** — Frotz is single-player only; our multiverse architecture enables shared worlds
- **Self-modifying universe** — our Lua engine treats the world as mutable code; traditional Z-machine games are static
- **PWA deployment** — we run in any browser; Frotz requires an iOS app install
- **Mobile-first design** — our UI will be designed for touch from day one; Frotz retrofits a 1980s text interface to phones

### Strategic Insight

Frotz proves there's a dedicated audience for parser IF on mobile (4.8 stars!), but that audience is frustrated by keyboard input on phones. Our embedding-based parser that accepts natural language instead of rigid `VERB NOUN` syntax directly addresses this pain point.
