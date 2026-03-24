-- curtains.lua — FSM-managed window covering
-- States: closed <-> open (reversible)
return {
    guid = "{cc981807-a74e-4ecc-8d52-903cc4fc5bd6}",
    template = "sheet",

    id = "curtains",
    material = "velvet",
    keywords = {"curtains", "drapes", "curtain", "velvet", "window covering"},
    size = 3,
    weight = 3,
    categories = {"fabric", "soft", "window covering", "wearable"},
    room_position = "hang across the window in the far wall",
    portable = true,

    wear = {
        slot = "back",
        layer = "outer",
        fit = "makeshift",
        wear_quality = "makeshift",
        provides_warmth = true,
        mirror_appearance = "wearing curtains as a makeshift cloak",
    },

    event_output = {
        on_wear = "You drape the heavy velvet curtains over your shoulders like a cape. You look ridiculous, but at least you're warm.",
    },

    -- Initial state (closed)
    name = "heavy velvet curtains",
    description = "Heavy curtains of faded burgundy velvet, drawn closed and pooling on the floor in dusty folds. They block whatever light tries to enter. Moths have been at them -- small holes let through pinpricks of grey light like a constellation of neglect.",
    room_presence = "Heavy velvet curtains of faded burgundy hang across the far wall, pooling on the floor in dusty folds.",
    on_feel = "Heavy fabric, hanging in thick folds. Velvet -- once fine, now dusty. The weave is dense enough to block all light.",
    on_smell = "Dusty. The accumulated neglect of years, trapped in velvet.",
    on_listen = "A faint rustling when disturbed, like dry leaves shifting.",
    on_taste = "Dust and velvet fibers. Regret.",
    filters_daylight = true,

    location = nil,

    -- Destructive mutations (not FSM — object ceases to exist)
    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth", "rag"},
        },
    },

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "heavy velvet curtains",
            description = "Heavy curtains of faded burgundy velvet, drawn closed and pooling on the floor in dusty folds. They block whatever light tries to enter. Moths have been at them -- small holes let through pinpricks of grey light like a constellation of neglect.",
            room_presence = "Heavy velvet curtains of faded burgundy hang across the far wall, pooling on the floor in dusty folds.",
            on_feel = "Heavy fabric, hanging in thick folds. Velvet -- once fine, now dusty. The weave is dense enough to block all light.",
            on_smell = "Dusty. The accumulated neglect of years, trapped in velvet.",
            filters_daylight = true,

            on_look = function(self)
                return self.description .. "\n\nThey could be opened."
            end,
        },

        open = {
            name = "heavy velvet curtains (open)",
            description = "The heavy burgundy curtains have been pulled aside, bunched against the wall in dusty velvet heaps. Pale grey light spills through, illuminating motes of dust that swirl like tiny lost souls.",
            room_presence = "Heavy burgundy curtains have been pulled aside against the wall, letting pale light spill across the floor.",
            on_feel = "Heavy velvet, bunched and dusty. The fabric is thick and slightly damp near the window.",
            on_smell = "Dust stirred up from the folds. The smell of a room opening its eyes.",
            allows_daylight = true,

            on_look = function(self)
                return self.description .. "\n\nThey could be closed again."
            end,
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"draw", "pull"},
            message = "You grab the heavy velvet and heave the curtains aside. Dust billows. Pale light floods in, and for a moment you can see the room clearly.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"draw", "pull"},
            message = "You pull the heavy curtains shut. The light dies, and the room returns to its usual gloom.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
    },
}
