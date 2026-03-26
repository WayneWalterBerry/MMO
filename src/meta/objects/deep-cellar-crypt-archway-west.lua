-- deep-cellar-crypt-archway-west.lua — Portal object: deep cellar side of crypt archway
-- Paired with: crypt-deep-cellar-archway-east.lua (crypt side)
-- Replaces: deep-cellar.exits.west (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #204
return {
    guid = "{8be0ec4e-f5a2-4538-8e9e-2893264a50c5}",
    template = "portal",

    id = "deep-cellar-crypt-archway-west",
    name = "a stone archway with an iron gate",
    material = "iron",
    keywords = {"archway", "arch", "gate", "iron gate", "crypt",
                "passage", "silver padlock", "padlock"},
    size = 6,
    weight = 200,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "crypt",
        bidirectional_id = "{42345886-9154-4147-8306-2a71c19cf102}",
        direction_hint = "west",
    },

    max_carry_size = 3,
    max_carry_weight = 30,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A stone archway is set into the wall, its rounded top carved with symbols that match those on the altar. An iron gate blocks the passage, secured with a silver padlock that gleams dully in the light.",
    room_presence = "A stone archway with a locked iron gate leads deeper into the rock. Carved symbols frame the entrance.",
    on_examine = "A rounded stone archway, carved with the same symbols you see on the altar — repeating patterns of interlocking circles and angular script. An iron gate of closely spaced bars blocks the passage. A silver padlock — small, finely made, utterly unlike the crude iron locks above — secures the gate. Through the bars, worn stone steps descend into profound darkness.",
    on_feel = "Iron bars, closely spaced, cold to the touch. A padlock — small, silver, finely made, unlike the crude iron locks above. The bars are solid; this gate was built to last. Through the gaps, you feel colder air and smell something older — dust and dry stone.",
    on_smell = "Through the gate: drier, colder air. Mineral dust, ancient stone, and the faintest trace of something sweet — old wax from candles burned centuries ago. The air beyond is perfectly still.",
    on_listen = "Silence beyond the gate. Not the cellar's damp silence, but something more complete — the silence of a sealed space, undisturbed for ages. Your breathing echoes faintly off the iron bars.",
    on_taste = "You lick the iron bars. Cold metal, old rust. The silver padlock tastes different — cleaner, sharper, the metal better preserved.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a locked iron gate in a stone archway",
            description = "An iron gate in a stone archway, secured with a silver padlock. Through the bars, stone steps descend into darkness.",
            room_presence = "A stone archway with a locked iron gate leads deeper into the rock. A silver padlock gleams on the hasp.",
            on_examine = "The silver padlock is finely crafted. The keyhole is precise — this lock was made by a skilled smith. A silver key would fit.",
            on_feel = "Iron bars, cold and solid. The silver padlock: smooth, well-made, its keyhole precise.",
            on_smell = "Ancient dust and cold stone from beyond the gate.",
            on_listen = "Profound silence from beyond. The sealed space swallows sound.",
        },

        closed = {
            traversable = false,
            name = "an unlocked iron gate",
            description = "The iron gate stands unlocked. The silver padlock hangs loose from the hasp.",
            room_presence = "The stone archway's iron gate is unlocked. The silver padlock hangs open.",
            on_examine = "The silver padlock hangs open from the hasp. The gate is closed but no longer secured. A push would open it.",
            on_feel = "The gate shifts on its hinges. The padlock hangs loose. A push would swing it open.",
            on_smell = "More of the ancient stillness seeps through — dust, dry stone, old wax.",
            on_listen = "A breath of cold, ancient air seeps through the unlocked gate.",
        },

        open = {
            traversable = true,
            name = "an open iron gate in a stone archway",
            description = "The iron gate stands open in the stone archway. Beyond it, worn stone steps descend into a narrow passage leading into profound darkness.",
            room_presence = "The iron gate stands open in the stone archway. Stone steps descend into darkness beyond.",
            on_examine = "The gate stands open on silent hinges — oiled once, long ago, and preserved by the dry air. Beyond: worn stone steps descending into a narrow passage. The cold, still air of the crypt washes over you.",
            on_feel = "The open gate, iron bars warm where your hand rested. Beyond: colder air, drier air, the stillness of a sealed tomb.",
            on_smell = "Ancient dust, old wax, dry stone. The smell of a place undisturbed for centuries pours through the open gate.",
            on_listen = "The silence beyond is total. It presses against you like something physical.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            requires_tool = "silver-key",
            message = "The silver key slips into the padlock with a precise click. The mechanism turns smoothly — finely made, even after centuries. The padlock falls open.",
            mutate = {
                keywords = { add = "unlocked", remove = {"locked", "silver padlock"} },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push", "swing"},
            message = "The gate swings open on silent hinges — oiled once, long ago, and preserved by the dry air. A breath of cold, ancient stillness washes over you from the passage beyond.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You push the gate shut. It closes with a soft, precise click.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            requires_tool = "silver-key",
            message = "The silver key turns the padlock shut with a smooth, quiet click. Sealed again.",
            mutate = {
                keywords = { add = {"locked", "silver padlock"}, remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
