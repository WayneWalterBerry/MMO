-- src/meta/injuries/stress.lua
-- Injury template: Acute Stress (psychological)
-- Pattern: Threshold-based accumulation from trauma triggers, rest-cured
-- Levels: mild → moderate → severe

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{18c87fad-5f27-435f-9802-b914e238207f}",
    id = "stress",
    name = "Acute Stress",
    category = "mental",
    description = "Psychological trauma from combat exposure. Accumulates through witnessed violence and near-death experiences.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL (for FSM lint validation)
    -- ═══════════════════════════════════════════════════════════
    damage_type = "mental",
    initial_state = "mild",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "You feel a wave of anxiety wash over you.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES (for lint validation INJ-20)
    -- ═══════════════════════════════════════════════════════════
    states = {
        mild = {
            name = "mild stress",
            description = "Your hands tremble slightly. A sense of unease settles over you.",
            on_feel = "Your heart races slightly. Muscles tense.",
            on_look = "Your hands are steady, but you feel tense.",
            damage_per_tick = 0,
        },
        moderate = {
            name = "moderate stress",
            description = "You're breathing hard, heart pounding. Everything feels wrong.",
            on_feel = "Your hands shake. Cold sweat beads on your forehead.",
            on_look = "You look visibly shaken. Sweat glistens on your brow.",
            damage_per_tick = 0,
        },
        severe = {
            name = "severe panic",
            description = "Panic grips you. Your vision tunnels. Everything feels wrong.",
            on_feel = "Your entire body shakes. Every muscle is locked in tension.",
            on_look = "You're visibly trembling, eyes wide, barely holding it together.",
            damage_per_tick = 0,
        },
        breakdown = {
            name = "nervous breakdown",
            description = "You collapse under the weight of terror. Everything is too much.",
            terminal = true,
        },
        recovered = {
            name = "calm",
            description = "You've regained your composure. The panic has passed.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS (for lint validation INJ-58)
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["safe-room"] = {
            transitions_to = "recovered",
            from_states = { "mild", "moderate", "severe" },
        },
        ["meditation"] = {
            transitions_to = "mild",
            from_states = { "moderate", "severe" },
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- LEGACY STRESS API STRUCTURE
    -- Used by engine.injuries.add_stress() and engine.injuries.cure_stress()
    -- This part is NOT an FSM — it's the accumulated-points system.
    -- ═══════════════════════════════════════════════════════════

    -- Severity levels: threshold-based point accumulation.
    -- v1.1: thresholds raised per CBG review — single kill must NOT cripple player.
    levels = {
        { name = "shaken", threshold = 3, description = "Your hands tremble slightly." },
        { name = "distressed", threshold = 6, description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 10, description = "Panic grips you. Everything feels wrong." },
    },

    -- Debuffs applied at each severity level.
    -- v1.1: overwhelmed debuffs reduced — hindrance, not wall.
    effects = {
        shaken = { attack_penalty = -1 },
        distressed = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -2, flee_bias = 0.3, movement_penalty = 0.2 },
    },

    -- Cure method: rest-based recovery requiring safe room.
    -- Requires safety (no creatures in room).
    cure = {
        method = "rest",
        duration = "2 hours",
        requires = { safe_room = true },
        description = "With time and safety, the panic subsides.",
    },

    -- Trauma triggers: sources that accumulate stress points.
    -- v1.1: player_first_kill removed — victory rewards, not punishes.
    -- Stress accumulates gradually through repeated exposure.
    triggers = {
        witness_creature_death = 1,
        near_death_combat = 2,
        witness_gore = 1,
    },
}
