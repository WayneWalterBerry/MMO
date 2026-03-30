-- spider-web.lua — Creature-spawned environmental obstacle
-- Created by spider via creates_object behavior (WAVE-4)
-- Blocks NPC movement; player can walk through (sticky but passable)
-- No size system, no escape_difficulty, no trap state machine (v1.1 CBG simplification)
return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{bb5699b3-e027-4b43-b9cf-3acc183091b9}",
    template = "small-item",

    id = "spider-web",
    name = "a sticky spider web",
    keywords = {"web", "spider web", "cobweb", "silk"},
    description = "Glistening threads span the corner, sticky to the touch. The strands catch what little light there is, forming a lattice of pale silk anchored to the walls.",

    -- ═══════════════════════════════════════════════════════════
    -- PHYSICAL PROPERTIES
    -- ═══════════════════════════════════════════════════════════
    material = "silk",
    size = 2,
    weight = 0.1,
    portable = false,
    categories = {"obstacle", "silk", "creature-made"},

    location = nil,

    -- ═══════════════════════════════════════════════════════════
    -- SENSORY (on_feel REQUIRED — primary dark sense)
    -- ═══════════════════════════════════════════════════════════
    on_feel = "Tacky, clinging strands. They stick to your fingers and stretch when you pull away, leaving thin threads trailing from your hand.",
    on_smell = "Faintly musty. Old silk and dust.",
    on_listen = "Silent, but the strands hum faintly when disturbed.",
    on_taste = "Tasteless and sticky. The silk threads cling to your tongue.",
    room_presence = "A glistening spider web stretches across the corner.",

    -- ═══════════════════════════════════════════════════════════
    -- OBSTACLE MECHANIC
    -- ═══════════════════════════════════════════════════════════
    obstacle = {
        blocks_npc_movement = true,
        player_passable = true,
        message_blocked = "Something skitters into the web and struggles.",
        message_destroyed = "The web tears apart.",
    },

    -- Player interaction — passable but sticky
    passable = true,
    on_enter = "You brush through the sticky web. Threads cling to your clothes.",

    -- Creator tracking (set at runtime by create_object action)
    creator = nil,

    mutations = {},
}
