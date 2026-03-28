-- src/meta/injuries/stress.lua
-- Injury template: Acute Stress (psychological)
-- Pattern: Threshold-based accumulation from trauma triggers, rest-cured
-- Levels: shaken (3) → distressed (6) → overwhelmed (10)
-- Cure: rest in safe room (no creatures), 2 hours game time

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{18c87fad-5f27-435f-9802-b914e238207f}",
    id = "stress",
    name = "acute stress",
    category = "psychological",
    description = "Psychological trauma from combat exposure. Accumulates through witnessed violence and near-death experiences.",

    -- ═══════════════════════════════════════════════════════════
    -- SEVERITY LEVELS
    -- Threshold-based: stress points accumulate from triggers.
    -- v1.1: thresholds raised per CBG review — single kill must NOT cripple player.
    -- ═══════════════════════════════════════════════════════════
    levels = {
        { name = "shaken", threshold = 3, description = "Your hands tremble slightly." },
        { name = "distressed", threshold = 6, description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 10, description = "Panic grips you. Everything feels wrong." },
    },

    -- ═══════════════════════════════════════════════════════════
    -- EFFECTS
    -- Debuffs applied at each severity level.
    -- v1.1: overwhelmed debuffs reduced — hindrance, not wall.
    -- ═══════════════════════════════════════════════════════════
    effects = {
        shaken = { attack_penalty = -1 },
        distressed = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -2, flee_bias = 0.3, movement_penalty = 0.2 },
    },

    -- ═══════════════════════════════════════════════════════════
    -- CURE
    -- Rest-based recovery. Requires safety (no creatures in room).
    -- ═══════════════════════════════════════════════════════════
    cure = {
        method = "rest",
        duration = "2 hours",
        requires = { safe_room = true },
        description = "With time and safety, the panic subsides.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- TRAUMA TRIGGERS
    -- Sources that accumulate stress points.
    -- v1.1: player_first_kill removed — victory rewards, not punishes.
    -- Stress accumulates gradually through repeated exposure.
    -- ═══════════════════════════════════════════════════════════
    triggers = {
        witness_creature_death = 1,
        near_death_combat = 2,
        witness_gore = 1,
    },
}
