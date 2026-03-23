-- src/meta/injuries/poisoned-nightshade.lua
-- Injury template: Nightshade Poisoning
-- Pattern: Rapid lethal over-time damage, specific antidote only
-- FSM: active → neutralized → healed  (antidote in time)
--      active → worsened → neutralized → healed  (late antidote)
--      active → worsened → fatal  (no antidote)

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{62874f58-bcee-4f39-9f63-c3953d532aea}",
    id = "poisoned-nightshade",
    name = "Nightshade Poisoning",
    category = "toxin",
    description = "Deadly nightshade (belladonna) poisoning. Rapid decline without the specific antidote.",

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "active",

    on_inflict = {
        initial_damage = 10,
        damage_per_tick = 8,
        message = "A bitter, almost sweet taste burns your throat. Your heart begins to race.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── ACTIVE: Poison spreading, rapid health drain ──
        active = {
            name = "nightshade poisoning",
            description = "Your pupils are huge. Your heart hammers against your ribs. The burning in your throat has a bitter, sweet edge — nightshade.",
            on_feel = "Your skin is clammy. Your heart races under your fingertips.",
            on_look = "Your hands are shaking. Your vision blurs at the edges.",
            on_smell = "Everything smells sharp and metallic.",

            damage_per_tick = 8,

            restricts = {
                focus = true,
            },

            timed_events = {
                { event = "transition", delay = 1440, to_state = "worsened" },
                -- 1440 seconds = 4 turns. Escalates rapidly.
            },
        },

        -- ── WORSENED: Hallucinations, collapse risk, accelerated drain ──
        worsened = {
            name = "advanced nightshade poisoning",
            description = "Shadows move at the edges of your vision. Things that aren't there. Your legs won't hold you steady.",
            on_feel = "Your heartbeat is irregular — fast, then slow, then fast again.",
            on_look = "The world tilts and warps. Shapes crawl in the darkness.",

            damage_per_tick = 15,

            restricts = {
                focus = true,
                climb = true,
                run = true,
                fight = true,
            },

            timed_events = {
                { event = "transition", delay = 1440, to_state = "fatal" },
                -- 1440 seconds = 4 turns. Death if untreated.
            },
        },

        -- ── NEUTRALIZED: Antidote taken, poison clearing ──
        neutralized = {
            name = "neutralized poison",
            description = "The racing in your chest slows. The antidote is working. You feel wrung out, but alive.",
            on_feel = "Your skin is still clammy, but the trembling is fading.",
            on_look = "Your pupils are contracting. The world steadies.",

            damage_per_tick = 0,

            timed_events = {
                { event = "transition", delay = 1440, to_state = "healed" },
                -- 1440 seconds = 4 turns recovery from stage 1.
                -- Recovery from stage 2 (worsened) takes longer: engine sets
                -- delay = 2160 (6 turns) via transition mutate.
            },
        },

        -- ── FATAL: Terminal — nightshade kills ──
        fatal = {
            name = "fatal nightshade poisoning",
            description = "The darkness is complete. Your heart flutters, then begins to stop. The nightshade has won.",
            terminal = true,
        },

        -- ── HEALED: Terminal — poison fully cleared ──
        healed = {
            name = "recovered from poisoning",
            description = "The last traces of nightshade have left your body. Your vision is clear. Your heart beats steady.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player drinks nightshade antidote ──
        {
            from = "active", to = "neutralized",
            verb = "drink",
            requires_item_cures = "poisoned-nightshade",
            message = "You drink the dark liquid. The racing in your chest slows. Your pupils contract. The antidote is working.",
            mutate = { damage_per_tick = 0 },
        },
        {
            from = "worsened", to = "neutralized",
            verb = "drink",
            requires_item_cures = "poisoned-nightshade",
            message = "You force the antidote down. The hallucinations fade. Your heartbeat stumbles back toward normal. Just in time.",
            mutate = { damage_per_tick = 0, _timer_delay = 2160 },
            -- Recovery from worsened takes 6 turns (2160 seconds) instead of 4.
        },

        -- ── Auto-transitions: Poison escalation ──
        {
            from = "active", to = "worsened",
            trigger = "auto",
            condition = "timer_expired",
            message = "The room pulses with your heartbeat. Shadows crawl. The nightshade is reaching your brain.",
            mutate = { damage_per_tick = 15 },
        },
        {
            from = "worsened", to = "fatal",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your vision narrows to a dark tunnel. Your heart stutters. The nightshade has won.",
        },
        {
            from = "neutralized", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "The last traces of the nightshade have left your body. You won't forget that bitter taste.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Only the nightshade-specific antidote works. Generic cures fail.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["antidote-nightshade"] = {
            transitions_to = "neutralized",
            from_states = { "active", "worsened" },
        },
        -- Bandage, generic antidote, water — NONE listed here.
        -- Wrong treatment = no match = no effect.
    },
}
