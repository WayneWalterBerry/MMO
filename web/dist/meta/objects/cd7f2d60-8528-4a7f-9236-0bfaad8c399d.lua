-- cellar-storage-door-north.lua — Portal object: cellar side of iron-bound storage door
-- Paired with: storage-cellar-door-south.lua (storage side)
-- Replaces: cellar.exits.north (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #201
return {
    guid = "{cd7f2d60-8528-4a7f-9236-0bfaad8c399d}",
    template = "portal",

    id = "cellar-storage-door-north",
    name = "a heavy iron-bound door",
    material = "iron",
    keywords = {"door", "iron door", "heavy door", "iron-bound door",
                "padlock", "locked door", "storage door"},
    size = 6,
    weight = 140,
    portable = false,
    categories = {"architecture", "iron", "portal"},

    portal = {
        target = "storage-cellar",
        bidirectional_id = "{8e968d70-4e29-4eb6-acf5-2bc8b45bd853}",
        direction_hint = "north",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A heavy door of black iron-bound oak stands against the wall. A massive padlock secures it shut. Whatever lies beyond, someone went to great lengths to keep it sealed.",
    room_presence = "A heavy iron-bound door stands against the far wall, secured with a massive padlock.",
    on_examine = "Heavy oak planks, blackened with age, bound by thick iron bands riveted in place. A massive padlock hangs from a thick hasp — the keyhole is small, meant for a brass key. The iron is cold and old, but the lock mechanism looks serviceable. Someone maintained this lock even as everything else decayed.",
    on_feel = "Your hands find cold iron bands wrapped around heavy oak planks. A massive padlock hangs from a thick hasp — the keyhole is small, meant for a brass key. The door does not budge.",
    on_smell = "Cold iron and old oak. From around the edges of the door: drier air, the ghost of old grain, and something sweetly rotten.",
    on_listen = "You press your ear to the oak. From beyond: silence at first, then the faint scratching of something small — rats? The faint creak of shelving under its own weight.",
    on_taste = "Iron and wood. The metallic tang of the padlock stains your tongue.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a padlocked iron-bound door",
            description = "A heavy door of black iron-bound oak, secured with a massive padlock. The keyhole is small — meant for a brass key.",
            room_presence = "A heavy iron-bound door is secured with a massive padlock.",
            on_examine = "The padlock is heavy iron, well-maintained. The keyhole is small — a brass key, not iron. The door doesn't budge.",
            on_feel = "Cold iron bands, heavy oak. The padlock: cold, heavy, its keyhole small and precise. The door is immovable.",
            on_smell = "Iron and oak. Drier air seeps from beyond — old grain, decay.",
            on_listen = "Faint scratching from beyond the door. Rats in the storage cellar.",
        },

        closed = {
            traversable = false,
            name = "an unlocked iron-bound door",
            description = "The heavy iron-bound door stands unlocked. The padlock hangs open from the hasp.",
            room_presence = "The heavy iron-bound door stands with its padlock hanging open.",
            on_examine = "The padlock hangs open, its hasp pulled aside. The door is closed but no longer secured. A push would open it.",
            on_feel = "The door shifts slightly — no longer held by the lock. The padlock hangs loose. A push would open it.",
            on_smell = "Drier air seeps more freely around the unsealed edges. Old grain and something rotten.",
            on_listen = "The scratching from beyond is clearer now. Definitely rats.",
        },

        open = {
            traversable = true,
            name = "an open iron-bound door",
            description = "The heavy iron-bound door stands open, revealing a dark passage leading into deeper darkness.",
            room_presence = "The heavy iron-bound door stands open, revealing a dark storage vault beyond.",
            on_examine = "The door is open on heavy iron hinges. Beyond: a long, narrow vault with sagging shelves, dust, and the smell of old grain. Something skitters away from the light.",
            on_feel = "The open door edge, cold iron. Drier air drifts through from the vault beyond. The hinges are massive and well-oiled — this door was built to last.",
            on_smell = "Old grain, wood rot, and the sweet-sour tang of long-rotted provisions pour from the vault beyond.",
            on_listen = "Rats scatter in the darkness beyond. The creak of old shelving. Your footsteps echo differently — the space beyond is larger.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            requires_tool = "brass-key",
            message = "The brass key slides into the padlock with a precise click. You turn it — the mechanism resists, then yields with a grinding clank. The padlock falls open.",
            mutate = {
                keywords = { add = "unlocked", remove = {"locked", "padlock"} },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push"},
            message = "You push the heavy door. It swings open with a long, low groan of iron hinges, revealing darkness beyond.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You push the heavy door shut. It closes with a deep, resonant thud that echoes through the cellar.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            requires_tool = "brass-key",
            message = "You snap the padlock shut. The mechanism clicks with a cold finality.",
            mutate = {
                keywords = { add = {"locked", "padlock"}, remove = "unlocked" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
