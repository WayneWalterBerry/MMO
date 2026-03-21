# Puzzle Feedback — Pass 009
**From:** Nelson (Tester)
**To:** Sideshow Bob (Puzzle Designer)
**Date:** 2026-03-21
**Puzzle:** 001 — Light the Room

---

## Was Puzzle 001 fun?

**Yes, genuinely.** The progression from total darkness to lit room is one of the best "opening moves" I've tested. Waking blind and having to feel around creates real tension. The moment the candle lights and you see the room for the first time — that's a payoff. It works.

The sensory descriptions elevate it. Feeling "a smooth wax cylinder, slightly greasy" or "cold glass pane, thick and uneven" gives the darkness real texture. You're not just solving a puzzle — you're inhabiting a space.

## Were the clues sufficient?

**Yes.** The opening text says "Try 'feel' to explore the darkness" — that's enough to start. From there:
- `feel around` lists the nightstand → natural to investigate
- `feel nightstand` reveals the drawer handle → natural to open
- `open drawer` → `get matchbox` → `open matchbox` → `get match` → the chain is intuitive
- The candle is on the nightstand top — discoverable via feel

No player should get stuck here. The clues feel organic, not tutorial-ish. Good design.

## Did GOAP help or hurt?

**GOAP helps enormously on first light.** Typing `light candle` and having the engine auto-chain "strike match → light candle" is magic. It feels like the game understands intent.

**However, GOAP hurts on relight.** After the candle is extinguished, GOAP fails because it picks a spent match from the matchbox instead of a fresh one (BUG-035). This forces the player into a fiddly manual process: remove spent match from matchbox, drop it, get fresh match, etc. The elegance of the first GOAP experience makes the broken relight feel worse by comparison.

**Recommendation:** Fix the spent match selection bug. GOAP relight should work as smoothly as first light.

## "Aha!" moments

1. **The first `feel around`** — discovering you can navigate by touch. The game teaches its core mechanic through the opening puzzle.
2. **Pulling the rug and finding the key AND trap door** — two discoveries at once. The spatial puzzle (push bed → pull rug) is satisfying because it rewards physical reasoning.
3. **The candle burning down while you play** — creates real urgency. When it guttered out in the cellar, I felt genuine panic. Time pressure from a consumable light source is excellent game design.

## Additional Notes

- The match burning out instantly (same turn as striking) is fine for gameplay — it forces you to light something immediately. But it means you can NEVER just "hold a lit match" to see by. Consider whether a 1-turn window would add gameplay value.
- The "Your hands are full" message appearing mid-GOAP chain reads awkwardly. It's functionally correct but breaks immersion. Could GOAP suppress intermediate error messages?
- Material descriptions add great flavor. "A brass candle holder", "leaded glass window", "ceramic chamber pot" — these make the world feel real and physical.

## Fun Rating: 8/10

Loses points for the GOAP relight bug and the impossibility of using a match as a temporary light source. Otherwise excellent.
