-- feastables-factory.lua — The Feastables Factory
-- Chocolate sorting puzzle. Difficulty: ★★

return {
    guid = "67f234b1-878b-454c-9ff7-c0100e0d4ec5",
    template = "room",

    id = "feastables-factory",
    name = "The Feastables Factory",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 1,
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

    instances = {
        { id = "factory-sign", type = "Factory Sign", type_id = "{8CA8F631-B1BB-4481-B6B5-48A0D661559C}" },
        { id = "conveyor-belt", type = "Conveyor Belt", type_id = "{19AE105D-DE0E-44A6-AF0C-65C321F4B353}",
            on_top = {
                { id = "chocolate-bar-blue", type = "Blue Chocolate Bar", type_id = "{EE48EED8-41EC-44D9-8001-E0CFE9F7FD4A}" },
                { id = "chocolate-bar-gold", type = "Gold Chocolate Bar", type_id = "{D67EA761-ED47-4E0B-998F-3EE33E7122AB}" },
                { id = "chocolate-bar-green", type = "Green Chocolate Bar", type_id = "{BB86AFC1-7C8D-4DAD-83BD-4E6A782024B6}" },
                { id = "chocolate-bar-purple", type = "Purple Chocolate Bar", type_id = "{E97D0382-5B65-48E7-AF8C-768F1A69FA13}" },
                { id = "chocolate-bar-red", type = "Red Chocolate Bar", type_id = "{C4084BEC-5982-4797-9C8C-4408E8353E46}" },
            },
        },
        { id = "sorting-bin-creamy", type = "Creamy Bin", type_id = "{211076C8-3A5B-4777-A9EA-80415B57EE37}" },
        { id = "sorting-bin-crunchy", type = "Crunchy Bin", type_id = "{74EA982A-B33E-4F8B-8AA4-5D6A44BE8A0A}" },
        { id = "sorting-bin-fruity", type = "Fruity Bin", type_id = "{390677DD-0EE9-4789-AD9E-1ABE351F2112}" },
        { id = "sorting-bin-nutty", type = "Nutty Bin", type_id = "{EF762EC2-1C76-4918-B711-7CD70B5B132B}" },
        { id = "completion-medal", type = "Completion Medal", type_id = "{F0A395E5-167F-4DFE-B8E2-6643FBF82E6A}" },
    },

    exits = {
        south = { target = "beast-studio" },
    },

    mutations = {},
}
