-- mirror.lua — Standing vanity mirror with FSM breakage states
-- States: intact → cracked → broken (terminal, spawns glass-shard)
-- Placed on_top of vanity in start-room. Separate object from vanity (Issue #173).
return {
    guid = "{1b47a68e-33a7-4d27-8065-4bc94b8f149f}",
    template = "small-item",

    id = "mirror",
    material = "glass",
    is_mirror = true,
    keywords = {"mirror", "looking glass", "glass", "vanity mirror", "reflection", "my reflection"},
    size = 3,
    weight = 2.5,
    categories = {"reflective", "glass", "fragile"},
    portable = false,

    -- Initial state (intact)
    name = "an ornate mirror",
    description = "An ornate standing mirror in a frame of tarnished gilt scrollwork, rising from the back of the vanity. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality.",
    room_presence = "An ornate mirror in a tarnished gilt frame rises from the back of the vanity.",
    on_feel = "Cool, smooth glass under your fingertips. Perfectly flat, with the faintest warping at the edges. The gilt frame is rough with tarnish.",
    on_smell = "Nothing. Glass has no smell.",
    on_listen = "Silence. Your reflection stares back, mouthing nothing.",
    on_taste = "Cold and flat. Glass. You leave a tongue-print and regret your choices.",

    on_look_in = "Your reflection stares back from the warped glass, mimicking your movements with an unsettling half-second delay. In the old glass, your face looks slightly wrong — as though someone wearing your skin is looking back from the other side.",

    location = nil,

    -- FSM
    initial_state = "intact",
    _state = "intact",

    states = {
        intact = {
            name = "an ornate mirror",
            description = "An ornate standing mirror in a frame of tarnished gilt scrollwork, rising from the back of the vanity. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality.",
            room_presence = "An ornate mirror in a tarnished gilt frame rises from the back of the vanity.",
            on_feel = "Cool, smooth glass under your fingertips. Perfectly flat, with the faintest warping at the edges. The gilt frame is rough with tarnish.",
            on_smell = "Nothing. Glass has no smell.",
            on_listen = "Silence. Your reflection stares back, mouthing nothing.",

            on_look_in = "Your reflection stares back from the warped glass, mimicking your movements with an unsettling half-second delay. In the old glass, your face looks slightly wrong — as though someone wearing your skin is looking back from the other side.",

            on_look = function(self)
                return self.description .. "\n\nYour reflection stares back, wavering in the old glass."
            end,
        },

        cracked = {
            name = "a cracked mirror",
            description = "The ornate mirror is cracked — a web of fracture lines radiates from a central point of impact, splitting your reflection into a dozen fractured versions of yourself. The gilt frame still holds the glass in place, but barely.",
            room_presence = "A cracked mirror sits on the vanity, your fractured reflection scattered across its surface.",
            on_feel = "The glass is cracked. You can feel the sharp ridges where the fracture lines cross the surface. Careful — the edges are keen.",
            on_smell = "A faint mineral scent of stressed glass.",
            on_listen = "A soft tinkling. The cracked panes shift against each other when you touch them.",

            on_look_in = "A dozen fractured reflections stare back at you, each one showing a different angle of your face. It is deeply unsettling — like being watched by multiple versions of yourself.",

            on_look = function(self)
                return self.description .. "\n\nYour fractured reflection stares back from a dozen glass planes."
            end,
        },

        broken = {
            name = "a broken mirror frame",
            description = "The gilt frame stands empty on the vanity, jagged glass teeth jutting from its edges like a crown of broken fangs. Most of the glass has fallen away in glittering shards. Seven years bad luck, by the old reckoning.",
            room_presence = "An empty gilt frame stands on the vanity, jagged glass teeth jutting from its edges.",
            on_feel = "CAREFUL. Jagged glass teeth jut from the frame. The gilt wood is rough and splintered where the glass tore free.",
            on_smell = "The sharp, mineral scent of freshly broken glass.",
            on_listen = "Silence. There is nothing left to reflect.",
            is_mirror = false,
            terminal = true,

            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        {
            from = "intact", to = "cracked", verb = "hit",
            aliases = {"strike", "punch", "tap"},
            message = "You strike the mirror. A web of cracks spreads across the glass with a sharp, brittle snap. Your reflection shatters into a dozen fractured copies.",
            mutate = {
                keywords = { add = "cracked" },
                categories = { add = "damaged" },
            },
        },
        {
            from = "intact", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "break_mirror", "destroy"},
            spawns = {"glass-shard"},
            message = "You drive your fist into the mirror. It shatters with a crystalline scream, shards cascading across the vanity's surface and onto the floor. Seven years bad luck.",
            mutate = {
                keywords = { add = "broken" },
                categories = { remove = "reflective" },
            },
        },
        {
            from = "cracked", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "hit", "strike", "punch", "destroy"},
            spawns = {"glass-shard"},
            message = "The already-cracked glass gives way with a final, resigned crunch. Shards rain down across the vanity and clatter to the floor. Seven years bad luck.",
            mutate = {
                keywords = { add = "broken" },
                categories = { remove = "reflective" },
            },
        },
    },

    -- GOAP prerequisites
    prerequisites = {
        ["break"] = { warns = { "injury", "minor-cut" } },
        hit = { warns = { "injury", "minor-cut" } },
    },

    on_look = function(self)
        return self.description .. "\n\nYour reflection stares back, wavering in the old glass."
    end,

    mutations = {},
}
