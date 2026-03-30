-- src/meta/worlds/manor/injuries/food-poisoning.lua
-- Injury template: Food Poisoning
-- Pattern: Onset cramps → nausea with DOT → recovery → cleared
-- FSM: onset → nausea → recovery → cleared
-- Moderate severity, 20-tick total duration
-- Caused by: eating spoiled food, bat meat (10% risk even cooked)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{103e07e1-0610-474a-b63d-29f7d660a2a8}",
    id = "food-poisoning",
    name = "Food Poisoning",
    category = "disease",
    severity = "moderate",
    description = "Gastrointestinal distress from tainted food. Nausea, cramping, and weakness that must run its course.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "onset",

    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "Your stomach lurches. Something you ate is fighting back.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES (20 ticks total: 3 onset + 12 nausea + 5 recovery)
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ONSET: Initial cramps, warning signs ──
        onset = {
            name = "stomach cramps",
            description = "Your stomach twists and cramps. Cold sweat prickles your forehead. Something you ate was bad.",
            on_feel = "Your abdomen is tight and tender. Cold sweat on your brow. Each breath brings a fresh wave of nausea.",

            damage_per_tick = 0,

            restricts = {
                eat = true,
            },

            timed_events = {
                { event = "transition", delay = 1080, to_state = "nausea" },
                -- 1080 seconds = 3 ticks. Cramps escalate to full nausea.
            },
        },

        -- ── NAUSEA: Active illness, DOT, reduced effectiveness ──
        nausea = {
            name = "severe nausea",
            description = "Waves of nausea roll through you. Your hands shake. Everything you do takes twice the effort.",
            on_feel = "Your gut heaves with each movement. Your hands tremble. Standing upright is an act of will.",

            damage_per_tick = 1,

            restricts = {
                eat = true,
                precise_actions = true,
            },

            timed_events = {
                { event = "transition", delay = 4320, to_state = "recovery" },
                -- 4320 seconds = 12 ticks. The worst of it.
            },
        },

        -- ── RECOVERY: Subsiding, no more DOT ──
        recovery = {
            name = "recovering from food poisoning",
            description = "The nausea fades to a dull ache. Your strength is returning, slowly. The worst has passed.",
            on_feel = "Your stomach is sore but settling. The trembling has stopped. You feel wrung out.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "cleared" },
                -- 1800 seconds = 5 ticks. Full recovery.
            },
        },

        -- ── CLEARED: Terminal — illness resolved ──
        cleared = {
            name = "recovered from food poisoning",
            description = "The food poisoning has run its course. Your stomach is tender, but the nausea is gone.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Auto-transitions: Disease progression ──
        {
            from = "onset", to = "nausea",
            trigger = "auto",
            condition = "timer_expired",
            message = "The cramps worsen. A wave of nausea doubles you over. This is going to be rough.",
            mutate = { damage_per_tick = 1 },
        },
        {
            from = "nausea", to = "recovery",
            trigger = "auto",
            condition = "timer_expired",
            message = "The nausea begins to ebb. Your stomach unclenches. The worst has passed.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "recovery", to = "cleared",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your strength returns. The food poisoning has finally cleared. You won't eat that again.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Food poisoning has no cure — it must run its course.
    -- Future WAVE-4 antidote-vial may add an entry here.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {},
}
