-- beast-burger-kitchen.lua — The Beast Burger Kitchen
-- Recipe following puzzle. Difficulty: ★★★

return {
    guid = "8132ceb7-f259-466a-81eb-c1173d3d6b81",
    template = "room",

    id = "beast-burger-kitchen",
    name = "The Beast Burger Kitchen",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 2,
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

    instances = {
        { id = "kitchen-sign", type = "Kitchen Sign", type_id = "{2B444911-7207-49C7-B053-673E7549BE75}" },
        { id = "recipe-card", type = "Recipe Card", type_id = "{D9CE8A54-74B2-4F3E-8B83-8EBC60AC1E12}" },
        { id = "big-grill", type = "Big Grill", type_id = "{1A78B074-567C-4F10-8AF6-64C2BDF796A7}" },
        { id = "assembly-plate", type = "Assembly Plate", type_id = "{3376B79D-0C3C-47E5-8398-BAA8846655DA}" },
        { id = "ingredient-shelf", type = "Ingredient Shelf", type_id = "{B5DA4606-44DB-444F-BE0D-15B87BD9C3EB}",
            on_top = {
                { id = "bottom-bun", type = "Bottom Bun", type_id = "{92264A9C-0D3F-4328-9498-6B11C460FCCF}" },
                { id = "burger-patty", type = "Burger Patty", type_id = "{E7BF8CAC-4180-4549-BCD3-C88201DF5D7B}" },
                { id = "cheese-slice", type = "Cheese Slice", type_id = "{2DEC5036-20C2-4A99-9B26-FF4DF6F58CC1}" },
                { id = "lettuce-leaf", type = "Lettuce Leaf", type_id = "{4AE893C9-5EC7-4A82-95BE-5D40BC0EB5DE}" },
                { id = "tomato-slice", type = "Tomato Slice", type_id = "{83AE55F0-3307-401D-B16F-5AC389FF4679}" },
                { id = "top-bun", type = "Top Bun", type_id = "{080751D4-E617-467A-B7B6-EC755D5D8989}" },
            },
        },
        { id = "beast-burger-coupon", type = "Beast Burger Coupon", type_id = "{1E0DEB57-2014-4C3B-A846-257031E94EA5}" },
    },

    exits = {
        west = { target = "beast-studio" },
    },

    mutations = {},
}
