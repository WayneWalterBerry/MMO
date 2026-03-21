-- stone-well.lua — Static furniture (Courtyard center)
return {
    guid = "{096114c9-418d-41df-a5bf-d6a977664f8a}",
    template = "furniture",

    id = "stone-well",
    material = "stone",
    keywords = {"well", "stone well", "water well", "wishing well", "well shaft"},
    size = 6,
    categories = {"furniture", "stone", "container"},
    portable = false,

    name = "a stone well",
    description = "A stone well stands at the center of the courtyard -- a low ring of moss-covered granite, about four feet across, with a wooden crossbeam and a rusted iron winding handle. A frayed rope descends into darkness. When you lean over the edge, you can see nothing -- only black. But you can hear water, far below.",
    room_presence = "A stone well stands at the courtyard's center, its crossbeam dark against the stars.",
    on_feel = "Cold, rough stone, slimy with moss on the outside. The rim is worn smooth on top from centuries of hands and elbows. The crossbeam is weathered wood. The winding handle is cold iron, rough with rust.",
    on_smell = "Damp stone and moss. A breath of cool, mineral-scented air rises from the shaft -- underground water, clean and old.",
    on_listen = "Water. Distant, echoing. A drip... then silence... then another drip. The sound bounces up the stone shaft like a whispered secret.",
    on_taste = "Wet granite, moss, and mineral water. Cold.",

    location = nil,

    surfaces = {
        top = {
            capacity = 2, max_item_size = 2, weight_capacity = 10,
            contents = {},
            accessible = true,
        },
        inside = {
            capacity = 1, max_item_size = 3, weight_capacity = 50,
            contents = {"well-bucket-1"},
            accessible = true,
        },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
