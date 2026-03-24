-- wardrobe.lua — FSM-managed wardrobe
-- States: closed <-> open (reversible)
return {
    guid = "{9c4701d1-4cc4-49e7-9c4a-041e1e37caf1}",
    template = "furniture",
    id = "wardrobe",
    material = "oak",
    keywords = {"wardrobe", "armoire", "closet", "cabinet", "clothes"},
    room_presence = "A towering wardrobe lurks in the corner like a dark sentinel, its doors firmly shut.",

    on_feel = "A massive wooden frame, smooth and cold. Carved door handles -- acorns and oak leaves under your fingers.",
    on_smell = "Cedar. Sharp and sweet, even through closed doors.",

    size = 9,
    weight = 60,
    categories = {"furniture", "wooden", "large", "container"},
    room_position = "looms in the far corner like a dark sentinel",
    portable = false,

    surfaces = {
        inside = { capacity = 8, max_item_size = 4, accessible = false, contents = {"trousers", "sack"} },
    },

    location = nil,

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a heavy wardrobe",
            description = "A towering oak wardrobe, dark as a coffin and nearly as inviting. Its double doors are carved with a pattern of acorns and oak leaves, the craftsmanship fine but worn smooth by generations of hands. The doors are firmly closed. Something inside shifts faintly when you lean against it -- settling wood, or something else.",
            room_presence = "A towering wardrobe lurks in the corner like a dark sentinel, its doors firmly shut.",
            on_feel = "A massive wooden frame, smooth and cold. Carved door handles -- acorns and oak leaves under your fingers.",
            on_smell = "Cedar. Sharp and sweet, even through closed doors.",

            surfaces = {
                inside = { capacity = 8, max_item_size = 4, accessible = false, contents = {} },
            },

            on_look = function(self)
                return self.description
            end,
        },

        open = {
            name = "a heavy wardrobe (open)",
            description = "The massive wardrobe stands open, its carved doors flung wide like wings. The interior is lined with cedar -- you can smell it, sharp and sweet beneath the must. A few wooden pegs jut from the back wall, most empty.",
            room_presence = "A towering wardrobe stands open in the corner, its carved doors flung wide like wings.",
            on_feel = "A massive wooden frame, smooth and cold. The doors swing wide on iron hinges. Wooden pegs jut from the back wall.",
            on_smell = "Cedar -- sharp and sweet, now released into the room. Beneath it, the faintest trace of moth-eaten wool.",

            surfaces = {
                inside = { capacity = 8, max_item_size = 4, accessible = true, contents = {} },
            },

            on_look = function(self, registry)
                local text = self.description
                if not self.surfaces or not self.surfaces.inside
                   or #self.surfaces.inside.contents == 0 then
                    text = text .. "\n\nThe wardrobe is empty. Not even a moth."
                else
                    text = text .. "\n\nHanging inside:"
                    for _, id in ipairs(self.surfaces.inside.contents) do
                        local item = registry and registry:get(id)
                        text = text .. "\n  " .. (item and item.name or id)
                    end
                end
                return text
            end,
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You pull open the heavy wardrobe doors. They swing wide on iron hinges with a groan of old wood. The smell of cedar and moth-eaten wool billows out.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You push the wardrobe doors shut. They close with a solid thud.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
    },

    -- Base on_look for initial load (overridden by state on_look)
    name = "a heavy wardrobe",
    description = "A towering oak wardrobe, dark as a coffin and nearly as inviting. Its double doors are carved with a pattern of acorns and oak leaves, the craftsmanship fine but worn smooth by generations of hands. The doors are firmly closed. Something inside shifts faintly when you lean against it -- settling wood, or something else.",

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
