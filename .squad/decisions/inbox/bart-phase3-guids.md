# Phase 3 GUID Pre-Assignment — Bart (Architect)

**Date:** 2026-08
**Context:** Phase 3 WAVE-0 pre-flight — reserve GUIDs for all Phase 3 objects before parallel authoring begins.

## Reserved GUIDs

| Object ID | GUID | Target Wave |
|-----------|------|-------------|
| cooked-rat-meat | 971e819c-8ad2-4f6e-934c-48236d7c5660 | WAVE-3 |
| cooked-cat-meat | 91d7e699-edd7-4fd5-9fcd-7a9df9871571 | WAVE-3 |
| cooked-bat-meat | 59f5622f-c3aa-4471-8137-b04f20a9c46d | WAVE-3 |
| grain-handful | 3717e78a-d653-48fe-a12e-8440aae8efaa | WAVE-3 |
| flatbread | b20bf751-88f9-44c2-97bf-e2d73cb3aa94 | WAVE-3 |
| food-poisoning (injury) | 103e07e1-0610-474a-b63d-29f7d660a2a8 | WAVE-4 |
| antidote-vial | 87ec6b50-d0eb-4a1c-ae34-8b200625ccd0 | WAVE-4 |
| meat (material) | 94d05bd1-8393-4a54-a21f-7eae6ed503d9 | WAVE-3 |
| silk-bundle | 203f252d-61f6-4533-a379-f5ecb3880de4 | WAVE-3 |
| cellar-brazier | 22b77e90-8407-427a-a272-6b88277ba1fc | WAVE-3 |
| gnawed-bone | b8db1d83-9c05-401c-ae7b-67c31b98d6fc | WAVE-2 |

## Notes

- 11 GUIDs total (5 fewer than v1.2 — dead-creature GUIDs eliminated per D-14 reshape pattern)
- Stress injury GUID deferred to Phase 4 (Q5 decision)
- All GUIDs generated via `[guid]::NewGuid().ToString()` on Windows
- Flanders and Moe: use these GUIDs exactly when authoring object/room definitions
