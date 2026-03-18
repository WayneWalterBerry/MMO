return {
    id = "mirror",
    name = "a tall mirror",
    keywords = {"mirror", "looking glass", "reflection", "glass"},
    description = "A tall mirror in an ornate gilded frame, standing against the wall like a doorway to another world. The glass is old and slightly warped, giving your reflection a haunted, wavering quality.",

    size = 3,
    weight = 15,
    portable = false,
    material = "glass",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fragile", "reflective", "decorative"},

    on_look = function(self)
        return self.description .. "\n\nYour reflection gazes back at you, mimicking your every move with an unsettling half-second delay."
    end,

    mutations = {
        break = {
            becomes = "shattered-mirror",
            spawns = {"glass-shard"},
        },
    },
}
