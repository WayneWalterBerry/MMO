# Decision: Competitive Landscape Findings — Strategic Implications

**Agent:** Frink (Researcher)  
**Date:** 2026-07-24  
**Status:** PROPOSED  
**Relates to:** Decisions 17, 19; Parser architecture; Multiplayer design

## Context

Completed competitive analysis of 16 mobile text adventure / interactive fiction competitors across parser-based, choice-based, MUD/multiplayer, and narrative game categories.

## Key Strategic Decisions Proposed

### 1. Tap-to-Suggest UI Is Required (Not Optional)

Every parser game on mobile suffers from "typing on phones sucks." Choice-based games dominate downloads *specifically because* they eliminated typing. Our embedding parser solves the NLP problem, but we still need a **tap-to-suggest interface** that displays contextual verb/noun options alongside the text input. This makes the parser feel like a choice game for casual players while preserving free-form input for power users.

**Evidence:** Frotz (4.8★ but keyboards are top complaint), Son of Hunky Punk (word-tap feature is most praised UX), Choice of Games (240K downloads with zero typing).

### 2. Async Multiplayer First, Real-Time Later

80 Days' asynchronous multiplayer (seeing other players on a globe without direct interaction) is the most elegant solution studied. Low server cost, high emotional impact. Our first multiplayer feature should be async — show other players' universe states, discoveries, or progress. Real-time MUD-style multiplayer is expensive and fragile.

**Evidence:** 80 Days (BAFTA-nominated, 4.5★), Torn City (1M+ downloads but clunky), MUDs (decades of server maintenance burden).

### 3. Ship Complete Experiences

Magium's #1 complaint is unfinished content despite 1.3M downloads and 4.9★ rating. Players hate waiting for incomplete stories. Each release should be a **complete, self-contained experience** — even if small. Better to ship a perfect 2-hour game than a 20-hour game missing its ending.

### 4. A Dark Room's Progression Model Is the Template

A Dark Room's genre-evolution (idle → resource management → exploration RPG) is the most successful text game structure ever created (#1 App Store). Our "start in darkness" should similarly transform — from tactile exploration to puzzle-solving to world-building to multiplayer discovery. Each phase should feel like a new game.

### 5. Our Biggest Risk Is Discovery, Not Quality

As a PWA without app store presence, we face the same discovery problem as Twine games (thousands exist, nobody can find them) and Kingdom of Loathing (20-year community but zero mobile presence). We need a distribution strategy beyond "build it and they'll come."

## Recommendation

Proceed with current architecture (Lua engine, Wasmoon PWA, embedding parser). Add tap-to-suggest UI to parser roadmap. Design first multiplayer feature as async. Plan content releases as complete chapters.
