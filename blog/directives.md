# Blog Directives

Rules for writing and editing the blog series. All agents writing blog content must follow these.

## Wayne Must Sign Off Before Publishing

No blog post may be published (pushed to `WayneWalterBerry.github.io/_posts/`) until Wayne has explicitly approved it. "Looks good" or "publish it" counts. Silence does not. If in doubt, ask.

## Published Posts — Do Not Modify

Once a post is published, it is FROZEN. No edits, no corrections, no "small updates."
- **Post 01** (`posts/01-squad-specialists.md`) — ✅ PUBLISHED. Do not touch.
- If a published post has an error, address it in a future post, not by changing the original.

## Real Prompts as Examples

Readers benefit from seeing the actual prompts Wayne gave the Squad. Include real examples whenever possible:
- Use blockquote format with context about when/why the prompt was given
- Show the prompt verbatim (or near-verbatim) — don't sanitize or polish
- Brief annotation after each prompt explaining what it triggered or why it mattered
- These are the most valuable parts of the posts — they show the human's real contribution

## Voice & Authenticity

- Write in Wayne's voice — first person, conversational, direct
- Use REAL prompts, REAL moments, REAL decisions from the project history
- Never fabricate quotes, prompts, or outcomes
- If you don't have a real example, say so — don't invent one

## No Redundancy Across Posts

- Each post teaches ONE unique lesson (see `plan/series-outline.md`)
- If Post 1 explained specialists, Post 2 does NOT re-explain them — reference and move on
- If a section belongs in a different post, move it — don't duplicate
- Readers may read out of order, so brief context is fine, but full re-teaching is not

## Core Themes (Consistent Across All Posts)

1. **Context is limited** — this constraint drives every architectural decision
2. **LLMs are not deep domain experts** — research fills the knowledge gap
3. **Architecture decisions are the most expensive to reverse** — even more so with AI teams, because context contamination spreads decisions everywhere
4. **The human shapes the work** — through questions, constraints, directives, and vision

## What NOT to Write

- Don't claim "people told me this was overkill" — Wayne knew from prior Squad projects that research comes first
- Don't present AI as replacing the human — the thesis is AI makes humans MORE valuable
- Don't use generic AI hype language ("revolutionary", "game-changing", "the future of")
- Don't explain what Squad or Copilot is in every post — Post 1 covers that

## Structure Rules

- Posts are numbered 01-04 and live in `posts/`
- Filenames: `NN-slug.md` (e.g., `01-squad-specialists.md`)
- Each post starts with a title, subtitle, and "DRAFT" marker until Wayne approves
- Real prompt examples use blockquote format with context about when/why they were given

## Section Ownership

Avoid putting content in the wrong post:

| Topic | Belongs In |
|-------|-----------|
| Hiring specialists, training, departments | Post 1 |
| Research-first methodology, Frink's work, LLM knowledge depth | Post 2 |
| Context limits making architecture permanent, real prompt examples | Post 2 |
| Conway's Law, architecture mirroring team, doc reorganization | Post 3 |
| Doc structure as context optimization, splitting docs | Post 3 |
| Human as decision architect, fear of replacement, pivotal decisions | Post 4 |
| Ranking Wayne's most influential prompts | Post 4 |

## Editing Workflow

1. Agent writes/edits draft in `posts/`
2. Wayne reviews and gives feedback
3. Agent revises based on feedback
4. Wayne approves → agent publishes to blog repo with Jekyll frontmatter
