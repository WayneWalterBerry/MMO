-- wine-rack.lua — Static furniture / container for wine bottles
return {
    guid = "{ea06f4d5-7182-4b23-de45-f02167890123}",
    template = "furniture",

    id = "wine-rack",
    material = "wood",
    keywords = {"wine rack", "rack", "wine shelf", "bottle rack", "shelving"},
    size = 5,
    weight = 30,
    categories = {"furniture", "wooden"},
    portable = false,

    name = "a wooden wine rack",
    description = "A tall wooden wine rack against the west wall, built of dark-stained timber. Circular slots hold bottles in rows -- most empty, a few still occupied. Cobwebs bridge the gaps between bottles like silk hammocks. The wood is warped with damp.",
    room_presence = "A tall wine rack stands against the west wall, a few dusty bottles still resting in its slots.",
    on_feel = "Rough timber, damp-swollen. The circular slots are smooth-worn from years of bottles sliding in and out. Cobwebs cling to your fingers, sticky and old.",
    on_smell = "Old wine -- vinegar, oak tannins, and must. The wood itself smells of damp rot.",
    on_listen = "Bottles clink softly when you brush against the rack.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 12, max_item_size = 2, weight_capacity = 25,
            contents = {"wine-bottle"},
            accessible = true,
            accepts = {"bottle"},
        },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
