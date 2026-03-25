-- ceiling-collapse.lua — Unstable ceiling: unconsciousness trigger object
-- Decision: D-EFFECTS-PIPELINE, D-CONSC*, D-SELF-INFLICT-CEILING
-- Issue: #162
-- States: unstable → collapsing → collapsed (permanent)
-- MOST DANGEROUS TRIGGER: inflicts concussion + crushing-wound simultaneously
-- Total impact: 10 (concussion) + 15 (crushing) = 25 HP, plus 2/turn bleed during KO
--
-- Effect routing (all paths via effects.process):
--   noise/impact (unstable) → trans.effect → inflict_injury(concussion) + inflict_injury(crushing-wound)
--   self-trigger  (unstable) → trans.effect → same dual injury
--   prop ceiling   (unstable) → prevention path → stabilized, no injury
return {
    guid = "{d82788a7-e34e-4773-bd5b-d1d4a674a20f}",
    template = "furniture",

    id = "unstable-ceiling",
    material = "wood",
    keywords = {"ceiling", "cracks", "sagging ceiling", "unstable ceiling", "cracked ceiling", "timber", "plaster", "beam", "beams", "joists"},
    size = 10,
    weight = 500,
    categories = {"hazard", "dangerous", "environmental", "structural"},
    portable = false,
    room_position = "overhead",

    effects_pipeline = true,

    -- Trap metadata
    is_trap = true,
    is_armed = true,
    is_dangerous = true,
    trap_type = "area-collapse",
    trap_injury_type = "concussion",
    trap_damage_amount = 10,

    -- Unconsciousness metadata
    causes_unconsciousness = true,
    injury_type = "concussion",
    unconscious_severity = "severe",
    unconscious_duration = { min = 12, max = 18 },

    -- Stacking injury metadata — ceiling collapse inflicts TWO injuries
    stacking_injuries = {
        { injury_type = "concussion", severity = "severe", damage = 10, location = "head" },
        { injury_type = "crushing-wound", damage = 15, location = "torso" },
    },

    -- Initial state (unstable)
    name = "a cracked and sagging ceiling",
    description = "The ceiling sags ominously. Deep cracks spider across the plaster between ancient timber beams. Dust sifts down in thin streams. Every footstep sends a tremor through the joists.",
    room_presence = "The ceiling sags dangerously. Cracks web across the plaster. Dust drifts down like slow snow.",
    on_feel = "Grit falls on your fingers when you touch the wall. The timber beams overhead groan softly. The plaster between them is warm — dry rot.",
    on_smell = "Plaster dust. Dry-rotted wood. The stale air of a space that hasn't breathed in decades.",
    on_listen = "A continuous low creaking. The occasional tick of plaster flakes hitting the floor. The ceiling is alive with the sound of slow failure.",
    on_taste = "Plaster dust coats your tongue. Chalky, gritty, unpleasant.",

    location = nil,

    -- FSM
    initial_state = "unstable",
    _state = "unstable",

    states = {
        -- ── UNSTABLE: Ceiling intact but dangerous ──
        unstable = {
            name = "a cracked and sagging ceiling",
            description = "The ceiling sags ominously. Deep cracks spider across the plaster between ancient timber beams. Dust sifts down in thin streams. Every footstep sends a tremor through the joists.",
            room_presence = "The ceiling sags dangerously. Cracks web across the plaster. Dust drifts down like slow snow.",

            on_feel = "Grit falls on your fingers when you touch the wall. The timber beams overhead groan softly. The plaster between them is warm — dry rot.",
            on_smell = "Plaster dust. Dry-rotted wood. The stale air of a space that hasn't breathed in decades.",
            on_listen = "A continuous low creaking. The occasional tick of plaster flakes hitting the floor. The ceiling is alive with the sound of slow failure.",
            on_taste = "Plaster dust coats your tongue. Chalky, gritty, unpleasant.",

            is_dangerous = true,
            is_armed = true,
        },

        -- ── COLLAPSING: Brief transition state, debris raining down ──
        collapsing = {
            name = "a collapsing ceiling",
            description = "The ceiling is coming apart. Timber beams crack and splinter. Plaster erupts in clouds. Chunks of stone and wood rain down.",
            room_presence = "The ceiling is collapsing in a roar of splintering timber and cascading rubble.",

            on_feel = "Chunks of plaster and timber falling around you.",
            on_smell = "Dust. Splintered wood. The sharp smell of freshly broken stone.",
            on_listen = "A deafening roar of cracking timber and falling stone.",
            on_taste = "Dust and blood.",

            is_dangerous = true,
            is_armed = false,
        },

        -- ── COLLAPSED: Rubble everywhere, passage may be blocked ──
        collapsed = {
            name = "a collapsed ceiling",
            description = "Where the ceiling was, there is now open darkness above a heap of rubble. Broken timber beams jut from the wreckage at angles. Plaster dust hangs in the air like fog. The passage is half-blocked by debris.",
            room_presence = "The ceiling has collapsed. Rubble fills half the room — broken timber, plaster chunks, and stone.",

            on_feel = "A heap of broken timber, plaster chunks, and stone rubble. Sharp edges everywhere. Dust coats everything.",
            on_smell = "Plaster dust hangs thick. Dry rot and fresh-broken wood. The air is heavy with debris.",
            on_listen = "The occasional creak as rubble settles. A timber shifts. Then silence.",
            on_taste = "Grit and dust. Your mouth is full of it.",

            is_dangerous = false,
            is_armed = false,
            is_collapsed = true,
        },

        -- ── STABILIZED: Player propped the ceiling before collapse ──
        stabilized = {
            name = "a braced ceiling",
            description = "The sagging ceiling is propped by a makeshift brace. The cracks are still there, the timbers still groan, but something is holding it together — for now.",
            room_presence = "The damaged ceiling is held up by a crude brace. It looks precarious.",

            on_feel = "The brace is under enormous strain. The timbers still creak. This is a temporary measure.",
            on_smell = "Plaster dust, but less of it. The air is slightly clearer.",
            on_listen = "Creaking, but steadier. The brace absorbs the worst of the stress.",
            on_taste = "Dust. Less of it than before.",

            is_dangerous = false,
            is_armed = false,
            is_stabilized = true,
        },
    },

    transitions = {
        -- ── Trigger: Loud noise causes collapse ──
        {
            from = "unstable", to = "collapsing", verb = "shout",
            aliases = {"yell", "scream", "make noise"},
            message = "The sound echoes against the walls — and the ceiling answers. A crack like a gunshot splits the air. Timber groans, plaster erupts, and the world comes apart above you. You throw your arms over your head but it's not enough. Something massive strikes you down.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "severe",
                source = "unstable-ceiling",
                location = "head",
                damage = 10,
                causes_unconsciousness = true,
                unconscious_duration = { min = 12, max = 18 },
                message = "The ceiling collapses on you. Everything goes dark.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "severe", source = "unstable-ceiling", location = "head",
                  damage = 10, causes_unconsciousness = true,
                  unconscious_duration = { min = 12, max = 18 },
                  message = "The ceiling collapses on you. Everything goes dark." },
                { type = "inflict_injury", injury_type = "crushing-wound",
                  source = "unstable-ceiling", location = "torso",
                  damage = 15,
                  message = "Debris crushes your chest. Ribs crack under the weight." },
                { type = "narrate",
                  message = "The sound echoes against the walls — and the ceiling answers. A crack like a gunshot splits the air. Timber groans, plaster erupts, and the world comes apart above you." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
                { type = "mutate", target = "self", field = "is_collapsed", value = true },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_collapsed = true,
                keywords = { add = "rubble", remove = "sagging" },
                categories = { remove = "dangerous", add = "rubble" },
            },
        },

        -- ── Trigger: Physical impact causes collapse ──
        {
            from = "unstable", to = "collapsing", verb = "push",
            aliases = {"hit", "shake", "pull"},
            message = "You shove the timber beam. It shifts. Then everything shifts. The groan becomes a roar. You have a single, brilliant instant of clarity — you just brought the ceiling down on yourself — before the darkness takes you.",
            effect = {
                type = "inflict_injury",
                injury_type = "concussion",
                severity = "severe",
                source = "self-inflicted:unstable-ceiling",
                location = "head",
                damage = 10,
                causes_unconsciousness = true,
                unconscious_duration = { min = 12, max = 18 },
                message = "Timber and plaster crash down on you. Darkness.",
            },
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "concussion",
                  severity = "severe", source = "self-inflicted:unstable-ceiling",
                  location = "head", damage = 10, causes_unconsciousness = true,
                  unconscious_duration = { min = 12, max = 18 },
                  message = "Timber and plaster crash down on you. Darkness." },
                { type = "inflict_injury", injury_type = "crushing-wound",
                  source = "self-inflicted:unstable-ceiling", location = "torso",
                  damage = 15,
                  message = "Rubble pins your chest. Breathing is a labor." },
                { type = "narrate",
                  message = "You shove the timber beam. It shifts. Then everything shifts. The groan becomes a roar. You have a single, brilliant instant of clarity — you just brought the ceiling down on yourself — before the darkness takes you." },
                { type = "mutate", target = "self", field = "is_armed", value = false },
                { type = "mutate", target = "self", field = "is_dangerous", value = false },
                { type = "mutate", target = "self", field = "is_collapsed", value = true },
            },
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_collapsed = true,
                keywords = { add = "rubble", remove = "sagging" },
                categories = { remove = "dangerous", add = "rubble" },
            },
        },

        -- ── Collapsing → Collapsed: Immediate auto-transition ──
        {
            from = "collapsing", to = "collapsed",
            trigger = "auto",
            condition = "immediate",
            message = "",
        },

        -- ── Prevention: Prop/brace the ceiling with a suitable object ──
        {
            from = "unstable", to = "stabilized", verb = "prop",
            aliases = {"brace", "support", "shore up"},
            requires_tool = "structural_support",
            message = "You wedge the support into place beneath the sagging beam. The timber groans, shifts, and settles. The ceiling holds — for now.",
            fail_message = "You need something sturdy to brace the ceiling.",
            mutate = {
                is_armed = false,
                is_dangerous = false,
                is_stabilized = true,
                keywords = { add = "braced", remove = "sagging" },
                categories = { remove = "dangerous", add = "stabilized" },
            },
        },
    },

    -- Narration pools for unconscious/wake-up states
    unconscious_narration = {
        periodic = "Dust. Weight. The taste of blood and plaster. Something presses against your chest. Breathing is a labor. Far away, timber settles with a final, tired creak.",
        wake_up = "You cough yourself awake. Dust fills your lungs. Your body is a map of pain — your head throbs, your ribs scream, and you can barely see through the grit in your eyes. Chunks of plaster and splintered timber surround you. The ceiling is gone. Rubble fills the space where it used to be.",
    },

    -- Command rejection messages during unconsciousness from this source
    rejection_messages = {
        "Weight. Pressure. Your body refuses every signal your brain sends.",
        "You try to move. Pain answers. You stop trying.",
        "Somewhere far away, your fingers twitch. That's all.",
    },

    -- GOAP prerequisites
    prerequisites = {
        shout = { warns = { "injury", "concussion", "crushing-wound", "unconsciousness" } },
        push = { warns = { "injury", "concussion", "crushing-wound", "unconsciousness" } },
        prop = {
            requires_tool = "structural_support",
            requires_state = "unstable",
        },
    },

    mutations = {
        search_rubble = {
            requires_state = "collapsed",
            message = "You dig through the rubble and find...",
        },
    },
}
