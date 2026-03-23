-- concussion.lua — Injury template: Concussion (head trauma)
-- Pattern: One-time damage + causes unconsciousness (forced sleep state)
-- FSM: active → healed (auto-heals after wake + recovery period)
-- Triggered by: hit head (blunt force trauma to the head)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{b3e7a1c9-4d2f-48a6-9e5b-7c1d3f8a2b06}",
    id = "concussion",
    name = "Concussion",
    category = "unconsciousness",
    description = "Blunt-force trauma to the head causing loss of consciousness.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "one_time",
    initial_state = "active",
    causes_unconsciousness = true,

    -- Severity → unconscious turn count
    unconscious_duration = {
        minor    = 3,
        moderate = 5,
        severe   = 10,
        critical = 20,
    },

    on_inflict = {
        initial_damage = 5,
        damage_per_tick = 0,
        message = "Your head rings from the impact.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        active = {
            name = "concussed",
            description = "Your head is swimming. Stars dance at the edges of your vision.",
            on_feel = "A throbbing lump, hot and tender to the touch.",
            on_look = "A dark bruise forming on the side of your head.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 5400, to_state = "healed" },
                -- 5400 seconds = 15 turns. Concussion heals on its own.
            },
        },

        healed = {
            name = "recovered",
            description = "The headache has finally faded. Your vision is clear.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        {
            from = "active", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The throbbing in your head finally fades. Your vision clears.",
        },
    },

    healing_interactions = {},
}
