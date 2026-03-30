-- drawer.lua — Standalone drawer object (detached from nightstand)
-- FSM: closed → open (simple open/close)
-- Can be detached from nightstand via composite part system,
-- or spawned independently via room nesting.

return {
    guid = "{83dda7fe-c35c-4af7-94a0-346601e6d864}",
    template = "furniture",

    id = "drawer",
    name = "a small drawer",
    material = "oak",
    keywords = {"drawer", "small drawer", "nightstand drawer"},
    description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep. It has a small handle on the front.",
    size = 3,
    weight = 2,
    categories = {"furniture", "wooden", "container"},
    portable = true,
    hands_required = 2,

    container = true,
    openable = true,
    accessible = false,
    capacity = 2,
    max_item_size = 1,

    on_feel = "Wood, smooth but slightly sticky from old wax. There's a small handle on the front.",
    on_smell = "Pine wood, lingering candle wax.",
    on_listen = "Hollow, wooden sound when tapped.",

    location = nil,

    sounds = {
        ["on_verb_open"] = "container-open.opus",
        ["on_verb_close"] = "container-close.opus",
    },

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a small drawer",
            description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep. The drawer is closed.",
            on_feel = "Wood, smooth but slightly sticky from old wax. There's a small handle on the front. The drawer is shut.",
            accessible = false,

            on_look = function(self)
                return self.description
            end,
        },

        open = {
            name = "a small drawer",
            description = "A shallow wooden drawer, about 12 inches wide and 6 inches deep. The drawer is open.",
            on_feel = function(self)
                local n = self.contents and #self.contents or 0
                if n > 0 then
                    return "Wood, smooth but slightly sticky from old wax. There's something inside."
                end
                return "Wood, smooth but slightly sticky from old wax. It is empty."
            end,
            accessible = true,

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
        },
    },

    transitions = {
        {
            from = "closed", to = "open", verb = "open",
            message = "You pull the small drawer open. It slides out with a soft wooden scrape.",
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
    },

    -- Reattach metadata for composite part system
    reattach_to = "nightstand",

    mutations = {},
}
