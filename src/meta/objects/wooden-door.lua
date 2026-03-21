-- wooden-door.lua — FSM-managed door (Courtyard to manor interior)
-- States: locked → unlocked → open
return {
    guid = "68epu38b-f906-4319-5c2c-7e6a4f234567",
    template = "furniture",

    id = "wooden-door",
    material = "oak",
    keywords = {"door", "wooden door", "kitchen door", "servants door", "back door"},
    size = 6,
    categories = {"architecture", "wooden"},
    portable = false,

    name = "a heavy wooden door",
    description = "A heavy wooden door set into the manor's ground-floor wall. Iron bands cross it, and a large iron latch holds it shut. The lock is a simple keyhole type -- but you don't have the key. Through the gaps, you smell cooking fires and stale food.",
    room_presence = "A heavy wooden door is set into the north wall, leading into the manor.",
    on_feel = "Heavy oak planks, iron bands. The latch doesn't move -- locked. A keyhole, large and simple. Cold iron.",
    on_smell = "Through the gaps: old cooking smoke, stale bread, grease. A kitchen?",
    on_listen = "Silence beyond. No one home.",

    location = nil,

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            name = "a heavy wooden door",
            description = "A heavy wooden door set into the manor's ground-floor wall. Iron bands cross it, and a large iron latch holds it shut. The lock is a simple keyhole type -- but you don't have the key. Through the gaps, you smell cooking fires and stale food.",
            room_presence = "A heavy wooden door is set into the north wall, leading into the manor.",
            on_feel = "Heavy oak planks, iron bands. The latch doesn't move -- locked. A keyhole, large and simple. Cold iron.",
            on_smell = "Through the gaps: old cooking smoke, stale bread, grease. A kitchen?",
            on_listen = "Silence beyond. No one home.",
        },

        unlocked = {
            name = "an unlocked wooden door",
            description = "The door's latch lifts freely now. Push to open.",
            on_feel = "The latch moves. The door shifts in its frame.",
            on_smell = "Same kitchen smells, stronger.",
            on_listen = "A creak from the hinges.",
        },

        open = {
            name = "an open wooden door",
            description = "The door stands open, revealing a dark corridor leading into the manor's service areas. Cold air drifts through.",
            on_feel = "The door is ajar. Beyond: stone floor, cooler air.",
            on_smell = "Kitchen smells: stale food, cold hearth, old grease.",
            on_listen = "Distant dripping. The manor's plumbing.",
        },
    },

    transitions = {
        {
            from = "locked", to = "unlocked", verb = "unlock",
            message = "The lock clicks and the latch frees. The door is unlocked.",
            fail_message = "The door is locked. These iron bands are serious. You'd need something stronger -- or the right key.",
            mutate = {
                keywords = { add = "unlocked" },
            },
        },
        {
            from = "unlocked", to = "open", verb = "open",
            aliases = {"push"},
            message = "You push the door open. It swings inward with a long groan, revealing a dark corridor. The smell of a cold kitchen drifts out.",
            mutate = {
                keywords = { add = "open" },
            },
        },
    },

    mutations = {},
}
