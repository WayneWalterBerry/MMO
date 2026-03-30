-- src/meta/worlds/manor/injuries/burn.lua
-- Injury template: Burn
-- Pattern: One-time damage from flame contact, cold water or damp cloth treats
-- FSM: active → treated → healed  (cold water/cloth path)
--      active → healed  (natural healing, 10 turns — minor burns only)
--      active → blistered → treated → healed  (severe burns, untreated too long)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{d182984e-b424-47d9-91fc-2796d993228c}",
    id = "burn",
    name = "Burn",
    category = "environmental",
    description = "A burn from contact with flame or a hot surface.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "one_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 5,
        damage_per_tick = 0,
        message = "Searing pain — the flame bites into your skin.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Burn is fresh, skin red and tender ──
        active = {
            name = "burn",
            description = "Your fingertips are red and tender where you touched the flame. The skin is hot to the touch.",
            on_feel = "Hot, painful skin. Even the air stings against it.",
            on_look = "Red, angry skin where the flame touched. No blistering yet.",

            damage_per_tick = 0,

            restricts = {
                grip = true,
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "healed" },
                -- 3600 seconds = 10 turns. Minor burns self-heal naturally.
                -- Severe burns: inflicting object overrides timer to transition
                -- to "blistered" at delay=2880 (8 turns) instead.
            },
        },

        -- ── BLISTERED: Severe burn left untreated, worsened ──
        -- Only reachable from severe burn sources (torch, prolonged flame).
        -- Requires salve — cold water no longer sufficient.
        blistered = {
            name = "blistered burn",
            description = "The burn has blistered. Fluid-filled welts cover your hand. Don't touch anything.",
            on_feel = "Throbbing, tight skin. The blisters are agonizing to touch.",
            on_look = "Angry welts, swollen with fluid. The skin is ruined.",

            damage_per_tick = 0,

            restricts = {
                grip = true,
                climb = true,
            },

            -- No timed auto-heal. Blistered burns require salve treatment.
        },

        -- ── TREATED: Cooling applied, pain fading ──
        treated = {
            name = "treated burn",
            description = "The cool water brought relief. The burn still aches, but the angry red is fading.",
            on_feel = "Tender skin, but the searing pain has eased.",
            on_look = "The redness is fading. Healing has begun.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 1800, to_state = "healed" },
                -- 1800 seconds = 5 turns to fully heal after treatment.
            },
        },

        -- ── HEALED: Terminal — injury removed ──
        healed = {
            name = "healed burn",
            description = "The burn has faded to a patch of shiny pink skin. No pain remains.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies cold water or damp cloth ──
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "burn",
            message = "You splash cold water over the burn. The relief is immediate — the searing heat fades.",
        },

        -- ── Verb-triggered: Salve treats blistered burns ──
        {
            from = "blistered", to = "treated",
            verb = "use",
            requires_item_cures = "burn",
            message = "The cool salve soothes the blisters. The throbbing eases to a dull warmth.",
        },

        -- ── Auto-transitions ──
        {
            from = "active", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The burn has faded on its own. A patch of pink skin is all that remains.",
        },
        {
            from = "active", to = "blistered",
            trigger = "auto",
            condition = "timer_expired",
            -- Triggered by severe burn sources that override the active state timer.
            message = "The burn has blistered. Fluid-filled welts rise on your skin. This is beyond simple cooling — you need a medicinal salve.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The burn has fully healed. Only a faint pink mark remains.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Cold water and damp cloth treat active burns.
    -- Salve treats active burns AND blistered burns.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["cold-water"] = {
            transitions_to = "treated",
            from_states = { "active" },
        },
        ["damp-cloth"] = {
            transitions_to = "treated",
            from_states = { "active" },
        },
        ["salve"] = {
            transitions_to = "treated",
            from_states = { "active", "blistered" },
        },
    },
}
