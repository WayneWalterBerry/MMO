-- nightstand.lua — FSM-managed container (reversible open/close)
-- States: closed <-> open. Container with top + drawer compartments.
return {
    guid = "d40b15e6-7d64-489e-9324-ea00fb915602",

    id = "nightstand",
    keywords = {"nightstand", "night stand", "bedside table", "side table", "small table", "drawer"},
    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    room_position = "stands beside the bed",
    portable = false,
    on_smell = "Old pine wood and melted tallow.",

    -- Initial state properties (closed)
    name = "a small nightstand",
    description = "A squat nightstand of knotted pine, its top crusted with pooled and hardened wax drippings in a frozen cascade. A small drawer sits closed at the front.",
    room_presence = "A small nightstand crusted with candle wax sits against the wall.",
    on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
        inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
    },

    location = nil,

    on_look = function(self, registry)
        local text = self.description
        if self.surfaces and self.surfaces.top then
            local items = self.surfaces.top.contents or {}
            if #items > 0 then
                text = text .. "\n\nOn top:"
                for _, id in ipairs(items) do
                    local item = registry and registry:get(id)
                    text = text .. "\n  " .. (item and item.name or id)
                end
            end
        end
        text = text .. "\nThe drawer is closed."
        return text
    end,
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine, its top crusted with pooled and hardened wax drippings in a frozen cascade. A small drawer sits closed at the front.",
            room_presence = "A small nightstand crusted with candle wax sits against the wall.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",

            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
            },

            on_look = function(self, registry)
                local text = self.description
                if self.surfaces and self.surfaces.top then
                    local items = self.surfaces.top.contents or {}
                    if #items > 0 then
                        text = text .. "\n\nOn top:"
                        for _, id in ipairs(items) do
                            local item = registry and registry:get(id)
                            text = text .. "\n  " .. (item and item.name or id)
                        end
                    end
                end
                text = text .. "\nThe drawer is closed."
                return text
            end,
        },

        open = {
            name = "a small nightstand (drawer open)",
            description = "A squat nightstand of knotted pine. Wax drippings cascade down its side in frozen rivulets. The small drawer is pulled open.",
            room_presence = "A small nightstand with an open drawer sits against the wall, its top crusted with wax.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. The drawer slides open under your fingers.",

            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
                inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = true },
            },

            on_look = function(self, registry)
                local text = self.description
                if self.surfaces and self.surfaces.top then
                    local items = self.surfaces.top.contents or {}
                    if #items > 0 then
                        text = text .. "\n\nOn top:"
                        for _, id in ipairs(items) do
                            local item = registry and registry:get(id)
                            text = text .. "\n  " .. (item and item.name or id)
                        end
                    end
                end
                if self.surfaces and self.surfaces.inside then
                    local inside = self.surfaces.inside.contents or {}
                    if #inside == 0 then
                        text = text .. "\nThe drawer is open. It is empty."
                    else
                        text = text .. "\nInside the drawer:"
                        for _, id in ipairs(inside) do
                            local item = registry and registry:get(id)
                            text = text .. "\n  " .. (item and item.name or id)
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
            message = "You pull the small drawer open. It slides out with a soft wooden scrape.",
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You push the drawer shut with a click.",
        },
    },
}
