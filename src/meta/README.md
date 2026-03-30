# src/meta/ — Game Content Root

This directory holds all game metadata: world content, shared templates, and shared materials.

## Structure

```
meta/
├── templates/      ← Shared base templates (room, furniture, container, small-item, etc.)
├── materials/      ← Shared material properties (stone, iron, wood, etc.)
└── worlds/         ← World-specific content (one subfolder per world)
    ├── manor/      ← The Manor — Level 1 world (gothic horror)
    └── wyatt-world/← Wyatt's World — kid-friendly world (future)
```

## Conventions

- **Templates** are shared across all worlds — they define the structural shape of objects.
- **Materials** are shared physics properties — stone is stone in every world.
- **World content** (objects, rooms, creatures, levels, injuries) is isolated per world subfolder.
- Each world has a `world.lua` definition with `content_root`, `rating`, and theme metadata.
- The engine loader reads `content_root` from the world definition to find content files.

## Adding a New World

See `worlds/README.md` for instructions.
