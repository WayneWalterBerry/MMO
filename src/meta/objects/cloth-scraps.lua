-- cloth-scraps.lua — Craftable material (Storage Cellar, inside small crate)
return {
    guid = "7cb2e194-3d80-4a51-bf63-e8d1c5a40927",

    id = "cloth-scraps",
    material = "fabric",
    keywords = {"cloth", "scraps", "cloth scraps", "rags", "fabric", "strips", "torn cloth"},
    size = 1,
    weight = 0.15,
    categories = {"fabric", "craftable", "small"},
    portable = true,

    name = "some cloth scraps",
    description = "A handful of torn cloth strips -- once part of a sack or garment, now reduced to frayed scraps. The fabric is coarse and stained, but still has some strength in the weave. Useful for bandages, cleaning, or stuffing into gaps.",
    on_feel = "Rough, coarse fabric -- torn, frayed edges. Multiple strips of different lengths. Still has some strength when you pull on them.",
    on_smell = "Musty fabric. Old dust. The faintest trace of whatever these once held or covered.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        make_bandage = {
            becomes = "bandage",
        },
        make_rag = {
            becomes = "rag",
        },
    },
}
