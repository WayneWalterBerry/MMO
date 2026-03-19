return {
    guid = "0d5c8636-f168-4b5d-99ae-5d53714fd205",
    template = "sheet",
    id = "cloth",
    name = "a piece of cloth",
    keywords = {"cloth", "fabric", "burlap", "scrap", "material"},
    description = "A rough square of burlap cloth, torn from a sack. The edges are frayed and uneven, but the weave is sturdy enough to be useful.",

    on_feel = "Soft fabric with torn, frayed edges. The weave is coarse but sturdy.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric", "craftable"},

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

    crafting = {
        sew = {
            consumes = {"cloth", "cloth"},
            requires_tool = "sewing_tool",
            requires_skill = "sewing",
            becomes = "terrible-jacket",
            message = "You stitch the pieces together with small, uneven stitches. The result is... well, it's a jacket. Technically.",
            fail_message_no_tool = "You have nothing to sew with.",
            fail_message_no_skill = "You wouldn't know where to begin. You'd need to learn to sew first.",
        },
    },
}
