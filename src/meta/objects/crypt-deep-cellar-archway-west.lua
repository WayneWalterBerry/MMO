-- crypt-deep-cellar-archway-west.lua — Portal object: crypt side of deep cellar archway
-- Paired with: deep-cellar-crypt-archway-west.lua (deep cellar side)
-- Replaces: crypt.exits.west (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #204
return {
    guid = "{d9124959-350d-4172-9844-d6d390461dd5}",
    template = "portal",

    id = "crypt-deep-cellar-archway-west",
    name = "the stone archway",
    material = "iron",
    keywords = {"archway", "arch", "gate", "exit", "passage",
                "way out", "iron gate"},
    size = 6,
    weight = 200,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "deep-cellar",
        bidirectional_id = "{42345886-9154-4147-8306-2a71c19cf102}",
        direction_hint = "west",
    },

    max_carry_size = 3,
    max_carry_weight = 30,
    requires_hands_free = false,
    player_max_size = 5,

    description = "The stone archway leads back to the deep cellar. The iron gate stands open, its silver padlock hanging loose. Beyond it, the vaulted chamber with its altar and stairway waits.",
    room_presence = "The stone archway leads back toward the deep cellar. The iron gate stands open.",
    on_examine = "The same stone archway, seen from the crypt side. Worn stone steps ascend through the narrow passage back to the vaulted chamber. The iron gate stands open. Through it, you can see the deep cellar — the altar, the sconces, the stairway leading up to the manor. The symbols carved into the archway are the same from both sides — interlocking circles, angular script, endlessly repeating.",
    on_feel = "Iron bars, stone archway. The gate stands open. Through it: the slightly warmer air of the deep cellar. The steps ascend — each one worn smooth, ancient, patient.",
    on_smell = "Through the archway: the deep cellar's incense and limestone. Behind you: the crypt's utter stillness — dust, dry stone, old wax.",
    on_listen = "From beyond the archway: the deep cellar's absorbed silence. Not quite as total as the crypt's — there's the faintest whisper of air moving through the stairwell above.",
    on_taste = "Ancient dust. The air is so dry it tastes of mineral — limestone, quartz, the ghost of ages.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a locked iron gate",
            description = "The iron gate is shut and locked. The silver padlock gleams on the hasp. No escape this way.",
            room_presence = "The iron gate in the stone archway is locked. The silver padlock gleams.",
            on_examine = "Locked from the deep cellar side. The padlock hasp is accessible, but you'd need the silver key.",
            on_feel = "Iron bars, cold and solid. The silver padlock: precise, unyielding.",
            on_listen = "Silence from the deep cellar beyond. The gate is sealed.",
        },

        closed = {
            traversable = false,
            name = "an unlocked iron gate",
            description = "The iron gate is closed. The silver padlock hangs open from the hasp.",
            room_presence = "The iron gate in the archway is closed but unlocked.",
            on_examine = "The padlock is open. The gate could be pushed open.",
            on_feel = "The gate shifts on its hinges. Not locked.",
            on_listen = "A breath of air from the deep cellar beyond.",
        },

        open = {
            traversable = true,
            name = "an open iron gate",
            description = "The iron gate stands open. Beyond the stone archway, worn steps ascend to the vaulted deep cellar.",
            room_presence = "The iron gate stands open in the stone archway, leading back to the deep cellar.",
            on_examine = "The gate is open. Stone steps ascend through the narrow passage to the deep cellar with its altar and stairway.",
            on_feel = "The open gate. Slightly warmer air from the deep cellar drifts through.",
            on_listen = "From beyond: the deep cellar's silence, and the faintest whisper of air from the stairwell above.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            requires_tool = "silver-key",
            message = "The silver key turns the padlock with a smooth click. It falls open.",
            mutate = {
                keywords = { add = "unlocked", remove = "locked" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push", "swing"},
            message = "The gate swings open silently. The deep cellar waits beyond.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You push the gate shut. It clicks closed.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            requires_tool = "silver-key",
            message = "The silver key locks the padlock with a quiet click.",
            mutate = {
                keywords = { add = "locked", remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
