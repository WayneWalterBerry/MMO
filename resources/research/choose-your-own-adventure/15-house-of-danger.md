# #15 — House of Danger

## Quick Reference

| Field | Details |
|-------|---------|
| **Title** | House of Danger |
| **Series Number** | #15 |
| **Author** | R.A. Montgomery |
| **Publication Year** | 1982 |
| **Publisher** | Bantam Books |
| **Pages** | 117 |
| **Endings** | ~20 |
| **Estimated Good / Bad / Neutral** | ~6 / ~10 / ~4 |

---

## Premise & Setting

You are a detective and psychic investigator who receives a cryptic, desperate phone call pleading for help. Using your psychic powers and detective skills, you trace the caller to the Marsden house — a creepy mansion built on the site of a former Civil War prison. Inside, you encounter vanishing people, mutant creatures, mind-bending technology, and mysteries that defy rational explanation.

The book is Montgomery at his most unrestrained: it blends mystery, paranormal activity, science fiction, and pulp adventure into a single chaotic narrative.

## Branching Structure

### Topology: Rapid Divergence with Genre-Shifting Branches

- **~20 endings** — moderate for the series
- **Extremely rapid branching** — nearly every choice leads to a completely distinct sub-plot
- **Genre shifts between branches** — one path is detective noir, another is sci-fi, another is horror
- **Minimal convergence** — once you branch, you're in a different genre
- **Psychic powers as choice modifier** — some paths are only available because of your abilities

### Genre-Shifting Structure

```
Mystery call → Marsden House → [Investigate upstairs → HORROR (ghosts, Civil War)]
                              → [Investigate basement → SCI-FI (lab, mutant chimps)]
                              → [Use psychic powers → PARANORMAL (telepathy, dimensions)]
                              → [Follow counterfeiting clue → DETECTIVE NOIR]
```

Each branch doesn't just change the story — it changes the *genre* of the story.

## Endings Breakdown

| Category | Count | Examples |
|----------|-------|---------|
| **Good** | ~6 | Rescue victims, defeat villains, gain super psychic powers |
| **Bad** | ~10 | Trapped in other dimensions, captured by antagonists, killed by mutant chimps |
| **Neutral/Strange** | ~4 | Transformed, abducted by aliens, displaced in time, bizarre metamorphosis |

Many endings are deliberately weird — Montgomery was less interested in resolution than in spectacle. Some endings feel like the beginning of a different book entirely.

## Notable Design Patterns

1. **Genre Mashup** — The book doesn't commit to one genre. It's simultaneously a mystery, horror story, sci-fi thriller, and paranormal investigation. Different paths emphasize different genres.

2. **Player Ability as Branching Mechanism** — Your psychic powers aren't just flavor; they open specific paths. This is an early example of ability-gated content.

3. **Antagonist Variety** — Different paths have completely different antagonists: ghosts, mad scientists, mutant chimps, counterfeiters, aliens. The Marsden house contains multitudes.

4. **Surreal Tone** — Montgomery embraces the absurd. Mutant psychic chimpanzees are presented with the same narrative seriousness as Civil War ghosts. This tonal flexibility is a Montgomery trademark.

5. **Location as Portal** — The Marsden house functions as a portal to different types of stories, similar to how Cave of Time's cave was a portal to different eras. The house is a narrative nexus.

## Innovation

- **Genre mashup as design strategy** — demonstrated that a single location could contain multiple genre experiences
- **Ability-gated content** — psychic powers opening specific paths; precursor to skill-based game design
- **Adapted to a Z-Man board game** (2018) — "House of Danger" became a successful tabletop game, proving the narrative structure could translate to other media
- **"Location as portal" evolution** — refined the concept from Cave of Time: instead of a cave leading to time periods, a house leads to genres
- **Tonal flexibility** — showed that CYOA books could be campy and strange without losing engagement

## Relevance to Our Project

### Applicable Patterns

| Pattern | Application |
|---------|-------------|
| **Genre-shifting branches** | Different areas of our game world could have different tonal flavors |
| **Ability-gated content** | Player abilities (gained through exploration) unlock new areas/interactions |
| **Location as portal** | A single hub location leading to fundamentally different experiences |
| **Antagonist variety** | Different threats in different areas keep exploration fresh |
| **Surreal tone tolerance** | Players accept tonal shifts if the underlying exploration loop is engaging |

### Lessons

- **Ability-gated content creates natural progression.** If exploring the darkness grants new abilities (better hearing, spatial sense, etc.), those abilities can unlock new interactions and areas. This mirrors Montgomery's psychic powers opening unique paths.
- **Genre flexibility within a unified space is powerful.** Our game world can shift from horror (the darkness) to wonder (discovery) to mystery (figuring out what happened) — all within the same physical space.
- **Campiness has its place.** Montgomery's willingness to be weird and fun (psychic chimps!) kept readers engaged. Our game doesn't need to be uniformly serious.
- **The board game adaptation proves interactive narrative design translates across media.** Our Lua engine could potentially support multiple front-ends.

---

*Part of the CYOA research collection for the MMO text adventure engine. See [00-series-overview.md](00-series-overview.md) for series context.*
