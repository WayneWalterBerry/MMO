-- tome.lua — Critical lore object (Crypt, Sarcophagus 1 — Puzzle 014)
-- States: closed → open (readable)
return {
    guid = "d5lw1a5i-6073-4a86-c393-e53116901234",
    template = "small-item",

    id = "tome",
    material = "leather",
    keywords = {"tome", "book", "leather book", "ledger", "volume", "manuscript", "diary", "journal"},
    size = 3,
    weight = 2,
    categories = {"readable", "treasure"},
    portable = true,

    name = "a leather-bound tome",
    description = "A thick, leather-bound tome. The cover is embossed with the eye-and-triangle symbol in gold leaf, much of it flaked away. The spine is cracked but intact. Iron clasps hold it shut -- not locked, just stiff with age. This book has been sealed in a sarcophagus for centuries, yet it's remarkably well-preserved.",
    on_feel = "Heavy, thick leather. The embossed symbol is raised under your fingertips -- an eye in a triangle. Iron clasps, cold and stiff. The pages are thick -- parchment, not paper.",
    on_smell = "Old leather, aged vellum, and a hint of iron-gall ink. The smell of preserved knowledge. Centuries of silence.",

    location = nil,

    prerequisites = {
        read = { requires_state = "open" },
    },

    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a leather-bound tome",
            description = "A thick, leather-bound tome. The cover is embossed with the eye-and-triangle symbol in gold leaf, much of it flaked away. The spine is cracked but intact. Iron clasps hold it shut -- not locked, just stiff with age. This book has been sealed in a sarcophagus for centuries, yet it's remarkably well-preserved.",
            on_feel = "Heavy, thick leather. The embossed symbol is raised under your fingertips -- an eye in a triangle. Iron clasps, cold and stiff. The pages are thick -- parchment, not paper.",
            on_smell = "Old leather, aged vellum, and a hint of iron-gall ink. The smell of preserved knowledge. Centuries of silence.",
        },

        open = {
            name = "an open leather-bound tome",
            description = "The tome lies open, its pages thick and yellowed. The handwriting is cramped and archaic but readable -- the author intended this to be understood. The text is a mixture of Latin and the common tongue, illustrated with diagrams and symbols. This is a chronicle -- the history of the Blackwood family and their purpose.",
            on_feel = "Thick vellum pages, smooth but fragile. The ink is raised slightly -- hand-written with care. The binding creaks when turned.",
            on_smell = "Stronger ink smell now. Old vellum. The breath of centuries released.",
            on_read = "THE CHRONICLE OF THE BLACKWOOD FAMILY\nAs set down by Lord Aldric Blackwood, Founder and First Keeper\n\nIn the year of our Lord 1138, I, Aldric, did discover beneath this hill a chamber of ancient making -- older than memory, older than the faith that now claims these lands. The symbols upon its walls spoke of a duty: to guard what sleeps below, and to ensure it never wakes.\n\nI built this manor above the chamber, and my family has kept the vigil ever since. We are the Custodes -- the Keepers. Each generation inherits the burden. The altar is our covenant. The offering is our oath.\n\nIf you read these words, I am gone. The vigil has passed to you, whether you chose it or not. Guard well. Speak the words at the altar. And never, never open the [final pages are torn out -- the text ends abruptly].",
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"read", "unclasp"},
            message = "You work the iron clasps free -- they resist, then give with a dry click. The cover opens heavily, releasing a breath of ancient air. The pages within are covered in dense, careful handwriting.",
            mutate = {
                keywords = { add = "open" },
            },
        },
    },

    mutations = {},
}
