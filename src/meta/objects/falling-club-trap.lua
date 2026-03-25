-- club-trap.lua — Spring-loaded club trap: unconsciousness trigger object
-- Decision: D-EFFECTS-PIPELINE, D-CONSC*, D-SELF-INFLICT-CEILING
-- Issue: #162
-- States: armed → triggered → spent (permanent, one-shot)
-- Mechanical trap simulating "enemy blow" — V1 has no NPCs (Principle 0)
-- Pressure plate + concealed spring-loaded oak club
--
-- Effect routing (all paths via effects.process):
--   pressure plate (armed) → trans.effect → inflict_injury(concussion, severity=moderate)
--   self-trigger   (armed) → trans.effect → inflict_injury(concussion, severity=moderate)
--   disarm         (armed) → safe path    → spent, no injury
return {
    guid = "{d9a87506-25cd-4bd1-a638-77876a0a285a}",
    template = "furniture",

    id = "falling-club-trap",
    material = "oak",
    keywords = {"club", "trap", "spring trap", "mechanism", "lever", "club trap", "spring", "pressure plate", "plate", "panel", "flagstone"},
    size = 5,
    weight = 80,
    categories = {"trap", "dangerous", "hazard", "mechanical", "wooden"},
    portable = false,
    room_position = "concealed behind a wall panel",

    effects_pipeline = true,

    -- Trap metadata
    is_trap = true,
    is_armed = true,
    is_dangerous = true,
    trap_type = "spring-mechanism",
    trap_injury_type = "concussion",
    trap_damage_amount = 5,

    -- Unconsciousness metadata
    causes_unconsciousness = true,
    injury_type = "concussion",
    unconscious_severity = "moderate",
    unconscious_duration = { min = 6, max = 10 },

    -- Initial state (armed)
    name = "a spring-loaded club",
    description = "A heavy oak club is mounted on a spring-loaded iron arm, concealed behind a false wall panel. A pressure plate on the floor serves as the trigger.",
    room_presence = "A loose flagstone rocks slightly underfoot. A faint seam runs along the wall panel.",
    on_feel = "Your fingers find a seam in the wall — a panel that shifts slightly. Below your feet, a flagstone rocks under your weight. Something is rigged here.",
    on_smell = "Machine oil. The faint metallic tang of a spring under tension.",
    on_listen = "A faint metallic creak when you shift your weight. Something is coiled and waiting.",
    on_taste = "You taste iron and oil on the air. Industrial. Wrong for a cellar.",

    location = nil,

    -- FSM
    initial_state = "armed",
    _state = "armed",

    states = {
        -- ── ARMED: Trap set, pressure plate active, club cocked ──
        armed = {
            name = "a spring-loaded club",
            description = "A heavy oak club is mounted on a spring-loaded iron arm, concealed behind a false wall panel. A pressure plate on the floor serves as the trigger.",
            room_presence = "A loose flagstone rocks slightly underfoot. A faint seam runs along the wall panel.",

            on_feel = "Your fingers find a seam in the wall — a panel that shifts slightly. Below your feet, a flagstone rocks under your weight. Something is rigged here.",
            on_smell = "Machine oil. The faint metallic tang of a spring under tension.",
            on_listen = "A faint metallic creak when you shift your weight. Something is coiled and waiting.",
            on_taste = "You taste iron and oil on the air. Industrial. Wrong for a cellar.",

            is_dangerous = true,
            is_armed = true,
        },

        -- ── TRIGGERED: Club has swung, brief transition ──
        triggered = {
            name = "a sprung club trap",
            description = "A heavy oak club hangs limply from a spring-loaded iron arm, the wall panel smashed open. The pressure plate is depressed. The spring is slack — the mechanism has fired.",
            room_presence = "A heavy oak club hangs limply from a wall-mounted iron arm. The trap has fired.",

            on_feel = "A heavy oak club, still swinging on its iron arm. The wood is dense and hard — this thing was built to kill.",
            on_smell = "Machine oil and fresh-split wood from the shattered panel.",
            on_listen = "A slow creak as the club settles on its arm. The spring ticks softly as it cools.",
            on_taste = "Oil and sawdust in the air.",

            is_dangerous = false,
            is_armed = false,
        },

        -- ── SPENT: Club extended, spring relaxed, trap done ──
        spent = {
            name = "a spent club trap",
            description = "A heavy oak club hangs limply from its iron arm mount. The wall panel is shattered. The spring mechanism is slack and spent. The pressure plate in the floor is jammed down.",
            room_presence = "A heavy oak club hangs limply from a broken wall panel. The trap is spent.",

            on_feel = "A heavy club on a limp iron arm. A relaxed spring. The mechanism is spent. The oak club is solid and weighty.",
            on_smell = "Stale machine oil. The metallic smell is fading.",
            on_listen = "Silence. The coiled tension is gone. Just the faint tick of cooling metal.",
            on_taste = "Oil and dust. Mechanical residue.",

            is_dangerous = false,
            is_armed = false,
            is_spent = true,
        },

        -- ── DISARMED: Mechanism jammed, safe ──
        disarmed = {
            name = "a disarmed club trap",
            description = "The spring-loaded club hangs limply, the mechanism jammed by a wedge. The pressure plate is blocked. The trap is harmless.",
            room_presence = "A club trap has been disarmed. The mechanism hangs limply behind a broken panel.",

            on_feel = "The club is inert. The spring is jammed. No tension, no danger. Just cold iron and heavy oak.",
            on_smell = "Machine oil. The threat is gone but the smell lingers.",
            on_listen = "Silent. Completely mechanically dead.",
            on_taste = "Stale air. Nothing active.",

            is_dangerous = false,
            is_armed = false,
            is_disarmed = true,
        },
    },

    transitions = {
        -- ── Trigger: Pressure plate activation ──
        {
            from = "armed", to = "triggered", verb = "step",
            aliases = {"step on plate", "step on flagstone", "walk"},
            message = "The flagstone sinks under your foot with a click. You hear a metallic twang — and then something fast and heavy fills your vision. A wooden club, swinging out from the wall on an iron arm. It connects with the side of your head. The world cracks apart.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "moderate",
                source = "falling-club-trap",
                location = "head",
                damage = 5,
                causes_unconsciousness = true,
                unconscious_duration = { min = 6, max = 10 },
                message = "The club strikes the side of your head. The world goes white, then black.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "moderate", source = "falling-club-trap",
                  location = "head", damage = 5, causes_unconsciousness = true,
                  unconscious_duration = { min = 6, max = 10 },
                  message = "The club strikes the side of your head. The world goes white, then black." },
                { type = "narrate",
                  message = "The flagstone sinks under your foot with a click. You hear a metallic twang — and then something fast and heavy fills your vision. A wooden club, swinging out from the wall on an iron arm. It connects with the side of your head. The world cracks apart." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                keywords = { add = "sprung", remove = "spring" },
                categories = { remove = "dangerous", add = "spent" },
            },
        },

        -- ── Self-infliction: Deliberate trigger ──
        {
            from = "armed", to = "triggered", verb = "trigger",
            aliases = {"push lever", "activate mechanism", "activate trap", "push panel", "open panel"},
            message = "You step on the loose flagstone deliberately. Click. Twang. The club catches you perfectly across the temple. You had time to brace for it. It didn't help.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "moderate",
                source = "self-inflicted:falling-club-trap",
                location = "head",
                damage = 5,
                causes_unconsciousness = true,
                unconscious_duration = { min = 6, max = 10 },
                message = "The club connects with your temple. Darkness.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "moderate", source = "self-inflicted:falling-club-trap",
                  location = "head", damage = 5, causes_unconsciousness = true,
                  unconscious_duration = { min = 6, max = 10 },
                  message = "The club connects with your temple. Darkness." },
                { type = "narrate",
                  message = "You step on the loose flagstone deliberately. Click. Twang. The club catches you perfectly across the temple. You had time to brace for it. It didn't help." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                keywords = { add = "sprung", remove = "spring" },
                categories = { remove = "dangerous", add = "spent" },
            },
        },

        -- ── Triggered → Spent: Immediate auto-transition ──
        {
            from = "triggered", to = "spent",
            trigger = "auto",
            condition = "immediate",
            message = "",
        },

        -- ── Disarm: Jam the mechanism with a tool ──
        {
            from = "armed", to = "disarmed", verb = "disarm",
            aliases = {"jam", "disable", "block spring", "defuse", "neutralize"},
            requires_tool = "thin_tool",
            message = "You wedge the knife into the spring mechanism. There's a click, a soft whir, and the club drops limply. The trap is harmless now.",
            fail_message = "You need something thin and sturdy to jam the mechanism.",
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_disarmed = true,
                keywords = { add = "disarmed", remove = "spring" },
                categories = { remove = "dangerous", add = "disarmed" },
            },
        },

        -- ── Take club: Detach from spent mechanism ──
        {
            from = "spent", to = "spent", verb = "take",
            aliases = {"grab", "detach", "wrench", "pull"},
            message = "You wrench the oak club free of its iron mount. Heavy. Solid. This would make a decent weapon.",
            mutate = {
                portable = true,
            },
        },
    },

    -- Narration pools for unconscious/wake-up states
    unconscious_narration = {
        periodic = "Ringing. A high, sustained tone, like a struck bell. Your head is a bell. Someone struck it. The tone fades to silence.",
        wake_up = "Your eyes open to stone floor. Your temple throbs with a hot, rhythmic ache. The oak club hangs limply from its iron arm, spent. The trap got you. You sit up slowly, vision swimming.",
    },

    -- Command rejection messages during unconsciousness from this source
    rejection_messages = {
        "Your ears ring. The world is a tone — one long, sustained note.",
        "You hear your own heartbeat, slow and thick. Nothing else.",
        "Movement is a concept you can no longer parse.",
    },

    -- GOAP prerequisites
    prerequisites = {
        step = { warns = { "injury", "concussion", "unconsciousness" } },
        trigger = { warns = { "injury", "concussion", "unconsciousness" } },
        disarm = {
            requires_tool = "thin_tool",
            requires_state = "armed",
        },
        take = {
            requires_state = "spent",
        },
    },

    mutations = {
        take_club = {
            requires_state = "spent",
            message = "You wrench the oak club free of its iron mount. Heavy. Solid. This would make a decent weapon.",
        },
    },
}
