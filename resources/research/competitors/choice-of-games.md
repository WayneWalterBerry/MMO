# Choice of Games — ChoiceScript Platform

## Overview

| Field | Details |
|-------|---------|
| **Game** | Choice of Games (omnibus app + individual titles) |
| **Developer** | Choice of Games LLC |
| **Platforms** | iOS, Android, Web, Steam |
| **Price** | Free app; individual stories $2.99–$6.99; some free with ads |
| **Category** | Choice-based interactive fiction — text novel with branching paths |

## What It Is

Choice of Games is both a **platform** and a **publisher** of interactive text novels built on the ChoiceScript engine. Players read story text and make choices from presented options — no typing, no parser. The library spans 100+ titles across fantasy, sci-fi, romance, mystery, and superhero genres. Key titles include *Choice of the Dragon*, *Choice of Robots*, *Versus*, and *Affairs of the Court*.

ChoiceScript is open-source and supports community authoring via the "Hosted Games" imprint, which publishes community-written titles. This creates a flywheel: authors write for the platform, attracting readers, who fund more authoring.

## Ratings & Reviews

| Platform | Rating | Reviews | Downloads |
|----------|--------|---------|-----------|
| iOS App Store | ⭐ 4.6/5 | ~1,100 ratings | N/A |
| Google Play | ⭐ 4.7/5 | ~4,100 ratings | ~240K+ |

## What Players LOVE

- **Writing quality** — sophisticated, literary-grade prose; many titles rival published novels
- **Deep branching** — choices genuinely matter; stats track consequences across the story
- **Character customization** — gender, orientation, personality all player-defined
- **Replay value** — different choices lead to meaningfully different stories
- **No graphics needed** — the writing is compelling enough to carry the experience
- **Author community** — ChoiceScript is open; players can become authors
- **Inclusive representation** — gender-neutral options, LGBTQ+ representation standard
- **Niche genres** — stories about topics (political intrigue, AI ethics, vampire courts) that AAA games ignore

## What Players HATE

- **Pay per story** — each title costs $3–$7; library gets expensive
- **Inconsistent quality** — Hosted Games (community titles) vary wildly in quality
- **Wall of text** — long passages between choices can feel like reading, not playing
- **No dark mode** (requested frequently)
- **Limited interactivity** — choose from 2–5 options; no free-form input
- **Some stories feel railroaded** — choices seem meaningful but converge to same outcomes
- **App navigation** — discovery and library management could be improved

## Key Features

| Feature | Details |
|---------|---------|
| Parser type | **Choice-based** — select from presented options, no typing |
| Graphics | None (pure text) |
| Multiplayer | None |
| Save system | Checkpoint saves within stories |
| Offline play | Yes (after download) |
| Engine | ChoiceScript (open source) |
| Content creation | Yes — ChoiceScript allows anyone to write and publish |
| Stats tracking | Yes — hidden stats affected by choices |

## How It Compares to Our Project

### What Choice of Games does that we don't
- **100+ published titles** — massive content library across genres
- **Author community/ecosystem** — ChoiceScript enables fan authoring → content flywheel
- **Zero typing required** — pure choice selection eliminates mobile input friction
- **Proven business model** — per-title purchases sustain ongoing content creation
- **Writing quality bar** — editorial process ensures literary quality

### What we do that Choice of Games doesn't
- **Parser-based exploration** — free-form text input enables emergent discovery; choice-based is inherently limited
- **Spatial world model** — rooms, objects, containment hierarchy; CoG has no physical world
- **Multiplayer/MMO** — shared universe; CoG is single-player
- **Self-modifying world** — dynamic Lua-driven state vs. static branching script
- **Object interaction** — FSM-driven objects with state machines; CoG has only narrative variables
- **Tactile exploration** — physical "feeling around in the dark"; CoG is reading + choosing

### Strategic Insight

Choice of Games is the **commercial benchmark for text-only mobile games**. Their key innovation is **eliminating the parser entirely** in favor of presented choices, which removes the #1 mobile friction point (typing). Their weakness is that **choice-based games can't surprise** — you always see all available options. Parser games enable discovery and emergent play that choice-based can't match.

**Key lesson:** We should consider offering a "choice mode" fallback where the parser suggests 3–5 contextual options for players who don't want to type. This gives us Choice of Games' accessibility while preserving parser discovery for advanced players.

**Market note:** 240K+ downloads on Android alone proves sustainable demand for premium text-only mobile games.
