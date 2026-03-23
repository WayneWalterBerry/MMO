-- src/meta/injuries/minor-cut.lua
-- Injury template: Minor Cut
-- Pattern: One-time damage, self-heals naturally, bandage optional accelerator
-- FSM: active → healed  (natural path, 5 turns)
--      active → treated → healed  (bandaged path, 2 turns)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{fc7f4ea7-c569-4f6d-bc80-64f918ccfb42}",
    id = "minor-cut",
    name = "Minor Cut",
    category = "physical",
    description = "A small laceration that stings but heals on its own.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "one_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 3,
        damage_per_tick = 0,
        message = "A sharp sting — a thin line of blood appears on your hand.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Cut is fresh, stinging ──
        active = {
            name = "minor cut",
            description = "A small cut on your hand where the glass caught you. It stings, but the bleeding has mostly stopped on its own.",
            on_feel = "The skin around the cut is tender and slightly raised.",
            on_look = "A thin red line, barely bleeding. Nothing serious.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "healed" },
                -- 1800 seconds = 5 turns. Self-heals naturally.
            },
        },

        -- ── TREATED: Bandage applied, healing accelerated ──
        treated = {
            name = "bandaged cut",
            description = "The bandage on your hand is snug. The sting is fading.",
            on_feel = "Tight cloth covers the cut. Comforting pressure.",
            on_look = "A small bandage wrapped around your hand. Barely necessary.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 720, to_state = "healed" },
                -- 720 seconds = 2 turns. Bandage accelerates healing.
            },
        },

        -- ── HEALED: Terminal — injury removed ──
        healed = {
            name = "healed cut",
            description = "The cut on your hand has closed. Barely a mark remains.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies bandage ──
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "minor-cut",
            message = "You wrap the cloth snugly around the cut on your hand. The sting fades.",
        },

        -- ── Auto-transitions ──
        {
            from = "active", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The cut on your hand has closed on its own. Barely a mark remains.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The cut has fully healed beneath the bandage.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["bandage"] = {
            transitions_to = "treated",
            from_states = { "active" },
        },
        ["healing-poultice"] = {
            transitions_to = "treated",
            from_states = { "active" },
        },
    },
}
