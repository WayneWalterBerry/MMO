-- poison-gas-vent.lua — Poison gas vent: unconsciousness trigger object
-- Decision: D-EFFECTS-PIPELINE, D-CONSC*, D-SELF-INFLICT-CEILING
-- Issue: #162
-- States: leaking → active → leaking (RESETS! — creates room-escape puzzle)
-- Also: leaking → plugged (prevention path with cloth)
-- Minor severity, short KO (3-5 turns), but repeatable
--
-- Effect routing (all paths via effects.process):
--   timed exposure (leaking) → trans.effect → inflict_injury(concussion, severity=minor)
--   breathe gas    (leaking) → trans.effect → inflict_injury(concussion, severity=minor)
--   plug pipe      (leaking) → prevention   → plugged, no injury
return {
    guid = "{ac7ca377-d585-4d22-bcfa-4fc40094e4c2}",
    template = "furniture",

    id = "poison-gas-vent",
    material = "iron",
    keywords = {"vent", "pipe", "gas", "poison gas", "crack", "cracked pipe", "gas vent", "fumes"},
    size = 3,
    weight = 50,
    categories = {"hazard", "dangerous", "chemical", "metal", "mechanism"},
    portable = false,
    room_position = "protruding from the wall near the floor",

    effects_pipeline = true,

    -- Trap metadata
    is_trap = true,
    is_armed = true,
    is_dangerous = true,
    trap_type = "chemical-exposure",
    trap_injury_type = "concussion",
    trap_damage_amount = 2,

    -- Unconsciousness metadata
    causes_unconsciousness = true,
    injury_type = "concussion",
    unconscious_severity = "minor",
    unconscious_duration = { min = 3, max = 5 },

    -- Gas exposure timing (turns before auto-trigger)
    gas_exposure_turns = 3,

    -- Initial state (leaking)
    name = "a cracked vent pipe",
    description = "A corroded iron pipe protrudes from the wall near the floor, cracked along its length. A faint, sweetish haze seeps from the fracture. The air near it shimmers.",
    room_presence = "A cracked iron pipe near the floor seeps a faint, sweetish haze.",
    on_feel = "The pipe is cold iron, rough with corrosion. Your fingers come away with a faint oily residue. The air around it feels heavier than it should.",
    on_smell = "Sweet. Cloying. Like overripe fruit left in a closed room. Your head swims after a few breaths.",
    on_listen = "A thin, continuous hiss. Gas escaping under pressure.",
    on_taste = "The air tastes sweet and thick. Immediately wrong. Your tongue goes numb.",

    location = nil,

    -- FSM
    initial_state = "leaking",
    _state = "leaking",

    states = {
        -- ── LEAKING: Gas seeps out, low concentration, warning signs ──
        leaking = {
            name = "a cracked vent pipe",
            description = "A corroded iron pipe protrudes from the wall near the floor, cracked along its length. A faint, sweetish haze seeps from the fracture. The air near it shimmers.",
            room_presence = "A cracked iron pipe near the floor seeps a faint, sweetish haze.",

            on_feel = "The pipe is cold iron, rough with corrosion. Your fingers come away with a faint oily residue. The air around it feels heavier than it should.",
            on_smell = "Sweet. Cloying. Like overripe fruit left in a closed room. Your head swims after a few breaths.",
            on_listen = "A thin, continuous hiss. Gas escaping under pressure.",
            on_taste = "The air tastes sweet and thick. Immediately wrong. Your tongue goes numb.",

            is_dangerous = true,
            is_armed = true,

            -- Room-entry warning text
            room_entry_message = "The air is thick here. A sweetish smell hangs low, almost pleasant — almost. Something about it makes your head feel light.",

            -- Escalation warning (after 2 turns)
            escalation_message = "The sweet smell is stronger. Your thoughts are moving slower. You should leave. You really should leave.",

            -- Auto-trigger after N turns of exposure
            timed_events = {
                { event = "transition", delay = 1080, to_state = "active" },
                -- 1080 seconds = 3 turns exposure before auto-trigger
            },
        },

        -- ── ACTIVE: Gas concentration critical, player affected ──
        active = {
            name = "a cracked vent pipe",
            description = "The air is thick with a sweet, cloying haze. The cracked pipe hisses steadily. Your vision swims. Your limbs are heavy.",
            room_presence = "The cracked pipe hisses. The air shimmers with a thick, sweet haze.",

            on_feel = "Your limbs are heavy. Vision blurs. The sweet smell is overwhelming.",
            on_smell = "Overwhelming sweetness. Your head is cotton wool.",
            on_listen = "The hiss of the pipe. Your own slow breathing. Nothing else.",
            on_taste = "Sweetness fills your mouth. Your tongue is numb.",

            is_dangerous = true,
            is_armed = true,
        },

        -- ── PLUGGED: Player blocked the vent ──
        plugged = {
            name = "a plugged vent pipe",
            description = "A wad of cloth is stuffed tightly into the cracked pipe. The hissing has stopped. The air is clearing, though a faint sweetness lingers.",
            room_presence = "A cracked iron pipe near the floor has been plugged with cloth. The air is clearing.",

            on_feel = "A wad of cloth stuffed into the cracked pipe. The hissing has stopped. The pipe is cold and still.",
            on_smell = "A fading sweetness. The air is clearing slowly.",
            on_listen = "Silence. The hissing has stopped completely.",
            on_taste = "The air tastes cleaner. The numbness is fading.",

            is_dangerous = false,
            is_armed = false,
            is_plugged = true,
        },
    },

    transitions = {
        -- ── Trigger: Timed exposure (gas overwhelms player) ──
        {
            from = "leaking", to = "active", verb = "wait",
            aliases = {"stay"},
            message = "The room sways. Your knees buckle. The sweet smell fills your skull like cotton wool, pushing everything else out — your name, your purpose, the floor rising to meet your face. Then nothing.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "minor",
                source = "poison-gas-vent",
                location = "head",
                damage = 2,
                causes_unconsciousness = true,
                unconscious_duration = { min = 3, max = 5 },
                message = "The gas overwhelms you. Consciousness dissolves.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "minor", source = "poison-gas-vent", location = "head",
                  damage = 2, causes_unconsciousness = true,
                  unconscious_duration = { min = 3, max = 5 },
                  message = "The gas overwhelms you. Consciousness dissolves." },
                { type = "narrate",
                  message = "The room sways. Your knees buckle. The sweet smell fills your skull like cotton wool, pushing everything else out — your name, your purpose, the floor rising to meet your face. Then nothing." },
            },
            mutate = {},
        },

        -- ── Self-infliction: Breathe deeply / inhale fumes ──
        {
            from = "leaking", to = "active", verb = "breathe",
            aliases = {"inhale", "breathe deeply", "inhale fumes", "sniff gas", "breathe gas"},
            message = "You lean toward the cracked pipe and breathe deeply. The sweetness floods your lungs, rich and heavy. Your vision narrows to a pinpoint. A distant voice in your head says this was idiotic. The voice is correct. Darkness.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "minor",
                source = "self-inflicted:poison-gas-vent",
                location = "head",
                damage = 2,
                causes_unconsciousness = true,
                unconscious_duration = { min = 3, max = 5 },
                message = "The gas floods your lungs. The world dissolves.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "minor", source = "self-inflicted:poison-gas-vent",
                  location = "head", damage = 2, causes_unconsciousness = true,
                  unconscious_duration = { min = 3, max = 5 },
                  message = "The gas floods your lungs. The world dissolves." },
                { type = "narrate",
                  message = "You lean toward the cracked pipe and breathe deeply. The sweetness floods your lungs, rich and heavy. Your vision narrows to a pinpoint. A distant voice in your head says this was idiotic. The voice is correct. Darkness." },
            },
            mutate = {},
        },

        -- ── Reset: Active → Leaking (trap resets after player wakes!) ──
        {
            from = "active", to = "leaking",
            trigger = "auto",
            condition = "player_wakes",
            message = "The gas continues to seep from the cracked pipe. The air is building again.",
            mutate = {
                is_armed = true,
                is_dangerous = true,
            },
        },

        -- ── Prevention: Plug the vent with cloth ──
        {
            from = "leaking", to = "plugged", verb = "plug",
            aliases = {"stuff", "block", "seal"},
            requires_tool = "cloth",
            message = "You stuff the cloth into the crack. The hissing stops. The air begins to clear.",
            fail_message = "You need something to stuff into the crack — cloth, a rag, something flexible.",
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_plugged = true,
                keywords = { add = "plugged", remove = "cracked" },
                categories = { remove = "dangerous", add = "disabled" },
            },
        },

        -- ── Unplug: Return to leaking state ──
        {
            from = "plugged", to = "leaking", verb = "unplug",
            aliases = {"remove cloth", "pull cloth", "unstuff"},
            message = "You pull the cloth free. The hissing resumes immediately. The sweet smell creeps back.",
            mutate = {
                is_armed = true,
                is_dangerous = true,
                is_plugged = false,
                keywords = { add = "cracked", remove = "plugged" },
                categories = { add = "dangerous", remove = "disabled" },
            },
        },
    },

    -- Narration pools for unconscious/wake-up states
    unconscious_narration = {
        periodic = "Sweet nothing. A chemical dreamlessness, empty as glass. Time passes without you.",
        wake_up = "You gasp awake, lungs burning. The sweet taste coats your throat. Your head aches — a chemical headache, sharp and thin. The air is still heavy. You need to move.",
    },

    -- Command rejection messages during unconsciousness from this source
    rejection_messages = {
        "The sweetness won't let go. Your thoughts dissolve before they form.",
        "You try to think. The thought has no edges. It melts.",
        "Breathing. That's all you manage. In. Out. The sweet air fills you.",
    },

    -- GOAP prerequisites
    prerequisites = {
        breathe = { warns = { "injury", "concussion", "unconsciousness" } },
        plug = {
            requires_tool = "cloth",
            requires_state = "leaking",
        },
    },

    mutations = {
        plug = {
            becomes = "poison-gas-vent-plugged",
            message = "You stuff the cloth into the crack. The hissing stops. The air begins to clear.",
        },
        unplug = {
            becomes = "poison-gas-vent",
            message = "You pull the cloth free. The hissing resumes immediately. The sweet smell creeps back.",
        },
    },
}
