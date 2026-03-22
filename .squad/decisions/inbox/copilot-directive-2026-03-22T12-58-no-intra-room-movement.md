### 2026-03-22T12:58: User directive — No intra-room movement
**By:** Wayne (Effe) Berry (via Copilot)
**What:** Players cannot move around WITHIN a room. Following classic IF convention (Zork, Infocom), the player is simply "in the room." Everything in the room is reachable from one position. Movement only happens between rooms via exits.

Implication for search: "proximity ordering" is NARRATIVE ordering (what the player would logically encounter first), not physical distance. The bed comes first because the player woke up in it. The nightstand is next because it's beside the bed. This is authored order in room metadata, not calculated distance.
**Why:** Classic IF convention — rooms are atomic locations, not spaces with sub-positions
