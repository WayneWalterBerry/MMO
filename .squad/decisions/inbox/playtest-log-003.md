### Play Test Log #3 — 2026-03-19
**By:** Wayne "Effe" Berry
**Build:** Post summary fix (commit 1f98cbe)

#### Transcript:
```
> feel around
  a large four-poster bed
  a small nightstand
  ...
> examine nightstand
It is too dark to see anything.
> feel the nightstand
Smooth wooden surface... A small drawer handle protrudes from the front.
> open drawer
It is too dark to see what you're doing.
```

#### Issues:
1. **OPEN blocked by darkness** — Player felt the drawer handle. They should be able to OPEN it by feel. Physical actions (OPEN, CLOSE, TAKE from felt containers) should work in the dark. You don't need eyes to pull a drawer.
2. **EXAMINE fails in dark, should fall back to FEEL** — EXAMINE in darkness should give on_feel description, not a dead end. "You can't see it, but you feel: {on_feel}"
3. **Parser strips "the" inconsistently** — "feel the nightstand" works, so the parser handles articles. Good.

#### Severity: HIGH — the puzzle is unsolvable. Player finds the drawer by feel but can't open it.
