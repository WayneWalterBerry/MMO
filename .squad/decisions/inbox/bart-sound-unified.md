# Decision: D-SOUND-UNIFIED — Unified Sound Implementation Plan

**Date:** 2026-07-31
**Author:** Bart (Architecture Lead)
**Status:** 🟢 Active
**Category:** Architecture / Planning

## Summary

Consolidated three draft sound plan sections (Bart engine architecture, CBG game design, Gil web pipeline) into one unified 4-wave implementation plan at `plans/sound/sound-implementation-plan.md`.

## Key Decisions Consolidated

- **D-SOUND-1 through D-SOUND-18** captured in the plan's Design Decisions table
- **4-wave structure:** WAVE-0 (infrastructure), WAVE-1 (metadata + assets), WAVE-2 (engine hooks), WAVE-3 (deploy + docs)
- **24 MVP sounds** at ~230 KB total (OGG Opus 48 kbps mono)
- **3 iron laws** enforced: accessibility first, lazy loading, pre-compressed delivery
- **Deleted consolidated drafts:** `sound-design-notes.md`, `sound-web-pipeline-notes.md`

## Affects

- **Bart:** WAVE-0 engine module, WAVE-2 engine hooks
- **Gil:** WAVE-0 web bridge, WAVE-3 build pipeline
- **Flanders:** WAVE-1 object/creature `sounds` tables
- **Moe:** WAVE-1 room ambient declarations
- **CBG:** WAVE-1 design review
- **Smithers:** WAVE-2 narration integration
- **Nelson:** Tests across all waves
- **Brockman:** WAVE-3 documentation
