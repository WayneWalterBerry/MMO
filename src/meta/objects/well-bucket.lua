-- well-bucket.lua — FSM-managed water retrieval tool (Courtyard)
-- States: raised-empty → lowered → raised-full → raised-empty
return {
    guid = "35bmr05y-c6d3-40e6-29f9-4b371c901234",
    template = "container",

    id = "well-bucket",
    material = "wood",
    keywords = {"bucket", "well bucket", "pail", "wooden bucket", "water bucket"},
    size = 3,
    weight = 2,
    categories = {"container", "wooden", "tool"},
    portable = true,

    name = "a wooden bucket",
    description = "A wooden bucket hangs from the well's crossbeam by a frayed rope. It's empty, dry inside, with dark water stains marking past use. The iron bands are rusted but intact.",
    on_feel = "A wooden bucket, round, iron-banded. Empty inside -- dry and rough. The rope above is frayed hemp, damp.",
    on_smell = "Old wood and hemp rope.",
    on_listen = "The rope creaks against the crossbeam when the bucket swings.",

    location = nil,

    prerequisites = {
        pour = { requires_state = "raised-full" },
    },

    initial_state = "raised-empty",
    _state = "raised-empty",

    states = {
        ["raised-empty"] = {
            name = "a wooden bucket",
            description = "A wooden bucket hangs from the well's crossbeam by a frayed rope. It's empty, dry inside, with dark water stains marking past use. The iron bands are rusted but intact.",
            on_feel = "A wooden bucket, round, iron-banded. Empty inside -- dry and rough. The rope above is frayed hemp, damp.",
            on_smell = "Old wood and hemp rope.",
            on_listen = "The rope creaks against the crossbeam when the bucket swings.",
        },

        lowered = {
            name = "a lowered bucket",
            description = "The bucket has been lowered into the well. The rope unspools from the winding handle, creaking and groaning. You can hear the bucket splash far below.",
            on_feel = "The rope is taut and wet where it emerges from the shaft. The winding handle is cold.",
            on_smell = "Damp air rising from the shaft.",
            on_listen = "A distant splash, then dripping. The bucket is in the water.",
        },

        ["raised-full"] = {
            name = "a bucket of water",
            description = "A wooden bucket, brimming with cold, dark water. Droplets trace down the iron bands. The rope is taut with the weight.",
            on_feel = "Heavy now -- the water sloshes inside. The wood is wet and cold. The iron bands are slippery.",
            on_smell = "Fresh water -- clean, mineral, cold. Like underground stone.",
            on_listen = "Water sloshes and drips.",
        },
    },

    transitions = {
        {
            from = "raised-empty", to = "lowered", verb = "lower",
            aliases = {"drop", "send down"},
            message = "You turn the winding handle. The rope unspools with a rhythmic creak, and the bucket descends into darkness. A long pause... then a distant splash echoes up the shaft.",
        },
        {
            from = "lowered", to = "raised-full", verb = "raise",
            aliases = {"pull up", "wind up", "crank"},
            message = "You crank the handle. The rope tightens and strains. Slowly, the bucket rises -- heavy with water. It clears the rim, dripping and full. Cold, dark water nearly to the brim.",
            mutate = {
                weight = function(w) return w + 8 end,
            },
        },
        {
            from = "raised-full", to = "raised-empty", verb = "pour",
            aliases = {"empty", "dump", "tip"},
            message = "You upend the bucket. Cold water splashes across the cobblestones, darkening the stone and releasing a brief mineral scent.",
            mutate = {
                weight = 2,
                keywords = { remove = "full" },
            },
        },
    },

    mutations = {},
}
