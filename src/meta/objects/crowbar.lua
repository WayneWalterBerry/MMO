-- crowbar.lua — Static tool object (Puzzle 009: required to pry open crates)
return {
    guid = "{b30076fe-7931-4089-8ea2-2cac139b022c}",
    template = "small-item",

    id = "crowbar",
    material = "iron",
    keywords = {"crowbar", "bar", "pry bar", "iron bar", "jimmy", "lever"},
    size = 3,
    weight = 3,
    categories = {"tool", "metal", "weapon"},
    portable = true,

    name = "an iron crowbar",
    description = "A heavy iron crowbar, nearly two feet long, with a flat claw at one end and a chisel point at the other. The iron is dark with age but solid -- no rust deep enough to weaken it. Scratches and dents mark a life of hard use.",
    room_presence = "An iron crowbar leans against the wall by the wine rack.",
    on_feel = "Cold, heavy iron bar. Smooth from use in the middle -- the grip. One end curves to a flat claw, the other tapers to a blunt chisel point. Solid. Reassuring.",
    on_smell = "Iron and old grease.",
    on_listen = "Rings like a bell when tapped against stone.",

    location = nil,

    provides_tool = {"prying_tool", "blunt_weapon", "leverage"},

    combat = {
        type = "blunt",
        force = 5,
        message = "smashes",
        two_handed = false,
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
