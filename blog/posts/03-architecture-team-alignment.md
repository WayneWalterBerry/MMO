# Conway's Law Wasn't an Accident—It Was the Feature

**How organizing your codebase by team ownership creates self-synchronizing specialists and eliminates context collisions.**

*By Wayne "Effe" Berry — DRAFT*

---

## The Problem: Architecture Decides Your Team

In Post 1, I hired five specialists — Flanders for objects, Bart for engine, Smithers for UI, Moe for world building, Bob for puzzles. In Post 2, I explained why I spent 160KB on research before writing any code. This post is about something less obvious but more important: **the architecture and the team became the same thing, and it wasn't an accident.**

Conway's Law says your system architecture mirrors your organization's communication structure. Most people cite it as a cautionary tale — a reason why org chart dysfunction produces tangled code. I started treating it as a design principle instead.

I deliberately shaped the codebase to *match* the team. Not because I followed some abstract principle, but because I watched code ownership become the single strongest force organizing human work. When Bart and Smithers were stepping on each other's toes — both hacking parser logic, both touching the main loop — I realized I had a choice: either merge their responsibilities or separate the code they owned.

I chose to separate the code.

The result was something better than either option: a codebase so cleanly partitioned by domain that specialists could work in parallel without meetings, without merge conflicts, without asking permission.

---

## INSIGHT 1: Architecture Mirrors Team Structure (Intentional Conway's Law)

Let me show you the structure:

```
src/
├─ meta/
│  ├─ objects/          ← Flanders (Object Designer)
│  ├─ world/            ← Moe (World Builder)
│  └─ levels/           ← Bart designed, Moe populates
├─ engine/              ← Bart (Architect)
│  ├─ parser/           ← Smithers (UI Engineer)
│  ├─ ui/               ← Smithers (UI Engineer)
│  ├─ fsm/              ← Bart
│  ├─ loader/           ← Bart
│  ├─ containment/      ← Bart
│  ├─ registry/         ← Bart
│  └─ mutation/         ← Bart
└─ main.lua             ← Shared responsibility
```

This structure exists for a reason. **Each specialist owns a directory tree.** Flanders never touches `src/engine/`. Bart never touches `src/meta/objects/`. Smithers doesn't touch `src/engine/fsm/`. The file system becomes a permission boundary. No two specialists edit the same files except for carefully-managed integration points.

Here's what that solves:

### Merge Conflicts Become Impossible

When I had Bart and Smithers both hacking on the main loop (`src/engine/loop/init.lua`), every session produced merge conflicts. One would refactor the parser dispatcher, the other would restructure the REPL I/O handler. Bart's change assumed a certain line number. Smithers's change moved it. Disaster.

So Smithers extracted the parser preprocessing into its own module: `src/engine/parser/preprocess.lua`. Pure functions. No side effects. No shared mutable state with the main loop. Smithers still uses it from `loop/init.lua`, but now the dependency is clean. When Smithers updates the preprocessing pipeline, Bart sees the interface stay stable. When Bart refactors the main loop, Smithers's code remains untouched.

Same pattern for UI: Smithers extracted `src/engine/ui/presentation.lua` (time formatting, light-level display, vision checks) into a pure module that lives in his domain. Verbs still call it. But the module boundary means Smithers can iterate on presentation logic without Bart changing the main loop.

### Synchronization Becomes a Non-Problem

Before this refactor, onboarding Smithers as a new specialist required careful coordination. "Don't touch the main loop right now, Bart is refactoring it." Smithers would have to wait. Or we'd add him to the same files, and suddenly two specialists are synchronizing changes, reviewing each other's work, making sure they don't collide.

After the refactor? Smithers and Bart can work in parallel on their own directories. They never hit each other. No meetings. No "wait, I've got someone making changes to that file right now."

The architecture enforces isolation. Conway's Law becomes self-enforcing.

### Code Ownership Becomes Obvious

Look at the codebase now and you can immediately ask: "Who owns this?" The answer is written in the directory structure.

- Who fixes a bug in how objects transition between FSM states? Bart in `src/engine/fsm/`. But who tests it? Lisa, the object tester, writes test cases in `test-pass/` that hit Bart's code.
- Who implements a new sensory property for objects? Flanders in `src/meta/objects/`. But who tests that it integrates with the FSM engine? Nelson runs a gameplay pass.
- Who refactors the parser? Smithers. Who makes sure it doesn't break existing commands? Smithers writes test cases. Ownership means accountability.

This clarity cascades into documentation. When I reorganized the documentation to match, Bart reads `docs/architecture/engine/`, Flanders reads `docs/architecture/objects/`, Smithers reads `docs/architecture/ui/`. Each specialist has a *focused* set of docs to read. No information bloat. No context wasted reading about things they don't own.

### The Real Test: Adding a New Specialist Mid-Project

I hired Smithers mid-project when parser complexity exceeded what Bart could handle. Here's what happened:

1. I pointed him at `src/engine/parser/` and `src/engine/ui/`
2. Gave him the charter: "You own everything the player sees"
3. Pointed him at `docs/architecture/ui/code-ownership.md` to see the boundary lines

Three hours later, he produced `src/engine/ui/presentation.lua` — a brand new module with 160 lines of pure functions, extracted duplicate time-formatting logic from three places, and wrote comprehensive documentation of what went where.

Bart didn't have to onboard him. The directory structure onboarded him. The documentation boundary showed him exactly what he owned. The architecture made it obvious where to work.

In a codebase organized by layers (all the parser code in one layer, all the rendering in another layer), adding Smithers would require deep understanding of how layers interact. In a codebase organized by *ownership*, he just looked at his directories and got to work.

### The Flip Side: Architecture Decides Team Structure

This relationship goes both directions. The codebase structure doesn't just match the team — it *constrains* how the team can grow.

If I want to add a new specialist for materials and reactions, where does their code go? Probably a new `src/engine/materials/` module that Bart oversees, with specialists able to add new material definitions to `src/meta/materials/`.

If I want to add a new specialist for movement and navigation, where do they work? `src/engine/movement/` owned by that specialist, integrated with Bart's containment and registry systems.

The architecture isn't just expressing the current team. It's expressing the *possible* team structures. Each partition in the codebase represents a potential specialist boundary. You can't hire a specialist and give them a vague mandate. The architecture won't support it. You have to partition the code first, then hire the specialist.

Conway's Law, inverted: the team structure you *want* requires the codebase structure you need. Design the code, design the team.

---

## INSIGHT 2: Doc Reorganization as Context Management

Here's something that surprised me: documentation structure is a performance optimization for AI systems. I've reorganized docs at least **six times** for the exact same reason each time: **limit what agents read at spawn time.**

When Bart spawns to fix a bug, he reads:
- `docs/architecture/engine/` — his domain
- `docs/architecture/00-architecture-overview.md` — the principles he works within
- Maybe specific tier files if he's touching the parser (but he knows those exist)

He does NOT read:
- `docs/architecture/objects/` — not his domain
- `docs/architecture/ui/` — not his domain
- `docs/levels/` — not his concern right now
- Room design theory — irrelevant to fixing a fsm bug

### Why Context Budgets Matter

An agent has a finite context window. It can hold maybe 50-100KB of information comfortably before quality starts degrading. Anthropomorphically: after reading 100KB of docs, the agent's "attention" starts slipping. Later docs are read less carefully. Important details get missed.

When I had a single 62KB architecture overview file covering engines, objects, UI, player systems, everything — agents read the whole thing. When they needed to fix something in the object model, they'd read 62KB, only 15KB of which was actually relevant. That's 47KB of context that could have been used for deeper analysis of the actual problem.

So I split it:
- `docs/architecture/engine/` — FSM, loader, containment, materials, mutation (12KB)
- `docs/architecture/objects/` — Object model, core principles, sensory system (8KB)
- `docs/architecture/ui/` — Parser tiers, presentation, terminal UI (15KB)
- `docs/architecture/player/` — Inventory, movement, skills, state tracking (9KB)

Now when Bart fixes an FSM bug, he reads ~12KB. When Flanders designs a new object, he reads ~8KB. When Smithers optimizes the parser, he reads ~15KB. **Each specialist gets to use their entire context budget for deep work on their actual problem.**

### Parser Documentation: A Case Study in Pruning

Parser documentation was especially egregious. The original "intelligent parser" doc was massive — Tiers 1 through 5, all in one file, with design, implementation, and TODO notes tangled together. When Smithers needed to debug a matching algorithm, he had to read about GOAP planners and LLM fallback strategies (which weren't implemented yet). Context wasted.

So I split it into **five tier-specific files**:
- `parser-tier-1-basic.md` — Exact verb dispatch (✅ Built)
- `parser-tier-2-compound.md` — Phrase similarity (✅ Built)
- `parser-tier-3-goap.md` — GOAP planner (🔷 Designed, not yet built)
- `parser-tier-4-context.md` — Context memory (🔷 Designed)
- `parser-tier-5-slm.md` — SLM/LLM fallback (🔷 Designed)

When Smithers debugs Tier 2, he reads one file: `parser-tier-2-compound.md`. The Tier 3+ files are there if he needs to understand the architecture, but he's not *forced* to read about planned future features.

Each tier file is 2-10KB. Each has clear status (✅ Built or 🔷 Designed). Each lists exactly which source files implement it. Cross-references connect tiers, so you can navigate if needed.

**Result:** Context-efficient. An agent can spawn, read the one or two tier files relevant to their task, and have context left for deep analysis.

### Room and Puzzle Reorganization

Same principle applied to Level 1 design docs. Started with a flat `docs/rooms/` directory — one file per room. But as we grew levels, agents designing Level 1 rooms would inherit docs about Level 2, 3, and future content. Irrelevant. Distracting.

So:
```
docs/levels/01/rooms/    ← Just Level 1 rooms
docs/levels/01/puzzles/  ← Just Level 1 puzzles
docs/levels/02/rooms/    ← Level 2 (when it exists)
```

When Moe designs Level 1 rooms, he reads from `docs/levels/01/`. When Bob designs Level 1 puzzles, he reads from the same level-specific folder. Agents stay focused.

### The Meta-Pattern: Docs Are a Partition of the Code

Here's what I notice: documentation structure mirrors code structure. After I reorganized code by ownership, I reorganized docs by ownership too:

```
docs/architecture/engine/     ← Bart reads this
docs/architecture/objects/    ← Flanders reads this
docs/architecture/ui/         ← Smithers reads this
docs/architecture/player/     ← Shared reference
```

This isn't coincidental. **When docs mirror code ownership, agents read the minimal set of docs needed to understand their domain.** Context budgets last longer. Analysis stays deeper. Quality improves.

It's like this:
- Code structure = who can edit what
- Doc structure = who needs to read what

Align them, and you get a system that scales. Agents onboard faster. Collisions disappear. Knowledge stays localized.

### But: Docs Reorganization Solves a Real AI Limitation

I want to be honest about why this matters. A human developer can *skip* irrelevant docs. They scan the TOC, grab what they need, ignore the rest. An LLM reads what you point it at. If you point it at 62KB of architecture docs, it reads all 62KB. It can't selectively attention. It processes the whole input.

Document organization isn't overhead for human-only teams. It's a necessary architectural pattern for AI-augmented teams. The computer will read what you give it. Give it only what it needs.

I've reorganized docs six times because each time, I noticed: "Agents are reading too much irrelevant context." The fix was always the same: split the doc, reorganize by domain, reduce the size of any single agent's reading list.

---

## How These Two Insights Compound

Alone, each insight is useful:

- Organizing code by team ownership eliminates merge conflicts
- Organizing docs by domain reduces context bloat

Together, they're powerful. A specialist spawns and:
1. Reads their charter (their job description)
2. Reads their focused doc partition (their domain knowledge)
3. Reads their code ownership tree (their workspace)
4. Understands immediately where to work and what to avoid

No ambiguity. No "wait, should I touch this file?" The system answers that question upfront.

When I onboarded Smithers, this is what happened:

1. Pointed him at `docs/architecture/ui/code-ownership.md` — instantly clear what he owns
2. He read `docs/architecture/ui/parser-overview.md` and the five parser tier files — focused context about his domain
3. He looked at `src/engine/parser/` and `src/engine/ui/` — his code directories
4. He identified duplication (time constants repeated in verbs and main loop), extracted them to `src/engine/ui/presentation.lua`
5. He created a new shared module that both he and Bart use

No collision. No coordination overhead. The architecture enabled it.

---

## What Real Prompts Looked Like

When I asked Wayne "Can we separate the engine so Bart and Smithers don't collide?", he didn't give me an abstract answer. He gave Smithers a concrete task:

> *"Smithers, the following files are ones where you and Bart have been working in the same code and causing merge conflicts: src/engine/loop/init.lua, src/engine/verbs/init.lua. Can you refactor these to create clean module boundaries between UI/parsing (your domain) and FSM/registry/engine (Bart's domain)? Your goal is: zero modified lines in Bart's files, all new lines and edits in your modules. Read docs/architecture/ui/code-ownership.md for the current ownership map."*

That prompt didn't ask Smithers to solve the general problem of "separation of concerns." It gave him a specific boundary to draw and a concrete success criterion: "Bart's files stay untouched."

Smithers extracted modules. Documented the boundaries. Created `code-ownership.md` as the source of truth for who owns what.

After that conversation, Bart and Smithers never had a merge conflict again. Not because they were more careful. Because the architecture made collisions impossible.

---

## Constraints Enable Scale

Most conversations about AI systems and teams assume the architecture is fixed. "How do we get agents to collaborate in this existing codebase?"

I ask the opposite question: "What codebase architecture enables collaboration?"

The answer is: one where specialists own partitions, boundaries are clear, and docs mirror code structure. You don't add a specialist and *then* figure out governance. You design the code structure *for* specialization.

Hiring is simple:
1. Identify the domain (UI engineering, object design, puzzle creation)
2. Create a directory for it
3. Hire the specialist
4. Point them at their domain

Onboarding is fast:
1. Read your charter (1-2KB)
2. Read your domain docs (5-15KB)
3. Look at your code directories (they're labeled with your name)
4. Start working

Synchronization is non-existent because the structure prevents collisions.

This is why I keep saying Conway's Law wasn't an accident — it was the feature. A team organized by clear domains, working in clearly-partitioned code, reading focused documentation, can coordinate without meetings.

That's the architecture scaling to 14 specialists working in parallel.

---

## Takeaways: Building for Team-Aligned Architecture

If you're building systems with AI agents or growing a human team:

### 1. Design Code Ownership First
Before you hire specialists, partition the codebase by domain. Each specialist needs a tree they own exclusively. Clean boundaries eliminate coordination overhead.

### 2. Doc Structure Is Derived From Code Structure
Don't reorganize docs because it's "cleaner." Reorganize docs so agents read only what their code domain needs. Match doc partitions to code partitions.

### 3. Use Ownership as a Permission System
When you're unsure if a specialist should edit a file, check the ownership map. If they don't own it, they don't edit it. No meetings needed. The structure decides.

### 4. Boundaries Become Team Clarity
When specialists can't collide with each other, they stop asking permission. They stop waiting for meetings. They work. This is why clear architecture improves team velocity more than process changes do.

### 5. Constraints Enable Scale
A team with no architecture can coordinate with frequent communication (5 people, daily standups). A team with strong architecture can scale to 14+ specialists with minimal overhead. Constraints paradoxically enable freedom.

### 6. Revisit the Organization When You Change the Team
When I added Smithers, I didn't just give him a charter. I reorganized the code to give him ownership boundaries. When I promoted Moe to lead world-building, his directory structure reflected that. The org chart is written in the file system.

---

## What's Next

In Post 1, I explained that specialists beat generalists. In Post 2, I showed how research prevents architectural dead-ends. This post shows how to *structure* that research and those specialists so they scale.

The MMO project now has 14 team members, four departments, and 200KB+ of organized documentation. The Level 1 prototype is functional. Specialists work in parallel without coordination overhead.

None of this happened by accident. It came from deliberately aligning architecture, team structure, and documentation into a self-reinforcing system.

Conway was right. Your system mirrors your organization. So build the organization you want by building the architecture first.

---

*Wayne "Effe" Berry builds things with AI agent teams. This is the third post in a series on building with Squad specialists:*

- *Post 1: [I Hired 5 Specialists This Morning. None of Them Are Human.](blog-squad-specialists.md) — Why specialist AI agents scale better than generalists*
- *Post 2: [I Spent 160KB on Research Before Writing a Single Line of Game Code.](blog-research-driven-development.md) — How research-first development prevents architectural mistakes*
- *Post 3: This post — How architecture mirrors team structure and documentation enables context-efficient agent coordination*
