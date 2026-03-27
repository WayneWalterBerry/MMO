-- src/meta/injuries/spider-venom.lua
-- Injury template: Spider Venom
-- Pattern: Immediate symptoms, progressive paralysis, recoverable
-- FSM: injected → spreading → paralysis → healed  (untreated, survives)
--      injected → healed  (early antivenom)
--      spreading → healed  (late antivenom, still possible)
--      paralysis: too late for cure, must ride it out

return {
    -- ═══════════════════════════════════════════════════════════
    -- IDENTITY
    -- ═══════════════════════════════════════════════════════════
    guid = "{b746be00-1ce2-4844-b3bb-7f85091ca220}",
    id = "spider-venom",
    name = "Spider Venom",
    category = "disease",
    description = "Neurotoxic venom from a spider bite. Causes progressive paralysis if untreated.",

    -- ═══════════════════════════════════════════════════════════
    -- DISEASE-SPECIFIC FIELDS
    -- ═══════════════════════════════════════════════════════════
    curable_in = { "injected", "spreading" },
    transmission = { probability = 1.0, via = "bite" },

    -- ═══════════════════════════════════════════════════════════
    -- DAMAGE MODEL
    -- ═══════════════════════════════════════════════════════════
    damage_type = "over_time",
    initial_state = "injected",

    on_inflict = {
        initial_damage = 2,
        damage_per_tick = 2,
        message = "Sharp pain flares from the bite. A burning numbness begins to spread.",
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM STATES
    -- ═══════════════════════════════════════════════════════════
    states = {
        -- ── INJECTED: Venom enters bloodstream, immediate pain ──
        injected = {
            name = "spider bite",
            description = "The bite burns. A creeping numbness spreads outward from the wound.",
            on_feel = "The skin around the bite is hot and swollen. Your fingers tingle.",
            on_look = "Two small puncture marks, ringed with angry red. The swelling is spreading.",
            on_smell = "A faint chemical tang rises from the wound.",

            damage_per_tick = 2,

            timed_events = {
                { event = "transition", delay = 1080, to_state = "spreading" },
                -- 1080 seconds = 3 ticks. Venom spreads quickly.
            },
        },

        -- ── SPREADING: Venom reaches major muscle groups ──
        spreading = {
            name = "spreading venom",
            description = "The numbness has reached your legs. Each step is an effort. The venom is winning.",
            on_feel = "Your limbs feel heavy and distant. Muscle cramps ripple through your calves.",
            on_look = "Dark veins radiate from the bite. Your hands shake. Your gait is unsteady.",
            on_smell = "Cold sweat with an acrid chemical undertone.",

            damage_per_tick = 3,

            restricts = {
                movement = true,
            },

            timed_events = {
                { event = "transition", delay = 1800, to_state = "paralysis" },
                -- 1800 seconds = 5 ticks. Escalation to full paralysis.
            },
        },

        -- ── PARALYSIS: Full neuromuscular shutdown, no cure ──
        paralysis = {
            name = "venom paralysis",
            description = "You can't move. Your body is a prison of locked muscles. Only your eyes obey you.",
            on_feel = "Nothing. Your body is numb from the neck down.",
            on_look = "You are frozen in place. Only shallow breathing continues.",

            damage_per_tick = 1,

            restricts = {
                movement = true,
                attack = true,
                precise_actions = true,
            },

            timed_events = {
                { event = "transition", delay = 2880, to_state = "healed" },
                -- 2880 seconds = 8 ticks. Venom metabolizes, paralysis fades.
            },
        },

        -- ── HEALED: Terminal — venom cleared from system ──
        healed = {
            name = "recovered from venom",
            description = "Feeling returns to your limbs in painful waves. The venom has run its course. You can move again.",
            terminal = true,
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- FSM TRANSITIONS
    -- ═══════════════════════════════════════════════════════════
    transitions = {
        -- ── Verb-triggered: Player applies antivenom during injection ──
        {
            from = "injected", to = "healed",
            verb = "use",
            requires_item_cures = "spider-venom",
            message = "You press the antivenom poultice against the bite. The burning fades. The numbness retreats.",
            mutate = { damage_per_tick = 0 },
        },
        -- ── Verb-triggered: Player applies antivenom during spreading ──
        {
            from = "spreading", to = "healed",
            verb = "use",
            requires_item_cures = "spider-venom",
            message = "You force the antivenom into the wound. Sensation floods back into your legs. The venom is neutralized.",
            mutate = { damage_per_tick = 0 },
        },

        -- ── Auto-transitions: Venom progression ──
        {
            from = "injected", to = "spreading",
            trigger = "auto",
            condition = "timer_expired",
            message = "The numbness creeps past your knee. Your legs feel like they belong to someone else.",
            mutate = { damage_per_tick = 3 },
        },
        {
            from = "spreading", to = "paralysis",
            trigger = "auto",
            condition = "timer_expired",
            message = "Your legs give out. Your arms lock at your sides. The venom has reached your spine.",
            mutate = { damage_per_tick = 1 },
        },
        {
            from = "paralysis", to = "healed",
            trigger = "auto",
            condition = "timer_expired",
            message = "Pins and needles — agonizing, but welcome. Your fingers twitch. The venom is finally fading.",
        },
    },

    -- ═══════════════════════════════════════════════════════════
    -- HEALING INTERACTIONS
    -- Treatable during injected and spreading phases.
    -- Once paralysis sets in, antivenom can't help — ride it out.
    -- ═══════════════════════════════════════════════════════════
    healing_interactions = {
        ["antivenom"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
        ["antidote-vial"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
            success_message = "The antidote burns going down, but the swelling begins to subside.",
            fail_message = "The paralysis is too advanced. The antidote cannot help now.",
        },
    },
}
