-- small-crate.lua — Simple container with latch
-- States: closed ↔ open, any → broken (terminal)
return {
    guid = "c8d4e2b3-5f60-4901-bc23-def045678901",
    template = "container",

    id = "small-crate",
    material = "wood",
    keywords = {"crate", "small crate", "wooden crate", "box", "small box"},
    size = 3,
    weight = 8,
    categories = {"container", "wooden", "breakable"},
    portable = true,

    name = "a small wooden crate",
    description = "A small wooden crate, about the size of a bread loaf. The lid sits loosely on top, held by a simple latch. Something rattles faintly inside.",
    room_presence = "A small wooden crate sits atop a shelf, its latch rusted shut.",
    on_feel = "Smooth-planed wood, lighter than the big crate. A small iron latch on one side. The lid moves slightly when pushed.",
    on_smell = "Sawdust and old varnish.",

    location = nil,

    surfaces = {
        inside = {
            capacity = 3, max_item_size = 2, weight_capacity = 10,
            contents = {},
            accessible = false,
        },
    },

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a small wooden crate",
            description = "A small wooden crate, about the size of a bread loaf. The lid sits loosely on top, held by a simple latch. Something rattles faintly inside.",
            room_presence = "A small wooden crate sits atop a shelf, its latch rusted shut.",
            on_feel = "Smooth-planed wood, lighter than the big crate. A small iron latch on one side. The lid moves slightly when pushed.",
            on_smell = "Sawdust and old varnish.",
        },

        open = {
            name = "an open small crate",
            description = "A small crate with its lid propped open. Inside: a tangle of old rags and wood shavings. Nothing of obvious value.",
            on_feel = "Open box. Inside: soft rags, scratchy wood shavings. The bottom is bare wood.",
            on_smell = "Musty fabric, sawdust.",
        },

        broken = {
            name = "a broken small crate",
            description = "The small crate has been smashed. Thin planks and a bent latch lie scattered.",
            on_feel = "Thin splinters and bent metal.",
            on_smell = "Sawdust.",
            terminal = true,
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You flip the latch and lift the lid. Inside: a nest of old rags and wood shavings. Nothing remarkable.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You close the lid and flip the latch shut.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "broken", verb = "break",
            aliases = {"smash"},
            requires_tool = "prying_tool",
            message = "The small crate splinters easily under the blow.",
            mutate = {
                weight = 2,
                keywords = { add = "broken" },
                categories = { remove = "container" },
            },
        },
        {
            from = "open", to = "broken", verb = "break",
            aliases = {"smash"},
            requires_tool = "prying_tool",
            message = "The open crate crunches apart.",
            mutate = {
                weight = 2,
                keywords = { add = "broken" },
                categories = { remove = "container" },
            },
        },
    },

    mutations = {},
}
