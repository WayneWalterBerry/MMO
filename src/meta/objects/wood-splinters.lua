-- wood-splinters.lua — Debris from broken wooden doors
-- Spawned by door break transitions (bedroom-hallway-door-north/south, courtyard-kitchen-door).
-- See: Issue #404, mutation-edge-check WAVE-2
return {
    guid = "{6e21c832-e8bd-4a41-8fd2-d62d3e12e328}",
    template = "small-item",
    id = "wood-splinters",
    name = "a handful of wood splinters",
    material = "wood",
    keywords = {"splinters", "wood splinters", "wood", "debris", "fragments", "splinter"},
    description = "A scatter of pale oak splinters, torn loose when the door gave way. Some are finger-length daggers of raw grain; others are short, jagged stubs still trailing fibres.",

    on_feel = "Sharp and rough. The broken grain catches on your skin like tiny fish-hooks.",
    on_smell = "Fresh-split oak — a faint, sweet tang of sap.",
    on_listen = "They crackle faintly when you shift them.",
    on_taste = "Dry, bitter wood fibre. A splinter pricks your tongue.",

    room_presence = "A spray of pale wood splinters litters the floor around the ruined door.",

    size = 1,
    weight = 0.1,
    portable = true,
    categories = {"wood", "debris", "sharp"},

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
