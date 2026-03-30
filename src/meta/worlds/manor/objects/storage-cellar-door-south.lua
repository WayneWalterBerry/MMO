-- storage-cellar-door-south.lua — Portal object: storage side of iron-bound cellar door
-- Paired with: cellar-storage-door-north.lua (cellar side)
-- Replaces: storage-cellar.exits.south (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #201
return {
    guid = "{ed35641e-4106-421f-bcd4-2d6654c8ed1b}",
    template = "portal",

    id = "storage-cellar-door-south",
    name = "the iron-bound door",
    material = "iron",
    keywords = {"door", "iron door", "iron-bound door", "south door",
                "heavy door", "cellar door"},
    size = 6,
    weight = 140,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "cellar",
        bidirectional_id = "{8e968d70-4e29-4eb6-acf5-2bc8b45bd853}",
        direction_hint = "south",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "The heavy iron-bound door stands open behind you, revealing the cellar stairway beyond.",
    room_presence = "The heavy iron-bound door leads back to the cellar.",
    on_examine = "The same heavy oak-and-iron door, seen from the storage side. The padlock and hasp are on the cellar side — from here, the door has no lock, just heavy iron hinges. It can be pushed shut or pulled open.",
    on_feel = "Heavy oak planks, iron bands, massive hinges. The door is thick and solid. From this side there is no lock — just smooth oak and cold iron.",
    on_smell = "The cellar beyond: damp earth, cold stone, the metallic tang of dripping water. Behind you: old grain and wood rot.",
    on_listen = "From beyond the door: the drip of water in the cellar. The cellar's cold emptiness hums with the silence of stone.",
    on_taste = "Iron and old oak. The same gritty taste from either side.",

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        on_traverse = "door-groan-iron.opus",
        on_verb_open = "door-open-iron.opus",
        on_verb_close = "door-close-iron.opus",
    },

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a padlocked iron-bound door",
            description = "The heavy iron-bound door is shut and padlocked from the cellar side. From here, there is no way to unlock it.",
            room_presence = "The heavy iron-bound door is shut tight, padlocked from the other side.",
            on_examine = "Locked from the cellar side. The padlock hasp is on the other face of the door — unreachable from here.",
            on_feel = "Heavy oak, cold iron. The door does not budge. The lock is on the other side.",
            on_smell = "Damp earth and cold stone from the cellar beyond.",
            on_listen = "Water dripping in the cellar beyond. The door is sealed.",
        },

        closed = {
            traversable = false,
            name = "a closed iron-bound door",
            description = "The heavy iron-bound door is shut, its iron bands dark against the oak.",
            room_presence = "The heavy iron-bound door to the cellar is closed.",
            on_examine = "The door is closed but no longer locked. A push or pull would open it.",
            on_feel = "The door shifts slightly in its frame. Not locked — just heavy.",
            on_smell = "Cold cellar air seeps around the edges.",
            on_listen = "Water drips in the cellar beyond. The door rattles faintly.",
        },

        open = {
            traversable = true,
            name = "an open iron-bound door",
            description = "The heavy iron-bound door stands open, revealing the cellar stairway beyond.",
            room_presence = "The heavy iron-bound door stands open to the cellar beyond.",
            on_examine = "The door stands open on massive iron hinges. Beyond: the cold, damp cellar and the stairway up to the bedroom.",
            on_feel = "The open door edge, cold iron. Damp cellar air drifts through.",
            on_smell = "Damp earth and cold stone pour through the open doorway.",
            on_listen = "Water drips echo from the cellar beyond. Cold air moves through the opening.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            message = "You hear the padlock clank open from the other side. The door is free.",
            mutate = {
                keywords = { add = "unlocked", remove = "locked" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"pull", "push"},
            message = "The door groans open on protesting hinges.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You push the heavy door shut. It closes with a deep, resonant thud.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            message = "The padlock clicks shut from the cellar side.",
            mutate = {
                keywords = { add = "locked", remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
