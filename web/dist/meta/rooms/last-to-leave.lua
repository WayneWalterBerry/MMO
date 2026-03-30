-- last-to-leave.lua — The Last to Leave Room
-- Find the three fakes puzzle. Difficulty: ★★★

return {
    guid = "54fd467b-c58b-49d2-b42f-b6836b150d6b",
    template = "room",

    id = "last-to-leave",
    name = "The Last to Leave Room",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 1,
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

    instances = {
        { id = "couch", type = "Couch", type_id = "{F0A5E5DB-1A9D-40D9-B453-7CAF742A561C}" },
        { id = "normal-rug", type = "Normal Rug", type_id = "{989C5DED-8BB9-4D10-A545-0B298593A207}" },
        { id = "bookshelf", type = "Bookshelf", type_id = "{0D5E44BB-D5E6-4191-9ADF-84841DDEC5C2}",
            on_top = {
                { id = "backwards-book", type = "Backwards Book", type_id = "{A9C3354C-0E29-4397-8688-785C6CD9EDBD}" },
            },
        },
        { id = "cold-lamp", type = "Cold Lamp", type_id = "{79C6EBDE-8521-41B1-9B11-9ED7072806C1}" },
        { id = "weird-clock", type = "Weird Clock", type_id = "{7720927E-D162-4983-B685-581F748A784A}" },
        { id = "found-it-box", type = "Found It Box", type_id = "{9F3154AD-FE86-42F6-8121-785420D9EE8E}" },
    },

    exits = {
        east = { target = "beast-studio" },
    },

    mutations = {},
}
