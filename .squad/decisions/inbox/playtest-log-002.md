### Play Test Log #2 — 2026-03-19
**By:** Wayne "Effe" Berry
**Build:** Post compound-tools (commit 50c9021)

#### Transcript:
```
> grope around what is around me
You can't feel anything like that nearby.

> feel around
You can't feel anything like that nearby.

> what is around me?
It is too dark to see. You need a light source.
(Try 'feel' to grope around in the darkness.)
```

#### Issues:
1. **"feel around" doesn't work** — "around" is parsed as noun, handler looks for object called "around" and fails. FEEL with no noun or "around" should trigger room-sweep (list reachable objects by touch).
2. **"grope around" same problem** — alias of feel, same bug.
3. **Multi-word natural language still fails** — "what is around me" parsed as verb="what". Need either better parsing or friendlier error pointing to FEEL.

#### Fix needed: FEEL with no noun, "around", or "room" should trigger the ambient feel-around behavior.
