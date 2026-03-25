-- stone-altar.lua — Static furniture (Deep Cellar hub for Puzzle 012)
return {
    guid = "{a5fbf32f-530b-49af-9a19-255575a5eb77}",
    template = "furniture",

    id = "stone-altar",
    material = "stone",
    keywords = {"altar", "stone altar", "slab", "sacrificial altar", "stone table"},
    size = 6,
    weight = 200,
    categories = {"furniture", "stone"},
    portable = false,

    name = "a stone altar",
    description = "A massive stone altar dominates the center of the chamber, carved from a single block of pale granite. Its surface is smooth and slightly concave -- worn by centuries of use. Symbols are inscribed around the edges: spirals, crosses, and a repeating motif of an eye within a triangle. Wax drippings and ash stains mark its surface. Three objects rest upon it -- a brass bowl, a small burner, and a rolled scroll.",
    room_presence = "A massive stone altar stands at the center of the chamber, pale granite carved with ancient symbols.",
    on_feel = "Cold, smooth stone. The surface dips slightly in the center -- worn from use or designed as a basin. The carved symbols are shallow grooves under your fingertips -- spirals, lines, geometric shapes. The stone holds the cold of centuries.",
    on_smell = "Old incense -- sandalwood and myrrh, faded almost to memory. Candle wax. Stone dust. And beneath it all, something organic and ancient -- must, or decay, or very old blood.",
    on_listen = "Your touch on the stone produces no echo. The altar absorbs sound.",
    on_taste = "Cold stone and grit. The taste of geology.",

    location = nil,

    surfaces = {
        top = {
            capacity = 5, max_item_size = 3, weight_capacity = 20,
            contents = {"offering-bowl-1", "incense-burner-1", "tattered-scroll-1"},
            accessible = true,
        },
        behind = {
            capacity = 2, max_item_size = 1, weight_capacity = 5,
            contents = {"silver-key-1"},
            accessible = true,
        },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
