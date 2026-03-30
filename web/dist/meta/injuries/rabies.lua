-- src/meta/worlds/manor/injuries/rabies.lua
-- Injury template: Rabies
-- Pattern: Silent incubation → escalating neurological damage → fatal
-- FSM: incubating → prodromal → furious → fatal  (untreated)
--      incubating → healed  (early cure)
--      prodromal → healed  (late cure, still possible)
--      furious → fatal  (too late for cure)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{d41aae12-a8b8-481b-a8e7-6c3902130172}",
    id = "rabies",
    name = "Rabies",
    category = "disease",
    description = "A viral disease transmitted through animal bites. Silent incubation gives way to madness and death.",

    -- ═══════════════════════════════════════════════════════════
    -- DISEASE-SPECIFIC FIELDS
    -- ═══════════════════════════════════════════════════════════
    hidden_until_state = "prodromal",
    curable_in = { "incubating", "prodromal" },
    transmission = { probability = 0.08, via = "bite" },

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "incubating",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "The bite wound throbs once, then fades. You think nothing of it.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── INCUBATING: Virus spreading silently, no symptoms ──
        incubating = {
            name = "incubating rabies",
            description = "You feel fine. The bite wound has scabbed over.",
            on_feel = "The bite wound is scabbed and slightly warm. Nothing alarming.",
            on_look = "A small scab where you were bitten. Already healing.",
            on_smell = "Nothing unusual.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 5400, to_state = "prodromal" },
                -- 5400 seconds = 15 ticks. Silent incubation period.
            },
        },

        -- ── PRODROMAL: First symptoms appear, cure still possible ──
        prodromal = {
            name = "early rabies",
            description = "A tingling itch radiates from the old bite wound. Your head aches. Something is wrong.",
            on_feel = "The bite wound itches unbearably. Your skin prickles with phantom sensations.",
            on_look = "The bite wound is inflamed again. Your hands tremble slightly.",
            on_smell = "Everything smells too sharp, too vivid.",

            damage_per_tick = 1,

            restricts = {
                precise_actions = true,
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "furious" },
                -- 3600 seconds = 10 ticks. Window for treatment closing.
            },
        },

        -- ── FURIOUS: Hydrophobia, aggression, no cure possible ──
        furious = {
            name = "furious rabies",
            description = "Your throat constricts at the thought of water. Rage flickers behind your eyes. The virus owns you now.",
            on_feel = "Your muscles spasm. Your jaw clenches involuntarily. Swallowing is agony.",
            on_look = "Your eyes are wild. Saliva drips from your chin. You can't hold still.",
            on_smell = "Your own sweat reeks of something animal and feral.",

            damage_per_tick = 3,

            restricts = {
                drink = true,
                precise_actions = true,
            },

            timed_events = {
                { event = "transition", delay = 2880, to_state = "fatal" },
                -- 2880 seconds = 8 ticks. Terminal decline.
            },
        },

        -- ── FATAL: Terminal — rabies kills ──
        fatal = {
            name = "terminal rabies",
            description = "Your body seizes. The virus has reached every nerve. The rage fades to nothing.",
            terminal = true,
            death_message = "The rabies has run its course. Your body convulses one final time, then is still.",
        },

        -- ── HEALED: Terminal — virus eliminated by early treatment ──
        healed = {
            name = "cured of rabies",
            description = "The treatment worked. The fever breaks. The bite wound is just a scar now.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies cure during incubation ──
        {
            from = "incubating", to = "healed",
            verb = "use",
            requires_item_cures = "rabies",
            message = "You apply the poultice to the bite wound. The warmth fades. You caught it in time.",
            mutate = { damage_per_tick = 0 },
        },
        -- ── Verb-triggered: Player applies cure during prodromal phase ──
        {
            from = "prodromal", to = "healed",
            verb = "use",
            requires_item_cures = "rabies",
            message = "You force the bitter remedy down. The itching subsides. The trembling stops. Just in time.",
            mutate = { damage_per_tick = 0 },
        },

        -- ── Auto-transitions: Disease escalation ──
        {
            from = "incubating", to = "prodromal",
            trigger = "auto",
            condition = "timer_expired",
            message = "The old bite wound begins to itch. A dull headache settles behind your eyes. Something is wrong.",
            mutate = { damage_per_tick = 1 },
        },
        {
            from = "prodromal", to = "furious",
            trigger = "auto",
            condition = "timer_expired",
            message = "Rage surges through you without reason. Your throat seizes at the sight of water. The madness has taken hold.",
            mutate = { damage_per_tick = 3 },
        },
        {
            from = "furious", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your body convulses. The rage drains away, replaced by nothing. The virus has won.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Only treatable during incubating and prodromal phases.
    -- Once furious stage begins, no cure exists.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "incubating", "prodromal" },
            success_message = "The poultice draws the infection. You feel the fever receding.",
            fail_message = "The disease has progressed too far. The poultice has no effect.",
        },
    },
}
