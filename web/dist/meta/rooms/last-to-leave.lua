-- last-to-leave.lua — The Last to Leave Room
-- Find the three fakes puzzle. Difficulty: ★★★

return {
    guid = "54fd467b-c58b-49d2-b42f-b6836b150d6b",
    template = "room",

    id = "last-to-leave",
    name = "The Last to Leave Room",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"last to leave", "living room", "leave room", "last to leave room"},
    description = "You walk into a room that looks like a regular living room. "
               .. "A couch, a TV, a bookshelf, a lamp, and a clock fill the space. "
               .. "A sign by the door says: Three things here don't belong!",
    short_description = "A normal-looking living room. Or is it?",

    goal = { verb = "examine", noun = "clock", label = "find the three fakes" },

    on_feel = "The carpet is soft and fluffy under your feet. "
           .. "Everything feels like a real living room.",

    on_smell = "It smells like a cozy house. Like cookies and clean laundry.",

    on_listen = "You hear a TV playing softly. A clock ticks on the wall.",

    instances = {},

    exits = {
        east = { target = "beast-studio" },
    },

    mutations = {},
}
