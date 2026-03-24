return {
    guid = "{3c75a0cc-0b60-458b-a533-7ec1c48da76a}",
    template = "sheet",
    id = "trousers",
    name = "a pair of moth-eaten trousers",
    keywords = {"trousers", "pants", "breeches", "wool trousers", "garment", "clothing"},
    description = "A pair of threadbare wool trousers the color of old dishwater. Moths have turned the left knee into lace, and the waistband has been let out twice -- the stitch marks still visible. They smell of cedar and mildew in equal measure. Someone wore these hard and put them away wet.",

    on_feel = "Rough, threadbare cloth with moth holes. The wool is coarse and pilled, barely holding together at the seams.",
    on_smell = "Cedar from the wardrobe and mildew from the wool. Musty, like old clothes left too long in a damp closet.",
    on_taste = "Bitter dust and lanolin. A terrible idea.",
    on_listen = "Silent. Cloth this thin barely rustles.",

    size = 2,
    weight = 1,
    categories = {"fabric", "wearable"},
    portable = true,
    material = "wool",

    wear = {
        slot = "legs",
        layer = "inner",
        fit = "makeshift",
        wear_quality = "makeshift",
    },

    event_output = {
        on_wear = "You pull on the trousers. They sag at the waist and the left knee is mostly hole, but they are, technically, pants.",
    },

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "rag"},
            message = "The threadbare trousers give way with barely a fight. Moth-eaten wool was never going to last.",
        },
    },
}
