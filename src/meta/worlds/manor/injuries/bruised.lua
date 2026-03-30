-- src/meta/worlds/manor/injuries/bruised.lua
-- Injury template: Bruise
-- Pattern: One-time blunt damage, self-heals naturally, rest accelerates
-- FSM: active → healed  (natural path, 8 turns)
--      active → recovering → healed  (rest path, 4 turns)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{4deab41d-f062-4f05-89fd-8fc2cbc2d073}",
    id = "bruised",
    name = "Bruise",
    category = "physical",
    description = "Blunt-force trauma that heals naturally with time and rest.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "one_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 4,
        damage_per_tick = 0,
        message = "A heavy impact. Pain blooms deep in the muscle.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Bruise is fresh, movement impaired ──
        active = {
            name = "bruised",
            description = "Badly bruised from the impact. Every movement sends a jolt of pain. This will heal with rest — time and staying off your feet.",
            on_feel = "Swollen, tender flesh. Hot to the touch.",
            on_look = "Dark purple discoloration spreading under the skin.",

            damage_per_tick = 0,

            restricts = {
                climb = true,
                run = true,
                jump = true,
            },

            timed_events = {
                { event = "transition", delay = 2880, to_state = "healed" },
                -- 2880 seconds = 8 turns. Self-heals naturally.
            },
        },

        -- ── RECOVERING: Rest accelerated healing, impairment fading ──
        recovering = {
            name = "recovering bruise",
            description = "The bruising is fading. Movement still protests, but you can manage.",
            on_feel = "Tenderness remains, but the sharp pain has dulled.",
            on_look = "Yellowish-green bruising. Healing visibly.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 1440, to_state = "healed" },
                -- 1440 seconds = 4 turns to fully heal after rest.
            },
        },

        -- ── HEALED: Terminal — injury removed ──
        healed = {
            name = "healed bruise",
            description = "The soreness has finally passed. Full strength has returned.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player rests to accelerate healing ──
        {
            from = "active", to = "recovering",
            verb = "rest",
            message = "You sit down and take the weight off your bruised limbs. The throbbing eases slightly.",
        },
        {
            from = "active", to = "recovering",
            verb = "sleep",
            message = "You lie down and let your body recover. The deep ache begins to fade as you rest.",
        },

        -- ── Auto-transitions ──
        {
            from = "active", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The bruising has healed on its own. The soreness is gone.",
        },
        {
            from = "recovering", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The bruise has fully healed. Full strength has returned.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Bruises require no items. Rest and time are the only treatments.
    -- The verb transitions (rest, sleep) handle the accelerated path.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {},
}
