-- src/meta/injuries/bleeding.lua
-- Injury template: Bleeding Wound
-- Pattern: Over-time damage with degenerative worsening if untreated
-- FSM: active → treated → healed  (happy path)
--      active → worsened → critical → fatal  (untreated path)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{f6c20c23-a8e3-402e-afc7-1f0857481b4c}",
    id = "bleeding",
    name = "Bleeding Wound",
    category = "physical",
    description = "An open wound that bleeds continuously.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 5,
        damage_per_tick = 5,
        message = "Blood wells from the wound.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Injury is untreated, draining health each turn ──
        active = {
            name = "bleeding",
            description = "A deep gash. Blood flows freely — a slow but steady stream that won't stop on its own.",
            on_feel = "The wound is wet and warm. Blood pulses with your heartbeat.",
            on_look = "A deep gash, still bleeding freely. Your sleeve is soaked crimson.",
            on_smell = "The metallic tang of blood.",

            damage_per_tick = 5,

            restricts = {
                climb = true,
            },

            timed_events = {
                { event = "transition", delay = 5400, to_state = "worsened" },
                -- 5400 seconds = 15 turns. Untreated bleeding worsens to infection.
            },
        },

        -- ── TREATED: Bandage applied, drain stopped, wound healing ──
        treated = {
            name = "bandaged wound",
            description = "The bandage around your arm is holding. The bleeding has stopped, but the wound beneath is serious.",
            on_feel = "Tight bandages cover the wound. It aches deeply.",
            on_look = "A bandaged gash. No longer bleeding.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 3600, to_state = "healed" },
                -- 3600 seconds = 10 turns to fully heal.
            },
        },

        -- ── WORSENED: Untreated too long, infection sets in ──
        worsened = {
            name = "infected wound",
            description = "The untreated wound festers. You feel feverish.",
            on_feel = "Hot, swollen. The skin around the wound is inflamed.",
            on_look = "The wound is red and swollen, oozing pus.",
            on_smell = "A sour, rotten smell rises from the wound. Infection.",

            damage_per_tick = 10,

            restricts = {
                climb = true,
                run = true,
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "critical" },
                -- 3600 seconds = 10 turns in worsened before critical.
            },
        },

        -- ── CRITICAL: Life-threatening, last chance for treatment ──
        critical = {
            name = "septic wound",
            description = "Sepsis. Your vision blurs. You can barely stand.",
            on_feel = "Burning fever. The wound is black at the edges.",
            on_look = "The wound is blackening at the edges. Dark streaks crawl up the veins beneath translucent, fevered skin.",
            on_smell = "The sickly-sweet stench of sepsis. Rotting flesh beneath the bandage.",

            damage_per_tick = 20,

            restricts = {
                climb = true,
                run = true,
                fight = true,
            },

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
                -- 1800 seconds = 5 turns. Last window for treatment.
            },
        },

        -- ── FATAL: Terminal — triggers death check ──
        fatal = {
            name = "fatal blood loss",
            description = "You've lost too much blood.",
            terminal = true,
        },

        -- ── HEALED: Terminal — injury removed ──
        healed = {
            name = "healed wound",
            description = "The wound on your arm has closed, leaving an angry red scar. Full strength has returned.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies healing item ──
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "bleeding",
            message = "You press the bandage firmly against the wound. The bleeding slows, then stops.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "worsened", to = "treated",
            verb = "use",
            requires_item_cures = "bleeding",
            message = "You apply the bandage to the infected wound. The swelling begins to subside.",
            mutate = { damage_per_tick = 0 },
        },

        -- ── Auto-transitions: Timer-driven worsening ──
        {
            from = "active", to = "worsened",
            trigger = "auto",
            condition = "timer_expired",
            message = "The wound is getting worse. You feel feverish.",
            mutate = { damage_per_tick = 10 },
        },
        {
            from = "worsened", to = "critical",
            trigger = "auto",
            condition = "timer_expired",
            message = "Infection spreads. Your vision swims.",
            mutate = { damage_per_tick = 20 },
        },
        {
            from = "critical", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "You collapse. The world goes dark.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The wound has fully healed. Only a scar remains.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["bandage"] = {
            transitions_to = "treated",
            from_states = { "active", "worsened" },
        },
        ["healing-poultice"] = {
            transitions_to = "treated",
            from_states = { "active", "worsened", "critical" },
        },
    },
}
