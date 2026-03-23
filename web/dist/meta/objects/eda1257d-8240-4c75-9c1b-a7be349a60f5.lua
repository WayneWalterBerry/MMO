-- vanity.lua — FSM-managed container with mirror
-- States: closed/open × mirror intact/broken. Container: top + drawer + mirror_shelf.
return {
    guid = "{eda1257d-8240-4c75-9c1b-a7be349a60f5}",
    template = "furniture",

    id = "vanity",
    material = "oak",
    is_mirror = true,
    keywords = {"vanity", "mirror", "vanity mirror", "dressing table", "desk", "table", "looking glass", "oak vanity", "reflection", "my reflection"},
    size = 8,
    weight = 40,
    categories = {"furniture", "wooden", "reflective"},
    room_position = "sits against the east wall",
    portable = false,
    on_smell = "Faint perfume -- rosewater and something powdery, trapped in the wood grain for years.",

    -- Initial state (closed, mirror intact)
    name = "an oak vanity",
    description = "A solid oak vanity, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality. A single drawer sits closed at the front, its brass pull green with age.",
    room_presence = "An oak vanity with an ornate mirror sits against one wall, its surface darkened by years of smoke.",
    on_feel = "Smooth oak surface, slightly sticky with old cosmetics. The mirror glass is cold and flat. A brass drawer pull, green with age.",

    surfaces = {
        top = { capacity = 6, max_item_size = 4, contents = {} },
        inside = { capacity = 4, max_item_size = 2, contents = {}, accessible = false },
        mirror_shelf = { capacity = 2, max_item_size = 1, contents = {} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        text = text .. "\n\nYour reflection stares back from the mirror, mimicking your movements with an unsettling half-second delay."
        if self.surfaces and self.surfaces.top and #self.surfaces.top.contents > 0 then
            text = text .. "\nOn the vanity's surface:"
            for _, id in ipairs(self.surfaces.top.contents) do
                text = text .. "\n  " .. id
            end
        end
        text = text .. "\nThe drawer is closed."
        return text
    end,

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "an oak vanity",
            description = "A solid oak vanity, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality. A single drawer sits closed at the front, its brass pull green with age.",
            room_presence = "An oak vanity with an ornate mirror sits against one wall, its surface darkened by years of smoke.",
            on_feel = "Smooth oak surface, slightly sticky with old cosmetics. The mirror glass is cold and flat. A brass drawer pull, green with age.",
            on_smell = "Faint perfume -- rosewater and something powdery, trapped in the wood grain for years.",

            surfaces = {
                top = { capacity = 6, max_item_size = 4, contents = {} },
                inside = { capacity = 4, max_item_size = 2, contents = {}, accessible = false },
                mirror_shelf = { capacity = 2, max_item_size = 1, contents = {} },
            },

            on_look = function(self)
                local text = self.description
                text = text .. "\n\nYour reflection stares back from the mirror, mimicking your movements with an unsettling half-second delay."
                if self.surfaces and self.surfaces.top and #self.surfaces.top.contents > 0 then
                    text = text .. "\nOn the vanity's surface:"
                    for _, id in ipairs(self.surfaces.top.contents) do
                        text = text .. "\n  " .. id
                    end
                end
                text = text .. "\nThe drawer is closed."
                return text
            end,
        },

        open = {
            name = "an oak vanity (drawer open)",
            description = "A solid oak vanity, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The brass-handled drawer hangs open, its dark interior exposed.",
            room_presence = "An oak vanity with a drawer hanging open sits against one wall, its mirror reflecting the room.",
            on_feel = "Smooth oak surface, slightly sticky with old cosmetics. The mirror glass is cold and flat. The drawer hangs open.",
            on_smell = "Faint perfume -- rosewater and something powdery, now mingling with the musty air of the open drawer.",

            surfaces = {
                top = { capacity = 6, max_item_size = 4, contents = {} },
                inside = { capacity = 4, max_item_size = 2, contents = {}, accessible = true },
                mirror_shelf = { capacity = 2, max_item_size = 1, contents = {} },
            },

            on_look = function(self)
                local text = self.description
                text = text .. "\n\nYour reflection stares back from the mirror."
                if self.surfaces and self.surfaces.inside then
                    local inside = self.surfaces.inside.contents or {}
                    if #inside == 0 then
                        text = text .. "\nThe drawer yawns open. It is empty."
                    else
                        text = text .. "\nInside the drawer:"
                        for _, id in ipairs(inside) do
                            text = text .. "\n  " .. id
                        end
                    end
                end
                return text
            end,
        },

        closed_broken = {
            name = "an oak vanity (mirror broken)",
            description = "A solid oak vanity, still sturdy despite the violence visited upon it. Where an ornate mirror once stood, only the gilt frame remains -- a jagged crown of broken glass teeth jutting from the backing. Glittering shards dust the vanity's surface. Seven years bad luck, by the old reckoning.",
            room_presence = "An oak vanity with a shattered mirror sits against the wall, glittering shards dusting its surface.",
            on_feel = "Smooth oak surface -- CAREFUL. Tiny glass shards dust the top. Your fingers find jagged edges where the mirror frame meets broken glass.",
            on_smell = "Faint perfume and the sharp, mineral scent of freshly broken glass.",
            weight = 38,
            categories = {"furniture", "wooden"},

            surfaces = {
                top = { capacity = 6, max_item_size = 4, contents = {} },
                inside = { capacity = 4, max_item_size = 2, contents = {}, accessible = false },
            },

            on_look = function(self)
                local text = self.description
                if self.surfaces and self.surfaces.top and #self.surfaces.top.contents > 0 then
                    text = text .. "\n\nOn the vanity's surface:"
                    for _, id in ipairs(self.surfaces.top.contents) do
                        text = text .. "\n  " .. id
                    end
                end
                text = text .. "\nThe drawer is closed."
                return text
            end,
        },

        open_broken = {
            name = "an oak vanity (drawer open, mirror broken)",
            description = "A solid oak vanity, still sturdy despite the violence visited upon it. Where an ornate mirror once stood, only the gilt frame remains -- jagged glass teeth jutting from the backing. The brass-handled drawer hangs open.",
            room_presence = "An oak vanity with a broken mirror and an open drawer sits against the wall, shards of glass glinting on its surface.",
            on_feel = "Smooth oak surface -- CAREFUL. Glass shards everywhere. The drawer hangs open, its interior dusty.",
            on_smell = "Faint perfume and the mineral tang of broken glass.",
            weight = 38,
            categories = {"furniture", "wooden"},

            surfaces = {
                top = { capacity = 6, max_item_size = 4, contents = {} },
                inside = { capacity = 4, max_item_size = 2, contents = {}, accessible = true },
            },

            on_look = function(self)
                local text = self.description
                if self.surfaces and self.surfaces.inside then
                    local inside = self.surfaces.inside.contents or {}
                    if #inside == 0 then
                        text = text .. "\n\nThe drawer yawns open. It is empty."
                    else
                        text = text .. "\n\nInside the drawer:"
                        for _, id in ipairs(inside) do
                            text = text .. "\n  " .. id
                        end
                    end
                end
                return text
            end,
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You pull the brass handle. The drawer slides open with a soft scrape, releasing a breath of old perfume.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You push the drawer shut with a click.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed_broken", to = "open_broken", verb = "open",
            message = "You pull the drawer open, careful to avoid the glass shards on the surface.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open_broken", to = "closed_broken", verb = "close",
            message = "You push the drawer shut, wincing as glass crunches under your fingers.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "closed", to = "closed_broken", verb = "break",
            aliases = {"smash", "shatter", "break_mirror"},
            spawns = {"glass-shard"},
            message = "You drive your fist into the mirror. It shatters with a crystalline scream, shards cascading across the vanity's surface. Seven years bad luck.",
            mutate = {
                keywords = { add = "broken" },
            },
        },
        {
            from = "open", to = "open_broken", verb = "break",
            aliases = {"smash", "shatter", "break_mirror"},
            spawns = {"glass-shard"},
            message = "You drive your fist into the mirror. It shatters with a crystalline scream, shards cascading across the vanity's surface and into the open drawer. Seven years bad luck.",
            mutate = {
                keywords = { add = "broken" },
            },
        },
    },
}
