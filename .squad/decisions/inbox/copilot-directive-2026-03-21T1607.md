### 2026-03-21T16:07: User directive — JIT Loader Architecture
**By:** Wayne Berry (via Copilot)
**What:** The web engine must use a just-in-time loader for meta files (objects, rooms, levels, templates). Each meta .lua file should be served individually as a static file on GitHub Pages — NOT bundled into one monolithic JS file. The engine should have a separate loader component that fetches resources by GUID as needed. Rooms and levels should get GUID identifiers (objects already have them). Files are too small individually to benefit from compression — serve them raw. This is critical for scalability as the game grows.
**Why:** User architecture decision — monolithic 16MB bundles don't scale, JIT loading does.
