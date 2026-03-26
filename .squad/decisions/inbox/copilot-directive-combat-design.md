### 2026-03-26T00:18Z: Combat system design directives
**By:** Wayne Berry (via Copilot)

**D-COMBAT-1: DF-inspired, simplified body zones**
4-6 body zones (head, torso, arms, legs, maybe hands/feet), NOT Dwarf Fortress's 200-part system. Enough granularity for tactical choice without overwhelming the player.

**D-COMBAT-2: MTG combat steps as embedded metadata, not player-driven**
The MTG combat phase structure (declare attackers → declare blockers → damage) is elegant, but the PLAYER should not manually play these steps. Instead, embed the combat phase logic into object/creature metadata — possibly as FSM states or a combat-phase pipeline. The engine runs the phases automatically based on declared actions.

**D-COMBAT-3: Body zones = armor slots**
The body zones that can be attacked MUST align with the locations where armor can be equipped. If you can wear a helmet (head), you can be hit in the head. If you can wear a breastplate (torso), you can be hit in the torso. One system, not two.

**D-COMBAT-4: Every creature has a body tree in its .lua file**
Every creature's .lua definition must include a `body_tree` field describing its body structure — which zones it has, what's connected to what. A rat has: head, torso, legs, tail. A human has: head, torso, arms, legs. This is pure metadata (Principle 8).

**D-COMBAT-5: Update NPC plan with body tree requirement**
The NPC system plan (`plans/npc-system-plan.md`) needs to be updated to include the body_tree requirement for all creatures. This affects the creature template and the rat's Phase 1 definition.

**Why:** User design vision — combat system must be elegant, metadata-driven, and align with existing armor/equipment system.