-- deep-cellar-storage-door-south.lua — Portal object: deep cellar side of storage door
-- Paired with: storage-deep-cellar-door-north.lua (storage side)
-- Replaces: deep-cellar.exits.south (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #202
return {
    guid = "{3f4dbb18-131f-46f6-83d5-99aa5b4eb98f}",
    template = "portal",

    id = "deep-cellar-storage-door-south",
    name = "the iron door",
    material = "iron",
    keywords = {"door", "iron door", "iron-bound door", "south door",
                "heavy door", "storage door"},
    size = 6,
    weight = 150,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "storage-cellar",
        bidirectional_id = "{00214e5f-c743-4fcb-8fef-a00ba4c0a444}",
        direction_hint = "south",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "The iron door stands open behind you, leading back to the narrow storage vault.",
    room_presence = "The iron-bound door leads back to the storage vault.",
    on_examine = "The same iron-bound door, seen from the deep cellar side. Heavy oak and iron, framed in limestone instead of granite. The lock plate and keyhole are on the storage side.",
    on_feel = "Heavy oak planks, thick iron bands. From this side the lock plate is unreachable — smooth oak and cold iron. The door is thick and solid.",
    on_smell = "From beyond the door: old grain, wood rot, the stale air of the storage vault. On this side: incense, ancient dust, cold limestone.",
    on_listen = "From beyond: the faint scratching of rats in the storage vault. On this side: the deep silence of the vaulted chamber.",
    on_taste = "Iron and old oak. The same ancient taste.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a locked iron door",
            description = "The iron door is shut, locked from the storage side. The lock plate is on the other face.",
            room_presence = "The iron-bound door is shut tight, locked from the other side.",
            on_examine = "Locked from the storage side. The keyhole is on the other face of the door.",
            on_feel = "Heavy oak and iron. The door does not budge. The lock is on the other side.",
            on_smell = "Old grain and wood rot seep from beyond. Locked and sealed.",
            on_listen = "Rats scratch faintly in the storage vault beyond.",
        },

        closed = {
            traversable = false,
            name = "a closed iron door",
            description = "The iron door is shut, cutting off the storage vault behind you.",
            room_presence = "The iron-bound door to the storage vault is closed.",
            on_examine = "The door is closed but unlocked. A push would open it.",
            on_feel = "The door shifts — heavy, but free. Not locked.",
            on_smell = "Old grain seeps around the edges.",
            on_listen = "Faint scratching from the storage vault. The door rattles in its frame.",
        },

        open = {
            traversable = true,
            name = "an open iron door",
            description = "The iron door stands open, leading back to the narrow storage vault.",
            room_presence = "The iron-bound door stands open to the storage vault beyond.",
            on_examine = "The door stands open on massive hinges. Beyond: the long, narrow storage vault with its sagging shelves and the smell of old grain.",
            on_feel = "The open door edge. Warmer, staler air drifts in from the storage vault.",
            on_smell = "Old grain, wood rot, and the sweet tang of decay from the vault.",
            on_listen = "Rats and creaking shelves in the storage vault beyond.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            message = "You hear the lock clank open from the storage side. The door is free.",
            mutate = {
                keywords = { add = "unlocked", remove = "locked" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push"},
            message = "The door groans open, and a faint draught of warmer air drifts in from the storage vault.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You push the heavy door shut. It booms closed, and the echoes take a long time to die in this vaulted space.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            message = "The lock engages from the storage side with a heavy clank.",
            mutate = {
                keywords = { add = "locked", remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
