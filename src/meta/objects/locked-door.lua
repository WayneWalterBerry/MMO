-- locked-door.lua — Level 2 boundary (Hallway, single-state in Level 1)
return {
    guid = "{0ddcb6f6-6514-4001-b904-c91938c8488b}",
    template = "furniture",

    id = "locked-door",
    material = "oak",
    keywords = {"door", "locked door", "oak door", "wooden door", "side door"},
    size = 6,
    categories = {"architecture", "wooden"},
    portable = false,

    name = "a locked oak door",
    description = "A heavy oak door with iron bands and a large keyhole. It doesn't budge when you push. A brass plate above the handle reads a room name. Beyond this door lies the rest of the manor -- but not today.",
    room_presence = "Oak doors with brass plates line the hallway -- all locked.",
    on_feel = "Heavy oak, iron bands crossing the surface. The handle turns but the bolt holds fast. A large keyhole -- you can feel the lock mechanism.",
    on_smell = "Oak and iron. Faint traces from beyond.",
    on_listen = "Nothing from the other side. Or -- is that the wind? Hard to tell.",

    location = nil,

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            name = "a locked oak door",
            description = "A heavy oak door with iron bands and a large keyhole. It doesn't budge when you push. A brass plate above the handle reads a room name. Beyond this door lies the rest of the manor -- but not today.",
            room_presence = "Oak doors with brass plates line the hallway -- all locked.",
            on_feel = "Heavy oak, iron bands crossing the surface. The handle turns but the bolt holds fast. A large keyhole -- you can feel the lock mechanism.",
            on_smell = "Oak and iron. Faint traces from beyond.",
            on_listen = "Nothing from the other side. Or -- is that the wind? Hard to tell.",
        },
    },

    transitions = {},

    mutations = {},
}
