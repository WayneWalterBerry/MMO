-- feastables-factory.lua — The Feastables Factory
-- Chocolate sorting puzzle. Difficulty: ★★

return {
    guid = "67f234b1-878b-454c-9ff7-c0100e0d4ec5",
    template = "room",

    id = "feastables-factory",
    name = "The Feastables Factory",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"factory", "feastables", "chocolate factory", "feastables factory"},
    description = "A long conveyor belt rolls through the middle of the room. "
               .. "Chocolate bars in shiny wrappers slide past in every color. "
               .. "The whole room smells like sweet, warm chocolate!",
    short_description = "A bright chocolate factory with a conveyor belt.",

    goal = { verb = "put", noun = "chocolate", label = "sort the chocolate bars" },

    on_feel = "The air feels warm and sticky. "
           .. "Your fingers touch smooth plastic bins near the belt.",

    on_smell = "Chocolate! It smells SO good in here. Yum!",

    on_listen = "You hear the conveyor belt humming and wrappers crinkling.",

    instances = {},

    exits = {
        south = { target = "beast-studio" },
    },

    mutations = {},
}
