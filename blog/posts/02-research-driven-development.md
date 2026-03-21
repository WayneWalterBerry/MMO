# I Spent 160KB on Research Before Writing a Single Line of Game Code. Here's Why.

**How a research-first, documentation-driven workflow produced a playable prototype in one session — and why it's neither Waterfall nor Scrum.**

*By Wayne "Effe" Berry — DRAFT*

---

## The First Hire Wasn't a Coder

When I started building an MMO text adventure engine — a Lua-based interactive fiction system inspired by Zork — my first instinct should have been to spin up an engineer and start writing code. That's what most developers do. That's what Agile tells you to do: ship something, learn from it, iterate.

Instead, my first hire was a researcher.

Not an architect. Not a designer. Not a tester. A researcher named Frink whose entire job was to read academic papers, analyze competitor architectures, and produce synthesis documents with citations.

Before a single `.lua` file existed, Frink delivered:

- **37KB** on dynamic object mutation — 29 citations spanning Harel statecharts, Entity-Component Systems, and Dwarf Fortress
- **36KB** comparing our architecture against Dwarf Fortress — 34 citations on how DF manages 200,000+ mutable entities
- **42KB** on room design theory — 26 citations including Inform 7 design patterns, Emily Short's spatial authoring philosophy, and Thief's immersive level design
- **47KB** on puzzle design — 33 citations tracing the evolution from Infocom's logic gates to modern environmental storytelling

That's roughly **160KB of academic-grade research** before anyone wrote `function init()`.

I knew from previous Squad projects that this had to come first. LLMs understand *something* about MUDs and text adventures — they can generate plausible-looking code for one. But they don't understand them *deeply*. They don't know why Dwarf Fortress's property-bag architecture scales to 200,000 mutable entities, or why Emily Short's spatial authoring philosophy produces better rooms than naive description strings, or how Infocom's puzzle gates evolved into modern environmental storytelling.

Without research, AI agents build from shallow pattern-matching. With research, they build from deep domain knowledge. The difference shows up in every decision they make downstream.

---

## Why Research First? Because Architecture Is Permanent

Here's the insight that drives everything: **architecture decisions are the most expensive to reverse.** A bug in a puzzle takes minutes to fix. A misguided object model takes weeks — or forces a rewrite.

This is true on any software project. But it's *especially* true when building with AI agent teams. On a human project, a bad architecture decision lives in the code and maybe some design docs. You refactor the code, update the docs, move on.

On a Copilot/Squad project, a bad architecture decision doesn't just live in the code — it permeates *everything*. It's in agent history files (their accumulated memory). It's in the decisions ledger. It's in the research documents that justified it. It's in the object specs that were built assuming it. It's scattered across fragments of context in a dozen agent histories, test reports, and design docs. You can say "don't do that anymore," but extracting a wrong assumption from everywhere it's been absorbed is genuinely hard. The agents learned it. They built on it. Their subsequent decisions assume it.

Research prevents this. When your architecture is grounded in 160KB of cited, analyzed, cross-referenced research, the probability of a fundamental misstep drops dramatically. You're not guessing — you're building on evidence.

And here's the deeper reason this matters for AI teams specifically: **context is limited.** An agent can't hold the entire project in its head at once. It reads its history, the decisions ledger, and the files you point it at — but it can't see everything simultaneously. When a wrong architectural assumption has propagated across dozens of files and agent memories, no single agent spawn has enough context to find and fix every instance. The contamination is distributed across more surface area than any one context window can cover. Getting it right the first time isn't perfectionism — it's a practical necessity of working within context limits.

When I analyzed Frink's research, one document changed the entire trajectory of the project: the Dwarf Fortress architecture comparison. DF manages hundreds of thousands of mutable objects with emergent behavior. My engine needed to do the same thing at a smaller scale — objects that change state, contain other objects, respond to sensory interaction, and mutate based on player actions.

I declared Dwarf Fortress as our architectural reference model. Not because I guessed it was right, but because 34 citations worth of analysis said it was right. That decision cascaded into everything: our object model, our containment hierarchies, our FSM engine, our material property system.

Research didn't just inform the architecture. Research *was* the architecture's foundation.

---

## The Documentation Spine

After research came documentation — not as an afterthought, but as the primary deliverable.

I established **8 Core Architecture Principles** as inviolable rules. Every one traces back to the research:

1. **Code-Derived Mutable Objects** — Objects are mutable Lua tables derived from immutable source code
2. **Base Objects → Object Instances** — Immutable templates spawn mutable instances at runtime
3. **Objects Have FSM; Instances Know Their State** — Every object is a finite state machine
4. **Composite Objects Encapsulate Inner Objects** — Spatial containment hierarchies (coins in bags, bags in rooms)
5. **Multiple Instances Per Base Object** — Many instances from one template, each with unique GUID
6. **Objects Exist in Sensory Space** — Sensory descriptions are state-dependent
7. **Objects Exist in Spatial Relationships** — Containment and location hierarchies
8. **The Engine Executes Metadata; Objects Declare Behavior** — Generic executor reads object declarations, no hard-coded behavior

Principle 8 — the metadata-driven execution model — came directly from Frink's Harel statechart research. Without that research, I would have hard-coded object behaviors. With it, I built a generic FSM executor that reads object metadata. That single principle is probably responsible for 60% of our engine's flexibility.

These 8 principles became our constitution. Every specialist reads them before spawning. They don't bend. They don't get "adapted" based on sprint feedback. They are load-bearing walls, not suggestions.

---

## Core Principles as Constitution

This is where my approach diverges sharply from Agile orthodoxy.

Scrum tells you to "respond to change over following a plan." That's excellent advice for feature requirements. It's terrible advice for architecture. If your object model changes every sprint, you're not iterating — you're thrashing.

My 8 principles are immutable. When the team grew from 5 to 14 members, those principles prevented architectural drift. When a new specialist joined — Smithers for UI engineering, added mid-project when parser complexity exceeded what we'd planned — he read the principles, understood the boundaries, and built within them.

The principles don't constrain creativity. They *channel* it. Puzzle designer Bob can invent any puzzle he wants as long as it works through FSM state transitions and sensory interactions. World builder Moe can design any room as long as objects follow the containment model. The principles are guardrails, not handcuffs.

With 14 AI specialists working in parallel, those guardrails aren't optional. They're survival.

---

## The Parallel Cascade

Here's where the methodology gets interesting. My workflow follows a clear sequence:

**Research → Architecture Docs → Design → Build → Test → Iterate**

If you squint, that looks like Waterfall. Research before design. Design before code. Specs before implementation. Phase gates. Documentation as deliverable.

But it's not Waterfall. Here's why.

In my workflow, these phases **overlap**. While Nelson runs gameplay test pass #012 on existing rooms, Moe is designing new rooms from his own specifications. While Bob designs puzzles, Flanders builds objects from completed specs. While Lisa tests object behavior and files bug reports, Bart fixes engine issues based on her findings.

The waterfall flows, but it flows through parallel channels:

```
Research ──→ Architecture Docs ──→ Design ──→ Build ──→ Test
                                    ↓           ↓         ↓
                               [Moe designs]  [Bart builds] [Nelson tests]
                               [Bob designs]  [Flanders builds] [Lisa tests]
                                    ↑___________________________↓
                                         feedback loops
```

Nelson finds a puzzle that's too obscure → feedback goes to Bob → Bob redesigns → Flanders rebuilds the objects → Nelson retests. Lisa finds an FSM transition bug → Flanders fixes it → Lisa retests. These are tight feedback loops running inside a cascading structure.

I call this the **Parallel Cascade**. The waterfall phases happen in order for any given feature, but multiple features flow through different phases simultaneously. And unlike pure Waterfall, the phases feed back into each other.

### What This Looks Like in Practice

Here are actual prompts I gave the Squad during this project. These aren't sanitized — they're what I actually typed:

**Shaping the research direction:**
> *"Put Puzzle Research Here: C:\Users\wayneb\source\repos\MMO\resources\research\puzzles"*

> *"Train Bob that puzzle creation needs to be done from research first, however he is allowed to make up his own puzzles, but since he is new to puzzle making he needs to work from the classics until he learns more about how to create good puzzles."*

**Asking architecture questions that shaped the engine:**
> *"Bart, we are going to need a way (back door) for testers to test rooms, where they don't have to start at the player starting room, they can start in any room to test it."*

> *"Have Smithers attempt to refactor the code for a separation between the objects handling, UI, and parser. This way Bart can work on the engine at the same time as Smithers. I am not sure this is possible, but give it a try."*

**Setting design constraints:**
> *"Objects might cross level boundaries, if a player picks them up from one level they may take them to another level. If the level designer doesn't want an object to transfer to the next level, then there needs to be a task/puzzle that destroys that object before they can enter the next level."*

**Organizing the team:**
> *"Put QA into the other departments. Lisa to Design, and Nelson to Engineering."*

**Directing the build pipeline:**
> *"Design Department: Review the current rooms and come up with an overall plan for Level 1 (Intro Level), design the rooms, puzzles and objects for Level 1. Document them, but don't implement them yet."*

None of these prompts are code. None of them are specifications. They're **questions, constraints, and directions** that shaped what the AI team built. The human's job isn't to write the code — it's to ask the right questions at the right time.

---

## Where Scrum Falls Short for AI Teams

Scrum was designed for human teams making judgment calls in meetings. Several of its core ceremonies don't translate to AI-assisted development.

**No sprints.** Work flows continuously. When Moe finishes a room design, Flanders starts building its objects immediately. No sprint boundary delays us.

**No user stories.** I think in terms of architecture, not features: "The light system needs a consumable fuel model that integrates with the FSM engine." User stories describe *what*. Architecture principles describe *why* and *how*.

**Research isn't "just enough."** Scrum encourages minimal upfront design. But when 14 specialists will build on an object model for months, "just enough" research is a trap. My 160KB of research wasn't gold-plating. It was load-bearing.

**Documentation is the architecture.** In Scrum, docs are overhead. In my workflow, docs are the source of truth. Every specialist reads them before working. When docs and code disagree, the docs win.

---

## Where Waterfall Falls Short

It's not pure Waterfall either.

**Living documents.** Docs get reorganized as understanding grows. Parser documentation split from 2 files into 5 tier-specific files when complexity demanded it. Waterfall specs are frozen; mine evolve.

**Mid-stream hiring.** When parser complexity exceeded our plan, I hired Smithers as a UI engineer. Waterfall assumes you know resource needs upfront. I don't.

**Emergent requirements.** Material properties emerged from research mid-project, not from an initial spec. The 27KB material properties doc was written because research revealed we needed it.

**Continuous testing.** Nelson has run 12 test passes. Each finds issues, triggers fixes, gets re-verified. Waterfall's testing comes at the end. Mine runs alongside building.

---

## What This Actually Is

After months of working this way, I think what I've built is a distinct methodology. I'm calling it **Research-Driven Development**, and it has five defining characteristics:

### 1. Research Informs Architecture
Not gut feeling. Not "best practices." Not what the last project did. Actual academic-grade research with citations. The research doesn't just validate decisions — it generates them. Principle 8 (metadata-driven execution) exists only because Frink's statechart analysis revealed it.

### 2. Principles Are Immutable
Eight principles. Load-bearing. Non-negotiable. They prevent architectural drift across a team of 14 specialists working in parallel. Scrum would "inspect and adapt" them. I don't. They're the constitution.

### 3. Documentation Is Architecture
Docs aren't written after the code. Docs *are* the architecture. Specialists read them before spawning. Design docs exist before implementation. The document trail is the project's skeleton.

### 4. Specialists Over Generalists
Each phase has an expert. Nobody wears multiple hats. Boundaries (whether by department or by domain) create quality. When specialists own distinct parts of the architecture — Bart owns the engine, Flanders owns objects, Smithers owns UI — they can go deep without stepping on each other. This is why we split the codebase by team ownership, not by layer.

### 5. The Parallel Cascade
Waterfall phases happen — research, design, build, test — but they overlap, run in parallel, and feed back. It's a cascade with loops. A waterfall that spirals.

---

## What This Produced

The proof is in the output. Using this methodology, one session of coordinated work produced:

- 🎮 **A 47KB Level 1 Master Plan** with 7 rooms, 15 puzzles, and 38 objects — fully designed before any room was built
- 🏗️ **45+ implemented objects** with FSM behavior, sensory descriptions, and material properties
- 🧪 **12 gameplay test passes** with documented bugs and verified fixes
- 📐 **8 immutable architecture principles** that held firm as the team doubled in size
- 📚 **200KB+ of research** that prevented at least three architectural dead-ends I can identify
- 🗺️ **A functional prototype** you can run with `lua src/main.lua` — rooms, objects, puzzles, parser, light system, inventory, the works

Level 1 went from concept to playable prototype with a coordinated team of specialists, each working from documented specifications that traced back through design docs, through architecture principles, all the way down to research citations.

Nothing was ad-hoc. Everything has a paper trail.

---

## Takeaways for Practitioners

1. **Hire the researcher first.** The research will save you from architectural mistakes that cost 10x more to fix than to prevent.

2. **Write immutable principles before code.** They scale when your team grows. Scrum's "inspect and adapt" doesn't work for architecture.

3. **Organize code by team ownership, not by layer.** Specialists own directories, reducing collisions and clarifying boundaries.

4. **Doc structure is context optimization.** Smaller, focused docs mean agents read exactly what they need.

5. **Let scope reveal the team.** Don't hire everyone upfront. When complexity demands a specialist, bring one in. Smithers joined mid-project.

---

## The Uncomfortable Truth

The uncomfortable truth about building with AI is that the bottleneck isn't code generation. It's *direction*. AI specialists can produce enormous volumes of high-quality work — but only if they know what to build, why they're building it, and what constraints they must respect.

Research provides the *why*. Documentation provides the *what*. Principles provide the *constraints*. The Parallel Cascade provides the *when*.

Get those four things right, and the code almost writes itself.

Get them wrong, and you'll generate a lot of code very fast in exactly the wrong direction.

I know which one I'd choose. I chose it on day one, when I hired a researcher instead of a coder.

---

*Wayne "Effe" Berry builds things at the intersection of game design, AI collaboration, and documentation-driven development. This post describes the methodology behind [MMO](https://github.com/WayneWalterBerry/MMO), a Lua-based interactive fiction engine built with a team of 14 AI specialists.*

**DRAFT — Not for publication. Pending Wayne's review.**
