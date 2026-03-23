-- nightstand.lua — Composite object with detachable drawer
-- States: closed/open × with_drawer/without_drawer
-- The drawer is a PART that can be pulled out to become an independent object.

local function look_with_top(self, registry)
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
    return text
end

return {
    guid = "{d40b15e6-7d64-489e-9324-ea00fb915602}",
    template = "furniture",

    id = "nightstand",
    material = "oak",
    keywords = {"nightstand", "night stand", "bedside table", "side table", "small table"},
    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    room_position = "stands beside the bed",
    portable = false,
    on_smell = "Old pine wood and melted tallow.",

    -- Initial state properties (closed_with_drawer)
    name = "a small nightstand",
    description = "A squat nightstand of knotted pine, its top crusted with pooled and hardened wax drippings in a frozen cascade. A small drawer sits closed at the front.",
    room_presence = "A small nightstand crusted with candle wax sits against the wall.",
    on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {} },
    },

    location = nil,

    on_look = function(self, registry)
        return look_with_top(self, registry) .. "\nThe drawer is closed."
    end,

    initial_state = "closed_with_drawer",
    _state = "closed_with_drawer",

    states = {
        closed_with_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine, its top crusted with pooled and hardened wax drippings in a frozen cascade. A small drawer sits closed at the front.",
            room_presence = "A small nightstand crusted with candle wax sits against the wall.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
            on_look = function(self, registry)
                return look_with_top(self, registry) .. "\nThe drawer is closed."
            end,
        },

        open_with_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine. Wax drippings cascade down its side in frozen rivulets. The small drawer is pulled open.",
            room_presence = "A small nightstand with an open drawer sits against the wall, its top crusted with wax.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. The drawer slides open under your fingers.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
            on_look = function(self, registry)
                return look_with_top(self, registry) .. "\nThe drawer is pulled open."
            end,
        },

        closed_without_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine, its top crusted with wax drippings. The front has an empty rectangular slot where a drawer used to be.",
            room_presence = "A small nightstand sits against the wall, a dark slot gaping where its drawer used to be.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. Your fingers find an empty slot at the front where the drawer was.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
            on_look = function(self, registry)
                return look_with_top(self, registry) .. "\nThe drawer slot is empty."
            end,
        },

        open_without_drawer = {
            name = "a small nightstand",
            description = "A squat nightstand of knotted pine, its top crusted with wax drippings. The front has an empty rectangular slot where a drawer used to be.",
            room_presence = "A small nightstand sits against the wall, a dark slot gaping where its drawer used to be.",
            on_feel = "Smooth wooden surface, crusted with hardened wax drippings. Your fingers find an empty slot at the front where the drawer was.",
            surfaces = {
                top = { capacity = 3, max_item_size = 2, contents = {} },
            },
            on_look = function(self, registry)
                return look_with_top(self, registry) .. "\nThe drawer slot is empty."
            end,
        },
    },

    transitions = {
        -- Open/close with drawer present
        {
            from = "closed_with_drawer", to = "open_with_drawer", verb = "open",
            message = "You pull the small drawer open. It slides out with a soft wooden scrape.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open_with_drawer", to = "closed_with_drawer", verb = "close",
            message = "You push the drawer shut with a click.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        -- Detach drawer (open state only — must open before pulling out)
        {
            from = "open_with_drawer", to = "open_without_drawer", verb = "detach_part",
            trigger = "detach_part",
            part_id = "drawer",
            message = "You grip the drawer and pull it free from the nightstand. It comes loose with a scrape of wood on wood.",
            mutate = {
                weight = function(w) return w - 2 end,
            },
        },
        -- Reattach drawer
        {
            from = "closed_without_drawer", to = "closed_with_drawer", verb = "reattach_part",
            trigger = "reattach_part",
            part_id = "drawer",
            message = "You slide the drawer back into the nightstand. It fits snugly with a satisfying click.",
            mutate = {
                weight = function(w) return w + 2 end,
            },
        },
        {
            from = "open_without_drawer", to = "open_with_drawer", verb = "reattach_part",
            trigger = "reattach_part",
            part_id = "drawer",
            message = "You slide the drawer back into the nightstand. It fits with a soft scrape.",
            mutate = {
                weight = function(w) return w + 2 end,
            },
        },
    },

    -- === COMPOSITE PARTS ===
    parts = {
        drawer = {
            id = "nightstand-drawer",
            detachable = true,
            reversible = true,
            -- drawer is a first-class container; no parent surface mapping needed
            keywords = {"drawer", "small drawer", "nightstand drawer"},
            name = "a small drawer",
            description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep.",
            size = 3,
            weight = 2,
            categories = {"furniture", "wooden", "container"},
            portable = true,
            hands_required = 2,
            carries_contents = true,
            on_feel = "Wood, smooth but slightly sticky from old wax. There's a small handle on the front.",
            on_smell = "Pine wood, lingering candle wax.",
            on_listen = "Hollow, wooden sound when tapped.",
            detach_verbs = {"pull", "remove", "yank", "tug", "extract"},
            detach_message = "You grip the drawer and pull it free from the nightstand. It comes loose with a scrape of wood on wood.",
            requires_state_match = "open_with_drawer",
            blocked_message = "The drawer is closed. You need to open it first before you can pull it out.",

            factory = function(parent)
                -- Drawer contents come from room-file nesting, not parent surfaces
                return {
                    guid = "drawer-inst-" .. math.random(100000, 999999),
                    id = "nightstand-drawer",
                    keywords = {"drawer", "small drawer", "nightstand drawer"},
                    name = "a small drawer",
                    description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep. It has a small handle on the front.",
                    size = 3,
                    weight = 2,
                    categories = {"furniture", "wooden", "container"},
                    portable = true,
                    hands_required = 2,
                    container = true,
                    reattach_to = "nightstand",
                    on_smell = "Pine wood, lingering candle wax.",
                    on_listen = "Hollow, wooden sound when tapped.",
                    on_feel = function(self)
                        local n = self.contents and #self.contents or 0
                        if n > 0 then
                            return "Wood, smooth but slightly sticky from old wax. There's something inside."
                        end
                        return "Wood, smooth but slightly sticky from old wax. It is empty."
                    end,
                    on_look = function(self, registry)
                        local text = "A shallow wooden drawer, about 12 inches wide and 6 inches deep."
                        local items = self.contents or {}
                        if #items == 0 then
                            text = text .. " It is empty."
                        else
                            text = text .. "\nInside:"
                            for _, id in ipairs(items) do
                                local item = registry and registry:get(id)
                                text = text .. "\n  " .. (item and item.name or id)
                            end
                        end
                        return text
                    end,
                    location = parent.location,
                    contents = {},
                }
            end,
        },

        legs = {
            id = "nightstand-legs",
            detachable = false,
            keywords = {"leg", "legs", "wooden legs", "four legs", "nightstand legs"},
            name = "four wooden legs",
            description = "Four sturdy legs carved from matching pine, holding the nightstand aloft.",
            on_feel = "Solid wood, smooth and well-sanded.",
            on_smell = "Pine wood.",
        },
    },
}
