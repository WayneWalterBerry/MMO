# #7 — Deadwood City

## Quick Reference

| Field | Details |
|-------|---------|
| **Title** | Deadwood City |
| **Series Number** | #7 (sometimes listed as #8 in variant editions) |
| **Author** | Edward Packard |
| **Publication Year** | 1978 (one of the earliest written; published in series 1980) |
| **Publisher** | Bantam Books |
| **Pages** | 115 |
| **Endings** | 37 |
| **Unique Paths** | ~156 |
| **Estimated Good / Bad / Neutral** | ~12 / ~15 / ~10 |

---

## Premise & Setting

You are a lone traveler riding into the rough frontier town of Deadwood City, seeking fortune and adventure in the Old West. You encounter outlaws (led by the infamous Kurt Malloy and his gang), lawmen, ranch hands, and townsfolk. Your choices determine whether you become a hero, an outlaw, a settler, or a cautious bystander.

The setting is classic American Western: saloons, stagecoaches, gold mines, cattle ranches, and the ever-present tension between law and lawlessness.

## Branching Structure

### Topology: Wide Branching with Role-Based Tracks

- **37 endings** across **~156 unique story paths**
- **Role-based branching** — early choices determine your social role (lawman, outlaw, ranch hand, etc.)
- **Moderate convergence** — some paths share encounters in town locations
- **Non-violent resolution bias** — surprisingly few gunfight endings for a Western

### Structural Innovation: Role Selection

The book's early choices function as **role selection**: Will you side with the law? Join the outlaws? Try to stay neutral? This creates several parallel narrative tracks, each with its own cast of characters and types of challenges.

```
Arrive in Deadwood → [Accept sheriff's offer → Lawman track]
                   → [Join Malloy's gang → Outlaw track]
                   → [Find ranch work → Settler track]
                   → [Leave town → Withdrawal endings]
```

## Endings Breakdown

| Category | Count | Examples |
|----------|-------|---------|
| **Good** | ~12 | Capture outlaws, become town hero, strike gold, establish peaceful life |
| **Bad** | ~15 | Outwitted by criminals, captured, lost in wilderness, failed ambitions |
| **Neutral** | ~10 | Leave town, change careers, survive but unremarkable, new beginnings |

Notably for a Western, **most endings avoid explicit violence.** The book steers away from gunfight deaths, preferring consequences like imprisonment, failure, or quiet departure. The high number of neutral endings reflects the Western genre's theme of "moving on."

## Notable Design Patterns

1. **Role-Based Branching** — Your social role (lawman, outlaw, worker) determines which NPCs you interact with and what challenges you face. This is an early form of class-based game design.

2. **Genre-Appropriate Consequence Tone** — The Western setting uses Western consequences: losing your horse, getting cheated at cards, being run out of town. Death is rare; humiliation and displacement are common.

3. **Many Neutral Endings** — The book acknowledges that "just leaving" is a valid choice. Not every story needs a dramatic conclusion. This reflects the transient nature of frontier life.

4. **NPC Faction System** — Characters align with different factions (law, outlaws, settlers, merchants). Your faction alignment affects available choices and endings.

5. **Moral Ambiguity** — Packard's signature: the outlaws aren't pure evil, the lawmen aren't pure good. Joining Malloy's gang can lead to success; working with the sheriff can lead to failure.

## Innovation

- **First CYOA Western genre entry** — proved the format worked for historical/genre fiction
- **Role-based branching** — player identity determined by early choices, not preset
- **High neutral-ending ratio** — validated that "walking away" is a legitimate story outcome
- **Non-violent Western** — subverted genre expectations by minimizing gunfight deaths
- **156 unique paths** — among the highest path counts in the early series

## Relevance to Our Project

### Applicable Patterns

| Pattern | Application |
|---------|-------------|
| **Role-based branching** | Player's early actions could establish their "role" in the game world |
| **Faction alignment** | NPCs respond differently based on player's demonstrated allegiances |
| **Neutral endings as valid outcomes** | Not every game state needs to be win/lose — "moving on" can be meaningful |
| **Genre-appropriate consequences** | Consequences should match the world's tone, not default to death |
| **Moral ambiguity** | No clear good/evil divide makes choices more interesting |

### Lessons

- **Role emergence through action is more engaging than role selection.** Instead of "choose your class," let players' actions determine how the world sees them. Our game can track behavior patterns and adjust NPC reactions accordingly.
- **Death shouldn't be the default failure state.** Deadwood City shows that displacement, humiliation, and lost opportunity can be just as dramatic. Our game can have failure states that are interesting rather than punitive.
- **High path counts require efficient content.** 156 paths in 115 pages means heavy content reuse through shared nodes and brief encounters. Our engine should support modular content that can be remixed across paths.

---

*Part of the CYOA research collection for the MMO text adventure engine. See [00-series-overview.md](00-series-overview.md) for series context.*
