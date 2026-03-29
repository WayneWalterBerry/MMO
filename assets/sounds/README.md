# Sound Assets

Sound files for the MMO text adventure engine.

## Format

- **Codec:** OGG Opus
- **Bitrate:** 48 kbps mono
- **Extension:** `.opus`
- **Max size:** 100 KB per file

## Directory Structure

```
assets/sounds/
├── ambient/    — Room ambient loops (continuous background)
├── combat/     — Combat impact sounds (hits, blocks, misses)
├── creatures/  — Creature vocalizations (squeaks, growls, hisses)
└── objects/    — Object interaction sounds (doors, locks, glass breaking)
```

## Naming Convention

Use kebab-case matching the object or action:

```
rat-squeak.opus
door-creak.opus
glass-shatter.opus
cave-drip-ambient.opus
```

## Build Pipeline

During web build (`web/build-meta.ps1`), sound files are copied to
`web/dist/sounds/{category}/` and deployed to GitHub Pages automatically.

Cache-busting uses the existing `CACHE_BUST` query parameter in bootstrapper.js.

## Adding New Sounds

1. Place the `.opus` file in the appropriate category directory
2. Run `web/build-meta.ps1` — sounds are discovered automatically
3. Reference in object metadata via `sound = { on_look = "objects/door-creak" }`

No build script changes needed — the pipeline auto-discovers all `.opus` files.
