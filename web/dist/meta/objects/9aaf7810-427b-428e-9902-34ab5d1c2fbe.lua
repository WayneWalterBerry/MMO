-- rope-coil.lua — Static tool object
return {
    guid = "{9aaf7810-427b-428e-9902-34ab5d1c2fbe}",
    template = "small-item",

    id = "rope-coil",
    material = "hemp",
    keywords = {"rope", "coil", "coil of rope", "hemp rope", "line", "cord"},
    size = 3,
    weight = 3,
    categories = {"tool"},
    portable = true,

    name = "a coil of rope",
    description = "A thick coil of hemp rope, looped neatly and hung on an iron peg in the wall. The fibers are rough but sound -- not rotted. About twenty feet of it, by the look.",
    room_presence = "A coil of rope hangs from an iron peg on the wall.",
    on_feel = "Rough hemp fibers, thick as your thumb. The coils are stiff but pliable -- not rotted through. The rope is strong.",
    on_smell = "Hemp and tar. A working rope, treated against damp.",

    location = nil,

    provides_tool = {"rope", "binding"},

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
