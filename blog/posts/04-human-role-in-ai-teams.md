# The Decision Architect: Why Humans Get *More* Valuable, Not Less, in AI-Driven Projects

**The human's job isn't writing code or executing tasks. It's asking the right questions, making judgment calls that span contexts, and steering the ship. A close look at how one person's decisions shaped an entire AI team's trajectory.**

*By Wayne "Effe" Berry — DRAFT*

---

## The Fear and the Inversion

People keep asking me the same question: *"If you have 14 AI agents building your game, what do you actually do?"*

The fear is real. When you watch a team of AI agents produce a complete game level in a day — 7 rooms, 15 puzzles, 37 objects, tested and documented — it's natural to wonder where the human fits.

But here's what nobody expects: I've never been more essential to a project in my life.

Not because I'm writing code. I barely write code anymore. My role is something else entirely: **I'm the decision architect**. I shape what gets built by asking the right questions at the right moments, making judgment calls that no agent can make, and steering a 14-person team using nothing but decisions.

---

## Decision #1: "Hire a Researcher First" (March 18)

The project started with a choice: hire an engineer and start writing code, or hire a researcher first.

No AI agent suggested the second option. It was a judgment call—a bet that deep domain knowledge matters more than fast iteration in the first 24 hours.

Frink, the researcher, delivered 160KB of academic-grade research before a single `.lua` file existed:
- 37KB on dynamic object mutation (29 citations)
- 36KB analyzing Dwarf Fortress architecture (34 citations on how DF manages 200,000+ mutable entities)
- 42KB on room design theory (26 citations)
- 47KB on puzzle design (33 citations from Infocom through modern escape rooms)

This wasn't me being cautious. It was me betting that AI agents build from pattern-matching, and pattern-matching on shallow understanding produces architecturally fragile code. The research grounded every downstream decision in evidence.

**Why this matters:** On a human team, a bad architecture decision is painful but fixable. On an AI team with 14 specialists working in parallel, a bad architecture decision permeates *everything*. It lives in agent memory files, design docs, object specs, and test reports. It's scattered across a dozen context windows. Extracting it later is brutal. Getting it right upfront isn't perfectionism—it's a practical constraint of working within distributed context limits.

---

## Decision #2: "Dwarf Fortress Is Our Reference Model" (March 18)

After reading Frink's research, one document changed everything: the Dwarf Fortress architecture comparison.

DF manages 200,000+ mutable entities with emergent behavior. Properties interact. Materials burn, melt, conduct. Objects contain other objects that contain other objects. Frink traced all of it through 34 citations.

I read it, and I made a declaration: *"Dwarf Fortress is our architectural reference model."*

Not because I'd played thousands of hours of DF. Not because I'd studied its source code. Because the research made a compelling case.

**This decision cascaded into everything.** 

Our object model, our containment hierarchies, our FSM engine, our material property system—all of it traces back to that moment. When the team later built a material system where hemp rope burns when exposed to flame and silver conducts electricity, that wasn't accidental. It was the direct consequence of a vision call made on Day 1 after reading research.

An AI agent could have summarized the research. But it couldn't have looked at the project's ambition, the team's capabilities, and the competitive landscape, then declared: *this is our north star.* Vision calls require judgment that spans more context than any single agent window can hold. They're commitments.

When Composite Object Architecture emerged (objects that come apart and carry their pieces), it worked because we'd already decided: DF's property-driven paradigm is our foundation. Every architectural choice since then has reinforced that decision.

---

## Decision #3: "Composite Objects With Disassembly" (March 20)

By March 20, the team had shipped basic rooms and objects. The game was playable. Then I asked a question that shifted everything.

I noticed that game objects were static. You could examine a nightstand. You could open a drawer. But you couldn't *take the drawer with you*. In a real game, a drawer full of items should be portable. A chest should be liftable. A rope should be uncoilable.

This wasn't a code request. It was a design question: *"What if objects could be disassembled and carried as separate entities?"*

Comic Book Guy, the game designer, heard the question and redesigned the entire object system. Objects now have a `composite` architecture:
- A nightstand (parent object, immobile)
- A nightstand drawer (detachable, becomes portable when removed)
- A poison bottle inside the drawer (spawns as its own entity when the drawer is opened)

This single decision unlocked puzzle design that didn't exist before. Suddenly, the game has a new dimension: *physical disassembly as a puzzle mechanic*. A locked puzzle could require finding a key. Or it could require dismantling something to get access to something else.

**The payoff:** That question—asked at the moment when the base architecture was stable but rigid—created emergent gameplay. It wasn't dictated by the Dwarf Fortress reference model; it emerged *from* thinking about what that model enables.

The human's role was to ask the question at the right moment, when the team had enough foundation to execute on it.

---

## Beyond the Three Pivotal Moments: The Architecture of Decisions

The three decisions above are the inflection points. But the human's work is broader than any single moment. It's ongoing, smaller decisions that keep the system coherent.

**When I noticed the light system was binary (on/off) instead of tri-state (lit/dim/dark)**, I raised it during a playtest. The issue wasn't a bug—the code worked exactly as designed. But the design was wrong. An AI testing script wouldn't catch this. It catches "did the function execute?" not "does this make sense in the world?" The human catches world coherence.

**When Bart and Smithers needed to work on the same codebase**, I asked: *"Can we separate ownership so they don't collide?"* That question led to architectural refactoring—UI and parser logic into separate modules, each specialist with their own domain. This is Conway's Law applied intentionally.

**When Bob joined as Puzzle Master**, I directed: *"Bob learns from research first."* No agent suggested this. But I recognized the risk: a new specialist given creative freedom would generate plausible-looking puzzles without proven foundations. So his charter encoded a learning pipeline: study the masters → gain experience via feedback → earn creative independence. His expertise accumulates over sessions via `history.md`.

**When I realized QA needed to move closer to the work**, I dissolved the traditional QA silo. Lisa (object tester) went to Design. Nelson (gameplay tester) went to Engineering. This mirrors the DevOps insight: don't separate builders from verifiers. Embed quality into the teams that own the work.

**When materials needed to scale**, I declared: *"One file per material, living in `src/meta/materials/`."* This small decision reinforced Principle 8 (metadata declares behavior) everywhere. Flanders can add materials without touching Bart's engine code.

**When the status bar needed enhancement**, I asked: *"Should it show the level, not just the room?"* A tiny UI call. A player in a 7-room dungeon needs to know they're on Level 1, The Awakening. That context matters. Small question, immediate implementation, the kind of thing you notice when you're playing the game like a *player*, not reviewing code.

These aren't heroic architectural moments. They're the maintenance work of steering a system: asking the right question at the right time, catching coherence failures, organizing structure, fighting entropy. It's invisible until you realize how much worse things would be without it.

---

## The Questions That Built the Architecture

I don't write code. I don't build objects. I don't design puzzles. But I ask questions. And every major architectural decision in this project traces back to a question I asked.

**"Can we separate the engine so Bart and Smithers don't collide?"**

When Smithers joined as UI Engineer, I noticed the risk immediately. Bart owned the engine. Smithers needed to own the parser and presentation layer. But both lived in the same files. If they worked simultaneously, merge conflicts were inevitable.

So I asked the question. Smithers refactored the UI and parser logic into separate modules — `parser-preprocess.lua`, `parser-presentation.lua`, `status.lua` — with clean ownership boundaries. Each specialist got their own directory. Collisions became impossible. That's Conway's Law, applied intentionally.

**"What happens when objects cross level boundaries?"**

Nobody on the team had raised this. We were designing Level 1 — everyone focused on making seven rooms work. But I was thinking about Level 2.

That question led to a formal directive: if a level designer doesn't want an object to transfer, there must be a puzzle that destroys it before the player can leave. The removal has to feel natural — diegetic, not arbitrary. This constraint shapes every puzzle Bob designs now.

**"Materials should be separate `.lua` files."**

The materials system was initially a single registry file. It worked, but violated the core principle that metadata declares behavior. I directed: split materials into individual files, one per material, in `src/meta/materials/`. This meant Flanders could add new materials without touching Bart's engine code. A small decision that reinforced architecture everywhere.

**"The status bar should show the level."**

A tiny UI call. Smithers had built a status bar showing the room name. I noticed: a player in a 7-room dungeon needs to know which *level* they're in, not just which room. "Level 1: The Awakening — The Cellar Entry" tells you where you are. Just the room name doesn't.

Small question. Immediate impact. The kind of thing you notice when playing the game like a *player*.

---

## The Work Nobody Sees: Entropy and Coherence

Some of my highest-impact contributions aren't dramatic. They're maintenance.

**Documentation reorganization.** I've restructured the docs multiple times—separating design from architecture, creating level subfolders, splitting parser tiers into five separate files. Every reorganization makes it easier for agents to read exactly the right context. A specialist reading 20KB of focused docs produces better work than one reading 60KB of mixed concerns.

**Decision governance.** I've identified that numeric material properties (like Dwarf Fortress) are our biggest design gap. These aren't purely architectural or purely design—they're a cross-domain concern. So I documented them in both `docs/architecture/` and `docs/design/`. When something sits at an intersection, the human makes sure both sides know about it.

**Accuracy over narrative.** When a blog post draft said "people told me this was overkill," I corrected it. That wasn't accurate. AI agents optimize for narrative coherence. Humans optimize for *truth*. Credibility lives in the details.

The invisible work—fighting documentation entropy, catching context drift, keeping the system honest over time—is what prevents slow decay. Without it, the team gradually loses coherence.

---

## What the Decision Architect Actually Does

After managing 14 AI specialists, I can articulate what the human's role actually is. It's not what people expect.

**The human provides vision.** *"Dwarf Fortress is our reference model."* *"Research comes before code."* These are judgment calls that span more context than any agent can hold. They require accountability—the willingness to stake the project on a bet. AI agents evaluate options. Humans choose directions and own the consequences.

**The human asks the right questions at the right time.** Questions like: *"What if objects could be disassembled?"* arrive at moments of maximum impact. Asking it during Level 1 design prevents architectural brittleness after three levels are built. Timing requires awareness of the project's trajectory, not just its current state.

**The human catches coherence failures.** A player can't simultaneously see dawn light and a dark drawer. Technically, both are correct. But together, they violate world coherence. Testing scripts verify contracts. Humans verify *meaning*. The human plays the game like a player, not a developer.

**The human governs.** Principles, org structure, learning pipelines, documentation standards—only the human declares these as policy. *"Bob learns from research first"* isn't a suggestion; it's a directive. *"Testers sit with builders, not in a QA silo"* is a structural decision. Governance requires authority and accountability.

**The human fights entropy.** Code rots. Context drifts. Documentation becomes stale. The human notices, reorganizes, corrects, and keeps the system honest. This is the work that doesn't ship but enables everything else to ship well.

---

## The Real Dynamic: Amplification, Not Replacement

Here's what I didn't expect: working with AI made my *human* skills more valuable, not less.

Before this project, my "skills" were a normal engineering mix—technical knowledge, system design, some people management. With 14 AI specialists handling code, design, testing, and documentation, my technical skills became almost irrelevant. I don't need to write Lua or debug parser edge cases.

But my judgment became *more* important. My ability to see the whole board. My instinct for when something doesn't feel right. My sense of timing. My stubbornness about quality. My willingness to play the game like a player, not a developer.

The irony: the skills that don't automate—judgment, vision, timing, coherence-checking—turn out to be the highest-leverage skills there are.

When I declare "Dwarf Fortress is our reference model," I'm betting the project on it. That bet changes how carefully I choose. When I ask "can objects be disassembled?" I'm imagining 100 possible emergent behaviors and choosing the one that feels right. When I catch a world coherence failure, I'm the only person in the room who experiences the game as a *player*.

These aren't tasks. They're functions. And they're irreducible to automation because they require accountability. A decision architect lives with the consequences of their decisions.

**The fear is pointed at the wrong thing.** AI doesn't replace the human. AI replaces the *tasks* the human used to do. What's left after you strip away the tasks is the *judgment*. And judgment turns out to be the activity that creates the most value.

The human's highest-leverage activity isn't writing code. It's asking the right questions at the right time, in front of agents who can synthesize those questions into working systems. That's not replacement. That's amplification.

---

*This is Post 4 in a series about building an MMO text adventure with a 14-person AI team.*

- *Post 1: [I Hired 5 Specialists This Morning. None of Them Are Human.](/blog/blog-squad-specialists)*
- *Post 2: [I Spent 160KB on Research Before Writing a Single Line of Game Code.](/blog/blog-research-driven-development)*
- *Post 3: Coming soon*
- **Post 4: The Decision Architect: Why Humans Get *More* Valuable, Not Less, in AI-Driven Projects** ← You are here
