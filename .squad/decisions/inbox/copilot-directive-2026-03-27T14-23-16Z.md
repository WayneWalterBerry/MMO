### 2026-03-27T14:23:16Z: User directives — Sound Implementation
**By:** Wayne "Effe" Berry (via Copilot)
**What:**
1. Accessibility: ALWAYS present both text AND sound together. Sound is enhancement, never replacement. Text remains the primary channel.
2. Lazy loading: Sounds must load via the lazy load system — only load sounds when the associated object/creature/room loads. Don't preload the entire sound library.
3. Compression: Use pre-compressed sound files uploaded to the web site. Decompress on the client when they come down.
**Why:** User requirements for sound implementation plan — captured for team memory
