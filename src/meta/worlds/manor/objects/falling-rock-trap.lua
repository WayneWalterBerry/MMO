-- rock-trap.lua — Falling rock trap: unconsciousness trigger object
-- Decision: D-EFFECTS-PIPELINE, D-CONSC*, D-SELF-INFLICT-CEILING
-- Issue: #162
-- States: armed → triggered → spent (permanent, one-shot)
-- Contact pipeline: tripwire trigger → inflict_injury(concussion, severity=severe)
-- Disarm path: cut wire with knife → spent without injury
--
-- Effect routing (all paths via effects.process):
--   walk-through (armed) → trans.effect → inflict_injury(concussion, damage=8)
--   self-trigger  (armed) → trans.effect → inflict_injury(concussion, damage=8)
--   cut wire      (armed) → disarm path  → spent, no injury
return {
    guid = "{4d0ef3f6-1212-48e6-ab26-0c0a6f727478}",
    template = "furniture",

    id = "falling-rock-trap",
    material = "stone",
    keywords = {"rock trap", "falling rock", "tripwire", "wire", "boulder"},
    size = 8,
    weight = 200,
    categories = {"trap", "dangerous", "hazard", "stone", "mechanism"},
    portable = false,
    room_position = "mounted on the ceiling",

    effects_pipeline = true,

    -- Trap metadata
    is_trap = true,
    is_armed = true,
    is_dangerous = true,
    trap_type = "falling-weight",
    trap_injury_type = "concussion",
    trap_damage_amount = 8,

    -- Unconsciousness metadata
    causes_unconsciousness = true,
    injury_type = "concussion",
    unconscious_severity = "severe",
    unconscious_duration = { min = 10, max = 15 },

    -- Initial state (armed)
    name = "a crude rock trap",
    description = "A heavy granite boulder sits in a crude wooden cradle bolted to the ceiling, held in place by a fraying hemp rope threaded through an iron ring. A thin tripwire stretches across the floor at ankle height.",
    room_presence = "A thin wire stretches across the passage at ankle height. Something heavy looms above.",
    on_feel = "Your fingers find a taut cord stretched across the passage at ankle height. Following it, you trace it to a rough iron ring set in the wall. Something heavy hangs above.",
    on_smell = "Old rope. Dust. The faint mineral smell of raw stone.",
    on_listen = "A faint creaking from above, like rope under tension.",
    on_taste = "You'd have to put your mouth on a tripwire. Probably not wise.",

    location = nil,

    -- FSM
    initial_state = "armed",
    _state = "armed",

    states = {
        -- ── ARMED: Trap is set, rock overhead, tripwire taut ──
        armed = {
            name = "a crude rock trap",
            description = "A heavy granite boulder sits in a crude wooden cradle bolted to the ceiling, held in place by a fraying hemp rope threaded through an iron ring. A thin tripwire stretches across the floor at ankle height.",
            room_presence = "A thin wire stretches across the passage at ankle height. Something heavy looms above.",

            on_feel = "Your fingers find a taut cord stretched across the passage at ankle height. Following it, you trace it to a rough iron ring set in the wall. Something heavy hangs above.",
            on_smell = "Old rope. Dust. The faint mineral smell of raw stone.",
            on_listen = "A faint creaking from above, like rope under tension.",
            on_taste = "You'd have to put your mouth on a tripwire. Probably not wise.",

            is_dangerous = true,
            is_armed = true,
        },

        -- ── TRIGGERED: Rock has fallen, brief transition ──
        triggered = {
            name = "a fallen boulder",
            description = "A massive granite boulder lies where it fell, cracks radiating through the flagstones beneath it. A frayed rope dangles from a ceiling ring. The tripwire is slack.",
            room_presence = "A massive boulder lies on the ground. A frayed rope dangles from the ceiling.",

            on_feel = "A huge boulder blocking the passage. Still warm from the impact.",
            on_smell = "Crushed stone dust. The sharp smell of fresh-broken rock.",
            on_listen = "Silence. The settling creak of stressed stone.",
            on_taste = "Stone dust coats your tongue. Gritty and dry.",

            is_dangerous = false,
            is_armed = false,
        },

        -- ── SPENT: Rock on the floor, trap permanently disarmed ──
        spent = {
            name = "a fallen boulder",
            description = "A massive granite boulder rests on the cracked flagstones. A frayed rope dangles from an iron ring in the ceiling. The tripwire lies slack on the ground. The trap is spent.",
            room_presence = "A massive boulder blocks part of the passage. A frayed rope hangs from above.",

            on_feel = "A heavy boulder on the ground. A frayed rope dangles from a ceiling ring. Cold granite, immovable.",
            on_smell = "Settling dust. The mineral smell of granite.",
            on_listen = "Nothing. The trap is spent.",
            on_taste = "Gritty stone dust. Nothing more.",

            is_dangerous = false,
            is_armed = false,
            is_spent = true,
        },

        -- ── DISARMED: Wire cut, rock dropped harmlessly ──
        disarmed = {
            name = "a disarmed rock trap",
            description = "The boulder has dropped harmlessly to one side, the severed hemp rope dangling from its ceiling ring. The tripwire lies cut on the ground. The trap is spent and safe.",
            room_presence = "A boulder rests against the wall. A severed rope dangles from the ceiling.",

            on_feel = "A boulder resting against the wall. The severed rope is rough hemp. No tension, no danger.",
            on_smell = "Dust and old rope. The crisis is past.",
            on_listen = "Silence. Complete mechanical stillness.",
            on_taste = "Dust. Just dust.",

            is_dangerous = false,
            is_armed = false,
            is_disarmed = true,
        },
    },

    transitions = {
        -- ── Trigger: Player walks into tripwire or self-triggers ──
        {
            from = "armed", to = "triggered", verb = "trigger",
            aliases = {"pull wire", "step on wire", "walk into trap", "trip wire"},
            message = "Your foot catches on something — a wire, stretched taut across the passage. You hear a snap, then a terrible grinding above. You look up. The last thing you see is a shadow the size of a boulder.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "severe",
                source = "falling-rock-trap",
                location = "head",
                damage = 8,
                causes_unconsciousness = true,
                unconscious_duration = { min = 10, max = 15 },
                message = "A granite boulder crashes down on you. The world goes dark.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "severe", source = "falling-rock-trap", location = "head",
                  damage = 8, causes_unconsciousness = true,
                  unconscious_duration = { min = 10, max = 15 },
                  message = "A granite boulder crashes down on you. The world goes dark." },
                { type = "narrate",
                  message = "Your foot catches on something — a wire, stretched taut across the passage. You hear a snap, then a terrible grinding above. You look up. The last thing you see is a shadow the size of a boulder." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                keywords = { add = "fallen", remove = "tripwire" },
                categories = { remove = "dangerous", add = "obstacle" },
            },
        },

        -- ── Self-infliction: Deliberate trigger ──
        {
            from = "armed", to = "triggered", verb = "pull",
            aliases = {"yank", "tug"},
            message = "You pull the wire deliberately. The snap echoes in the silence. The grinding starts. You have just enough time to think \"this was a mistake\" before the world goes dark.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "severe",
                source = "self-inflicted:falling-rock-trap",
                location = "head",
                damage = 8,
                causes_unconsciousness = true,
                unconscious_duration = { min = 10, max = 15 },
                message = "The boulder strikes you. Darkness.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "severe", source = "self-inflicted:falling-rock-trap",
                  location = "head", damage = 8, causes_unconsciousness = true,
                  unconscious_duration = { min = 10, max = 15 },
                  message = "The boulder strikes you. Darkness." },
                { type = "narrate",
                  message = "You pull the wire deliberately. The snap echoes in the silence. The grinding starts. You have just enough time to think \"this was a mistake\" before the world goes dark." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                keywords = { add = "fallen", remove = "tripwire" },
                categories = { remove = "dangerous", add = "obstacle" },
            },
        },

        -- ── Triggered → Spent: Immediate auto-transition ──
        {
            from = "triggered", to = "spent",
            trigger = "auto",
            condition = "immediate",
            message = "",
        },

        -- ── Disarm: Cut the wire with a cutting tool ──
        {
            from = "armed", to = "disarmed", verb = "cut",
            aliases = {"slice", "sever"},
            requires_tool = "cutting_edge",
            message = "You slice through the hemp wire. There's a grinding sound, then a heavy thud — the boulder drops harmlessly to one side. The trap is spent.",
            fail_message = "You need something sharp to cut the wire.",
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_disarmed = true,
                keywords = { add = "disarmed", remove = "tripwire" },
                categories = { remove = "dangerous", add = "disarmed" },
            },
        },
    },

    -- Narration pools for unconscious/wake-up states
    unconscious_narration = {
        periodic = "Weight. Unbearable weight pressing down. The smell of dust and blood. You can't move. You can't think.",
        wake_up = "Consciousness returns like a slow tide. Your head screams. Your body is pinned beneath something immensely heavy — no, the rock has rolled aside. You're free. But the ache in your skull tells you you were out for a long time.",
    },

    -- Command rejection messages during unconsciousness from this source
    rejection_messages = {
        "Weight. Pressure. Your body refuses every signal your brain sends.",
        "You try to move. Pain answers. You stop trying.",
        "Somewhere far away, your fingers twitch. That's all.",
    },

    -- GOAP prerequisites
    prerequisites = {
        trigger = { warns = { "injury", "concussion", "unconsciousness" } },
        pull = { warns = { "injury", "concussion", "unconsciousness" } },
        cut = {
            requires_tool = "cutting_edge",
            requires_state = "armed",
        },
    },

    mutations = {
        break_attempt = {
            message = "The rock is solid granite. Your efforts accomplish nothing but sore knuckles.",
        },
    },
}
