# AI Dungeon — Latitude

## Overview

| Field | Details |
|-------|---------|
| **Game** | AI Dungeon |
| **Developer** | Latitude (Nick Walton) |
| **Platforms** | iOS, Android, Web |
| **Price** | Free (base); Premium $9.99/mo; Plus $29.99/mo (better AI models) |
| **Category** | AI-generated text adventure / sandbox RPG |

## What It Is

AI Dungeon uses **large language models** (GPT-based) to generate interactive fiction in real-time. Players type any action they want — "I fly to the moon," "I bake a cake for the dragon" — and the AI generates a narrative response. There are no pre-authored scenarios (though users can create and share starting templates). It's essentially **unlimited interactive fiction** powered by AI.

This is our most philosophically interesting competitor because it explores the same "infinite possibilities" space from the opposite direction: we use authored content with procedural generation; AI Dungeon uses pure AI generation.

## Ratings & Reviews

| Platform | Rating | Reviews | Downloads |
|----------|--------|---------|-----------|
| iOS App Store | ⭐ 4.4/5 | 26,000+ ratings | N/A |
| Google Play | ⭐ 4.0/5 | 100,000+ ratings | Millions |

## What Players LOVE

- **Infinite freedom** — "be anyone, do anything"; no constraints on player input
- **AI creativity** — generates surprising, often delightful narrative responses
- **Community scenarios** — users create and share starting templates
- **Multiplayer adventures** — collaborative storytelling sessions
- **Free to start** — no paywall for basic experience
- **Genre flexibility** — fantasy, sci-fi, modern, horror, whatever you type
- **Rapid iteration** — the AI responds instantly; no waiting for authored content

## What Players HATE

- **AI inconsistency** — the AI "forgets" context, contradicts itself, generates nonsense
- **World/data loss** — saved games and custom content sometimes deleted without warning
- **Subscription cost** — best AI models locked behind $30/month subscription
- **Content policy changes** — moderation filters frustrate players who want creative freedom
- **Repetitive AI patterns** — the AI falls into formulaic responses over time
- **No real game mechanics** — no inventory, no puzzles, no consistent world rules
- **Bugs and instability** — frequent crashes and glitches after updates
- **Legacy player frustration** — long-time users feel the AI got worse over time
- **Per-session token limits** — free tier has energy/action limits

## Key Features

| Feature | Details |
|---------|---------|
| Parser type | **Free-form text input** — type anything; AI responds |
| Graphics | None (optional image generation on premium) |
| Multiplayer | Yes — collaborative story sessions |
| Save system | Cloud saves (sometimes unreliable) |
| Offline play | No (requires server-side AI) |
| Engine | GPT-based LLM (server-side) |
| Content creation | User-created scenarios and templates |
| Cost model | Subscription ($10–$30/mo for better models) |

## How It Compares to Our Project

### What AI Dungeon does that we don't
- **Unlimited input freedom** — accepts literally any typed input; our parser must handle a defined verb vocabulary
- **AI-generated content** — infinite novel content; we need authored + procedural content
- **Collaborative multiplayer** — real-time co-op storytelling
- **No content creation effort** — the AI generates everything; we must build worlds
- **Massive user base** — millions of downloads; proven demand for text adventure on mobile

### What we do that AI Dungeon doesn't
- **Consistent world rules** — our Lua engine enforces physics, logic, inventory; AI Dungeon has no rules
- **Reliable state** — FSM-driven objects maintain consistent state; AI Dungeon's world is incoherent
- **No server dependency** — our game runs entirely on-device; AI Dungeon requires internet
- **No subscription cost** — Decision 17: zero per-player token cost
- **Puzzle design** — authored puzzles with guaranteed solutions; AI Dungeon can't create solvable puzzles
- **Persistent world** — our universe persists and evolves; AI Dungeon sessions are ephemeral
- **Data sovereignty** — player data stays on their device; AI Dungeon sends everything to servers

### Strategic Insight

AI Dungeon is the **cautionary tale** of the AI-first approach. It proves massive demand for free-form text adventure on mobile (millions of downloads), but also proves that **pure AI generation fails at game design** — no consistent world, no real puzzles, no reliable state. Players love the freedom but hate the incoherence.

**Key lessons:**
1. **Free-form input is the dream** — players WANT to type anything; our parser should aspire to this
2. **Consistency matters more than freedom** — players ultimately want a world that makes sense
3. **Subscriptions are contentious** — $30/month for text games creates backlash; one-time purchase preferred
4. **Server dependency is a vulnerability** — AI Dungeon's users lose data; our on-device approach is safer
5. **AI augmentation, not AI generation** — use AI (our Tier 2/3 parser) to understand player intent, but keep the world deterministic

**Decision 17 validation:** AI Dungeon's subscription backlash proves that per-player token costs create unsustainable business models for text games. Our zero-cost on-device approach is strategically correct.
