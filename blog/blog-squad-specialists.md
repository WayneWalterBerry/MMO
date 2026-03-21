# I Hired 5 Specialists This Morning. None of Them Are Human.

*How building an AI game studio taught me that specialists beat generalists — even when they're language models.*

---

I'm building an MMO text adventure game in pure Lua. This morning, I hired five new team members — an Object Designer, a Puzzle Master, an Object Tester, a World Builder, and a UI Engineer. None of them are human. They're AI agents running in GitHub Copilot CLI through a system called Squad, and they just produced more coherent game design in one session than I've gotten from months of solo prompting.

Here's what I learned about why **specialist AI agents** change everything.

## The Generalist Wall

I started this project with a small team: Bart the Architect handles engine code. Frink the Researcher digs into academic papers and competitor analysis. Comic Book Guy (CBG) is the Creative Director. Nelson tests gameplay. Brockman writes documentation. Chalmers manages the project. A solid crew.

But a few weeks in, I hit the wall that every growing project hits.

Bart was writing engine code AND building individual game objects — the `.lua` files that define how a lantern works, how a door opens, how a clock ticks. That's like having your architect also laying bricks. He's context-switching between "how should the finite state machine executor work" and "what does a rusty padlock smell like." Different skills. Different cognitive modes. And the quality of both suffers.

CBG was designing the overall game AND designing individual puzzles. Nelson was testing the whole gameplay loop AND testing whether individual objects have correct state transitions. Everyone was wearing too many hats, and the hats were getting tangled.

This is the generalist trap. You think "the AI can do anything, so just give it everything." But AI agents, like humans, produce better work when they have clear scope, deep context, and focused expertise. A generalist who knows a little about everything will never match a specialist who knows *everything* about one thing.

## The Specialist Pattern

So I started hiring specialists. Not by writing more code — by writing better *charters*.

In Squad, every agent has two critical files:

1. **`charter.md`** — their job description. What they own, what they don't touch, who they collaborate with, and how they work.
2. **`history.md`** — their memory. Everything they've learned across sessions, organized into notes they re-read every time they're spawned.

A specialist is born the moment you draw a clear boundary. Here's what that looks like in practice:

### Flanders — Object Designer/Builder 🔨

**The boundary:** Flanders ONLY builds objects. He reads our 8 Core Architecture Principles, designs FSM states, defines sensory properties (what does it look like? feel like? smell like?), and writes material metadata. His output is `.lua` files in `src/meta/objects/` and design docs in `docs/objects/`.

**The rule:** Flanders does NOT touch engine code. Bart does NOT touch object files. Clean separation.

His charter literally says: *"Does NOT modify engine code (`src/engine/`) — that's Bart's domain."* And Bart's charter says the inverse. When you draw boundaries this explicitly, agents never step on each other's work.

Think of it like a game studio. You don't have your engine programmer also modeling 3D assets. They use different tools, think in different paradigms, and produce different artifacts. Why would AI agents be any different?

### Sideshow Bob — Puzzle Master 🧩

Bob designs puzzles — and ONLY puzzles. But here's what makes him interesting: he's not just a puzzle generator. His charter encodes a **philosophy**.

```
1. Research first. Before designing a new puzzle, read resources/research/puzzles/
   for inspiration and proven patterns.
2. Learn from the greats. Until Bob has significant experience, puzzle designs
   should be grounded in researched patterns — not pure invention.
3. Grow through experience. Bob's expertise accumulates over sessions via
   history.md. As his knowledge base grows, he earns more creative independence.
```

Bob starts conservative — leaning on studied Infocom classics, escape room patterns, and academic papers on puzzle design. As his `history.md` fills up with experience, he earns the right to be more creative. This mirrors how a junior designer at a real studio learns: you study the masters before you invent.

He also created his own rating system (1-5 stars plus the Zarfian Cruelty Scale) and a classification pipeline: 🔴 Theorized → 🟡 Wanted → 🟢 In Game. That pipeline wasn't in his charter — he built it because his charter gave him clear *ownership* of puzzle design, and ownership breeds initiative.

### Lisa — Object Tester 🧪

Lisa tests objects specifically — FSM transitions, mutate fields, sensory properties, material behaviors. Her reports are structured data: "input state → trigger → output state + property changes."

Why not just have Nelson test everything? Because **object testing and gameplay testing are fundamentally different disciplines.** Object testing is data-driven: does this padlock transition from `locked` to `unlocked` when picked? Does the brass material respond correctly to `>125°C`? Gameplay testing is exploratory: can a player figure out they need to heat the padlock with a candle? One is verification. The other is experience design.

### Moe — World Builder 🏗️

Moe designs rooms as *environments* — not isolated boxes but cohesive places. A manor house isn't one room; it's 15+ rooms sharing architecture, era, and internal logic. The study has oak paneling because it's a Victorian manor. The kitchen has flagstone floors because that's what Victorian kitchens had. Moe researched 42KB of room design theory — Zork analysis, Inform 7 patterns, Emily Short's "Room as Character" essay, immersive sim techniques from Thief and System Shock.

Moe's real power is in collaboration. He says "this study needs a grandfather clock and a fireplace" → Flanders builds the objects. He says "there's a hidden passage behind the bookshelf" → Bob designs the puzzle. He works with Frink to research real Victorian architecture. Moe is a creative hub who generates work for other specialists, just like an art director briefing their team.

### Smithers — UI Engineer ⚛️

Smithers owns everything the player actually sees — the REPL experience, parser tiers 1-5, text formatting, disambiguation, error messages, the help system. Nobody owned this before. Parser output was an afterthought. Now it has a dedicated craftsperson.

## Training: Building Agent Memory

Creating a specialist isn't just writing a charter. You have to **train** them.

Training an AI agent is remarkably similar to onboarding a new hire. You don't just hand them a job title and say "go." You sit them down, walk them through the codebase, let them read the existing work, and give them time to take notes.

In Squad, training looks like this:

1. **Spawn the agent** with their new charter
2. **Point them at the relevant files** — "Read all existing object files. Read the core principles document. Read the material properties spec."
3. **Let them write notes** — the agent reads everything, then writes 300-500 lines of organized knowledge into their `history.md`
4. **That file IS their memory** — agents read `history.md` on every spawn. It's their notebook.

When I trained Flanders, he read every existing object file, the 8 Core Principles, and the material properties specification. He wrote 475 lines of organized notes — categorized by design patterns, common pitfalls, and engine capabilities. Next time he's spawned, he reads those notes first. He doesn't start from zero. He starts from where he left off.

Lisa did the same: 308 lines of notes covering FSM testing patterns, common state transition failures, and material property edge cases.

The beautiful thing about this approach is that **agents get smarter over time.** Every session adds to their knowledge base. Bob's first puzzles will lean heavily on researched patterns. After ten sessions of designing puzzles, getting feedback from Nelson's gameplay tests, and iterating — his `history.md` will be dense with hard-won knowledge about what works and what doesn't. He'll earn that creative independence his charter promises.

This is the learning loop: research → design → feedback → learn → better design. The same loop that makes human designers better, except the "learning" step is writing to a file instead of updating synapses.

## Departments: Structure Creates Clarity

Once you have 14 team members, you need organizational structure. I set up departments:

| Department | Lead | Members | Focus |
|------------|------|---------|-------|
| 🎨 Design | Comic Book Guy | CBG, Flanders, Bob, Moe, Lisa | Game content + object testing |
| ⚙️ Engineering | Bart | Bart, Frink, Nelson, Smithers | Engine code, research, system testing |
| 📝 Docs | Brockman | Brockman | Documentation |
| 📋 Operations | Chalmers | Chalmers, Scribe, Ralph | PM, logging, monitoring |

The most interesting decision? **Lisa (object tester) went to Design, not a separate QA department. Nelson (gameplay tester) went to Engineering.**

Why? Testers belong with what they test. Lisa tests objects, so she sits with the people who design and build objects. Nelson tests the whole gameplay system, so he sits with the people who build the engine. No QA silo. This mirrors the DevOps movement's insight: you don't separate the people who build from the people who verify. You embed quality into the team that owns the work.

## The Collaboration Model: How Specialists Work in Concert

Specialists alone aren't enough. The magic is in how they collaborate.

Here's a real example from this morning. CBG (Creative Director) wrote a Level 1 Master Design — a 46KB document describing 7 rooms, 15 puzzles, and roughly 38 new objects. That document became the **single source of truth** that all specialists worked from, in parallel:

- **Moe** read the design and started laying out rooms — sight lines, environmental properties, spatial flow
- **Bob** read the design and started designing puzzles — prerequisite chains, difficulty ratings, sensory hints
- **Flanders** read the design and started specifying objects — FSM states, material properties, sensory descriptions
- **Lisa** prepared test plans for the new objects
- **Nelson** prepared gameplay test scenarios

One vision document, five specialists, all working simultaneously. This is how real studios operate. The creative director doesn't build everything — they articulate the vision, then fan out to specialists who execute it with deep expertise in their domain.

The collaboration chains are equally powerful:

- Frink researches puzzle design (47KB of analysis, 33 academic citations) → Bob reads the research → Bob designs research-grounded puzzles
- Bart builds engine features (material system, GOAP parser) → Flanders uses those features in objects → Lisa tests the objects → Nelson tests the whole system

Information flows through specialists like an assembly line where each station adds expertise.

## What One Session Produced

Numbers from this morning:

- **5 new specialists** hired and trained
- **47KB** puzzle research + **42KB** room research
- **Level 1 designed:** 7 rooms, 15 puzzles, ~38 new objects
- **5 engine bugs** found and fixed
- **Material property system:** 13 materials with threshold checking
- **Puzzle classification system** with rating scales
- **14 team members**, 4 departments, clear ownership everywhere

That's not the output of one person prompting ChatGPT. That's the output of an organized team with defined roles, accumulated knowledge, and clear boundaries.

## Takeaways: Building Your Own Specialist Teams

If you're working with AI agents — whether in Squad, or any multi-agent system — here are the principles that made this work:

### 1. Draw boundaries before you add agents
Don't just add more agents. First, identify where one agent is doing two different *kinds* of work. Bart doing engine code AND object files wasn't a capacity problem — it was a cognitive-mode mismatch. Split by skill type, not by workload.

### 2. Charters are job descriptions — write them like it
A good charter says what the agent owns, what they don't touch, and who they collaborate with. Be explicit about boundaries. "Does NOT modify engine code — that's Bart's domain" is more useful than "focuses on objects."

### 3. Training is onboarding, not prompting
Don't just tell an agent what to do. Give them time to *read*. Point them at every relevant file, let them write notes, and make those notes persistent. A trained specialist with 400 lines of domain knowledge in their history will outperform a generalist with a clever system prompt every single time.

### 4. Memory is a file, not a context window
Context windows reset. Files don't. The `history.md` pattern means agents accumulate expertise across sessions. This is the closest thing to actual learning in current AI systems, and it's just... a text file. Simple, debuggable, version-controlled.

### 5. Embed testers with builders
Don't create a QA silo. Put object testers with object designers. Put gameplay testers with engine engineers. Quality is everyone's job, and testers produce better work when they understand what they're testing at a deep level.

### 6. Let specialists generate work for each other
The best specialists don't just consume tasks — they create work for other specialists. Moe designs a room and generates object specs for Flanders and puzzle briefs for Bob. CBG writes a level design and spawns parallel work streams for five people. This is how you get exponential output from linear headcount.

### 7. Start conservative, earn creative freedom
Bob's charter tells him to research before inventing. As his experience grows, he gets more creative license. This is a pattern you can encode: agents that start by following established patterns and gradually develop their own voice. It's not just safer — it produces better work, because the foundations are solid.

---

This morning I went from a team of generalists bumping into each other to a studio of specialists working in concert. The game isn't finished — we're in the thick of Level 1 design — but for the first time, I can see how it scales. Not by making agents work harder, but by making them work *smarter*, in the same way that real teams have always worked.

You don't build a game studio with ten copies of the same person. You hire specialists, train them well, give them clear ownership, and let them collaborate. Turns out, the same is true when none of them are human.

---

*Wayne "Effe" Berry builds things with AI agent teams. The MMO text adventure is an ongoing project using Squad — a multi-agent orchestration system running in GitHub Copilot CLI. All agents mentioned in this post are AI specialists with Simpsons-character personas, because if you're going to build a team, you might as well give them personality.*
