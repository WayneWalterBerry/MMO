return {
    id = "shattered-mirror",
    name = "a shattered mirror",
    keywords = {"mirror", "shattered mirror", "broken mirror", "shards", "glass", "pile", "frame"},
    description = "What was once a tall gilded mirror is now a ruin. The ornate frame still stands, but the glass has exploded outward in a frozen violence of splinters and shards. Seven years bad luck, by the old reckoning.",

    size = 3,
    weight = 12,
    portable = false,
    material = "glass",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fragile", "decorative"},

    on_look = function(self)
        return self.description .. "\n\nA glittering pile of glass shards covers the floor beneath the frame. One particularly large shard has skittered away from the rest."
    end,

    mutations = {},
}
