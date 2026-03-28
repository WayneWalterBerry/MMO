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
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "mental",
    initial_state = "mild",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "You feel a wave of anxiety wash over you.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── MILD: First stage of stress ──
        mild = {
            name = "mild stress",
            description = "Your hands tremble slightly. A sense of unease settles over you.",
            on_feel = "Your heart races slightly. Muscles tense.",
            on_look = "Your hands are steady, but you feel tense.",
            on_smell = "You can smell your own sweat — acrid, nervous sweat.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 7200, to_state = "recovered" },
            },
        },

        -- ── MODERATE: Increased stress response ──
        moderate = {
            name = "moderate stress",
            description = "You're breathing hard, heart pounding. Everything feels wrong.",
            on_feel = "Your hands shake. Cold sweat beads on your forehead.",
            on_look = "You look visibly shaken. Sweat glistens on your brow.",
            on_smell = "The sharp tang of fear-sweat fills your nostrils.",

            damage_per_tick = 0,

            restricts = {
                focus = true,
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "severe" },
            },
        },

        -- ── SEVERE: Panic and debilitation ──
        severe = {
            name = "severe panic",
            description = "Panic grips you. Your vision tunnels. Everything feels wrong.",
            on_feel = "Your entire body shakes. Every muscle is locked in tension.",
            on_look = "You're visibly trembling, eyes wide, barely holding it together.",
            on_smell = "The sickly-sweet stench of terror-sweat.",

            damage_per_tick = 0,

            restricts = {
                focus = true,
                fight = true,
            },

            timed_events = {
                { event = "transition", delay = 1800, to_state = "breakdown" },
            },
        },

        -- ── BREAKDOWN: Terminal state ──
        breakdown = {
            name = "nervous breakdown",
            description = "You collapse under the weight of terror. Everything is too much.",
            terminal = true,
        },

        -- ── RECOVERED: Terminal — stress removed ──
        recovered = {
            name = "calm",
            description = "You've regained your composure. The panic has passed.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Rest in safe room to recover ──
        {
            from = "mild", to = "recovered",
            verb = "rest",
            condition = "in_safe_room",
            message = "In the quiet safety, your anxiety gradually subsides.",
        },
        {
            from = "moderate", to = "mild",
            verb = "rest",
            condition = "in_safe_room",
            message = "The tension begins to ease as you rest in this safe place.",
        },
        {
            from = "severe", to = "moderate",
            verb = "rest",
            condition = "in_safe_room",
            message = "Slowly, your racing heartbeat begins to slow.",
        },

        -- ── Auto-transitions: Time-based worsening if untreated ──
        {
            from = "mild", to = "moderate",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your anxiety intensifies. You're breathing too fast.",
        },
        {
            from = "moderate", to = "severe",
            trigger = "auto",
            condition = "timer_expired",
            message = "Panic surges through you. You can barely think straight.",
        },
        {
            from = "severe", to = "breakdown",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your mind shuts down. Everything goes grey.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
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
}
