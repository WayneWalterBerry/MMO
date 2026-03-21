-- bronze-ring.lua — Burial treasure (Crypt, Sarcophagus 2)
return {
    guid = "d4f18a63-9e27-4c85-b790-3a6e2f8d1c04",

    id = "bronze-ring",
    material = "brass",
    keywords = {"ring", "bronze ring", "band", "jewelry", "burial ring", "treasure"},
    size = 1,
    weight = 0.04,
    categories = {"treasure", "metal", "small", "wearable"},
    portable = true,

    name = "a bronze ring",
    description = "A simple bronze ring, green with verdigris. The band is thick and heavy for its size -- cast, not hammered. On the outer surface, a crude serpent bites its own tail: an ouroboros. The inside is smooth and unadorned. Whoever wore this ring was buried with it, and it has not left this coffin since.",
    on_feel = "A thick metal band, rough with green patina. The serpent design is raised -- you can trace it with a fingertip, head to tail. Cold. Heavy for a ring.",
    on_smell = "Green copper -- the sharp, slightly sweet smell of verdigris. Old metal.",

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
