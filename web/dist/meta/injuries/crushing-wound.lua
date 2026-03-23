-- src/meta/injuries/crushing-wound.lua
-- Injury template: Crushing Wound (bear trap, falling debris, etc.)
-- Pattern: Heavy initial blunt damage + ongoing bleeding from crushed tissue
-- FSM: active → treated → healed  (bandaged path, bleeding stops)
--      active → worsened → treated → healed  (untreated too long, infection)
--      active → worsened → critical → fatal  (completely untreated)
-- Distinct from pure bleeding: crushing pain persists even after bandaging.

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{8b3f6a21-d4c7-4e59-a1b2-5c8d9e0f3a74}",
    id = "crushing-wound",
    name = "Crushing Wound",
    category = "physical",
    description = "A crushing injury from blunt mechanical force. Combines deep bruising with bleeding from ruptured tissue.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 15,
        damage_per_tick = 2,
        message = "Bone-crushing force. The pain is blinding — blood wells from torn flesh beneath the bruising.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Fresh crushing injury, bleeding + deep bruising ──
        active = {
            name = "crushing wound",
            description = "Your hand is a ruin of purple bruising and torn skin. Blood seeps steadily from the crushed flesh. The bones ache deep — something may be cracked. Every movement sends jolts of white-hot pain up your arm.",
            on_feel = "Swollen, hot, throbbing. The flesh is pulped beneath the skin. You can feel the grinding of damaged bone.",
            on_look = "Deep purple and black bruising. Torn skin weeping blood. The fingers are swollen to twice their size.",
            on_smell = "Blood. The sharp metallic tang of a serious wound.",

            damage_per_tick = 2,

            restricts = {
                grip = true,
                climb = true,
                fight = true,
            },

            timed_events = {
                { event = "transition", delay = 4320, to_state = "worsened" },
                -- 4320 seconds = 12 turns. Untreated crushing wound gets infected.
            },
        },

        -- ── TREATED: Bandaged — bleeding stopped, but crushing pain persists ──
        treated = {
            name = "bandaged crushing wound",
            description = "The wound is bandaged. The bleeding has stopped, but deep bruising throbs beneath the wrapping. Your hand is stiff and swollen — the crushing damage will take time to heal.",
            on_feel = "Tight bandages over swollen flesh. The ache is deep and constant, but the bleeding has stopped.",
            on_look = "Heavy bandaging around a badly bruised hand. No fresh blood shows through.",

            damage_per_tick = 0,

            restricts = {
                grip = true,
            },

            timed_events = {
                { event = "transition", delay = 5400, to_state = "healed" },
                -- 5400 seconds = 15 turns. Crushing wounds heal slowly even when treated.
            },
        },

        -- ── WORSENED: Untreated too long, infection sets in ──
        worsened = {
            name = "infected crushing wound",
            description = "The crushing wound festers. The bruised flesh is hot and swollen, streaked with angry red lines. Infection has taken hold.",
            on_feel = "Burning heat radiates from the wound. The swelling has spread up your arm. Fever is setting in.",
            on_look = "The wound is inflamed and oozing. Red streaks extend from the injury site. This is getting worse.",

            damage_per_tick = 5,

            restricts = {
                grip = true,
                climb = true,
                run = true,
                fight = true,
            },

            timed_events = {
                { event = "transition", delay = 3600, to_state = "critical" },
                -- 3600 seconds = 10 turns. Infection worsens to critical.
            },
        },

        -- ── CRITICAL: Sepsis, last chance for treatment ──
        critical = {
            name = "septic crushing wound",
            description = "Sepsis. The infection from the crushing wound has spread. Your arm is useless, and fever clouds your mind. Without treatment, this ends badly.",
            on_feel = "Burning fever. The arm is nearly numb. You can barely think straight.",

            damage_per_tick = 12,

            restricts = {
                grip = true,
                climb = true,
                run = true,
                fight = true,
                focus = true,
            },

            timed_events = {
                { event = "transition", delay = 1800, to_state = "fatal" },
                -- 1800 seconds = 5 turns. Final window.
            },
        },

        -- ── FATAL: Terminal — the wound kills ──
        fatal = {
            name = "fatal crushing wound",
            description = "The infection overwhelms you. Darkness closes in.",
            terminal = true,
        },

        -- ── HEALED: Terminal — injury cleared ──
        healed = {
            name = "healed crushing wound",
            description = "The crushing wound has healed. A web of scar tissue marks where the trap bit down. Grip strength has returned, though the hand aches in cold weather.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies bandage (active) ──
        {
            from = "active", to = "treated",
            verb = "use",
            requires_item_cures = "crushing-wound",
            message = "You press the bandage firmly against the crushed flesh. The bleeding slows, then stops. The deep ache remains, but the worst is contained.",
            mutate = { damage_per_tick = 0 },
        },

        -- ── Verb-triggered: Player applies bandage (worsened) ──
        {
            from = "worsened", to = "treated",
            verb = "use",
            requires_item_cures = "crushing-wound",
            message = "You clean and bandage the infected wound. The angry redness begins to subside. The fever will take time to break.",
            mutate = { damage_per_tick = 0, _timer_delay = 7200 },
            -- Recovery from infection takes longer: 7200 seconds = 20 turns.
        },

        -- ── Verb-triggered: Healing poultice treats critical ──
        {
            from = "critical", to = "treated",
            verb = "use",
            requires_item_cures = "crushing-wound",
            message = "The poultice draws the infection. The fever begins to break. You've pulled back from the edge.",
            mutate = { damage_per_tick = 0, _timer_delay = 10800 },
            -- Recovery from critical is very slow: 10800 seconds = 30 turns.
        },

        -- ── Auto-transitions: Untreated degradation ──
        {
            from = "active", to = "worsened",
            trigger = "auto",
            condition = "timer_expired",
            message = "The crushing wound is getting worse. Red streaks spread from the injury. Fever builds. You need to bandage this.",
            mutate = { damage_per_tick = 5 },
        },
        {
            from = "worsened", to = "critical",
            trigger = "auto",
            condition = "timer_expired",
            message = "The infection is spreading. Your arm burns. Your vision swims with fever.",
            mutate = { damage_per_tick = 12 },
        },
        {
            from = "critical", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "The fever takes you. The world fades to nothing.",
        },
        {
            from = "treated", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The crushing wound has finally healed. A network of scars marks where iron met flesh, but your hand works again.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Bandage treats bleeding component. Healing poultice works on infection.
    -- Crushing pain (bruising) persists and self-heals with time.
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
