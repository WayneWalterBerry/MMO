-- storage-deep-cellar-door-north.lua — Portal object: storage side of deep cellar door
-- Paired with: deep-cellar-storage-door-south.lua (deep cellar side)
-- Replaces: storage-cellar.exits.north (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #202
return {
    guid = "{f7c36726-24ef-427d-bcb5-267cab725982}",
    template = "portal",

    id = "storage-deep-cellar-door-north",
    name = "the black iron door",
    material = "iron",
    keywords = {"door", "black iron door", "black door", "second door",
                "north door", "deep cellar door"},
    size = 6,
    weight = 150,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "deep-cellar",
        bidirectional_id = "{00214e5f-c743-4fcb-8fef-a00ba4c0a444}",
        direction_hint = "north",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A black iron door blocks the far end of the vault. Heavier and older than the iron-bound door behind you, with a lock plate of black iron. A large keyhole waits, dark and empty.",
    room_presence = "A black iron door blocks the far end of the vault, its lock plate staring like an empty eye.",
    on_examine = "Heavier and older than the iron-bound door behind you. The oak is nearly black with age, and the iron bands are thicker, more crudely forged — older work. A lock plate of black iron bears a large keyhole — meant for an iron key, not the delicate brass one. The door does not yield to pushing.",
    on_feel = "Cold black iron over ancient oak. Heavier than the door behind you. The keyhole is large — meant for an iron key, not the delicate brass one. The door does not yield to pushing.",
    on_smell = "Old iron and ancient oak. From beyond the door: drier air, colder, carrying the ghost of incense and old wax.",
    on_listen = "Silence from beyond. A deeper, more profound silence than the cellar behind you — as if the space beyond absorbs sound. No rats. No dripping.",
    on_taste = "Iron and ancient oak. The metal tastes older, cruder than the padlock on the other door.",

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        on_traverse = "door-groan-iron.opus",
        on_verb_open = "door-open-iron.opus",
        on_verb_close = "door-close-iron.opus",
        on_verb_unlock = "lock-grind-iron.opus",
        on_verb_lock = "lock-grind-iron.opus",
    },

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a locked black iron door",
            description = "A heavy black iron door, older and heavier than the first. A black iron lock plate with a large keyhole — meant for an iron key.",
            room_presence = "A heavy black iron door blocks the far end of the vault, locked tight. Its keyhole stares darkly.",
            on_examine = "The lock plate is black iron, the keyhole large. An iron key would fit. The door is immovable.",
            on_feel = "Cold, heavy iron. The keyhole is large — an iron key, not brass. The door does not budge.",
            on_smell = "Iron and ancient oak. The faintest breath of incense from beyond.",
            on_listen = "Silence from beyond. Deep, absorbed silence.",
        },

        closed = {
            traversable = false,
            name = "an unlocked black iron door",
            description = "The black iron door stands unlocked, its heavy lock plate hanging loose.",
            room_presence = "The heavy black iron door to the deep cellar stands unlocked.",
            on_examine = "The lock plate hangs loose — the iron key turned it. The door is heavy but free. A push would open it.",
            on_feel = "The door shifts — barely — in its frame. No longer locked, but heavy. It would take effort to open.",
            on_smell = "More of the ancient incense scent seeps through. Wax and dust.",
            on_listen = "The silence beyond is louder now, pressing against the unlocked door.",
        },

        open = {
            traversable = true,
            name = "an open black iron door",
            description = "The black iron door stands open, revealing a passage into older, darker stone beyond.",
            room_presence = "The black iron door stands open, revealing worked limestone and vaulted darkness beyond.",
            on_examine = "The door stands wide on massive hinges. Beyond: the architecture changes completely. Rough granite gives way to precisely fitted limestone. A vaulted ceiling rises into shadow. You smell incense and ancient dust.",
            on_feel = "The open door edge. Beyond: colder, drier air. The stone changes — smooth limestone instead of rough granite.",
            on_smell = "Incense and ancient dust pour through the opening. Wax and mineral dust. The smell of a place built for reverence.",
            on_listen = "The silence beyond is immense. Your breathing sounds muffled. The room absorbs sound.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            requires_tool = "iron-key",
            message = "The iron key turns with a grinding reluctance, and the lock plate falls open with a heavy clank.",
            mutate = {
                keywords = { add = "unlocked", remove = "locked" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push"},
            message = "You put your shoulder to the door. It yields slowly, grinding against the flagstones, and swings open into darkness.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You heave the door shut. It closes with a boom that echoes through the vault.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            requires_tool = "iron-key",
            message = "You turn the iron key. The lock engages with a heavy, final sound.",
            mutate = {
                keywords = { add = "locked", remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
