-- beast-burger-kitchen.lua — The Beast Burger Kitchen
-- Recipe following puzzle. Difficulty: ★★★

return {
    guid = "8132ceb7-f259-466a-81eb-c1173d3d6b81",
    template = "room",

    id = "beast-burger-kitchen",
    name = "The Beast Burger Kitchen",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"kitchen", "burger kitchen", "beast burger", "beast burger kitchen"},
    description = "You walk into a bright kitchen that sizzles and pops. "
               .. "Shelves are loaded with burger toppings in every color. "
               .. "A recipe card sits on the counter next to an empty plate.",
    short_description = "A colorful kitchen ready for burger building.",

    goal = { verb = "put", noun = "bun", label = "build the Beast Burger" },

    on_feel = "The counter feels smooth and cool. "
           .. "Warm air blows from the grill in the corner.",

    on_smell = "Sizzling burgers! The room smells amazing. Let's cook!",

    on_listen = "You hear the grill sizzle and a timer ticking on the wall.",

    instances = {},

    exits = {
        west = { target = "beast-studio" },
    },

    mutations = {},
}
