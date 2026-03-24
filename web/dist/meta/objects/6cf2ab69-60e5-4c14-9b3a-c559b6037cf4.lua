-- chest.lua — Standalone wooden chest (portable two-handed container)
-- Design doc: docs/objects/chest.md
-- FSM: closed ↔ open (simple open/close with sensory gating)
-- Material: oak (from material registry)
-- Container: 8 slots, max item size 3, weight capacity 30
-- Two-handed carry: hands_required = 2

return {
    guid = "{6cf2ab69-60e5-4c14-9b3a-c559b6037cf4}",
    template = "furniture",

    id = "chest",
    name = "a wooden chest",
    material = "oak",
    keywords = {"chest", "trunk", "storage", "wooden chest", "heavy chest", "treasure chest"},
    description = "A substantial oak chest bound with iron bands. A brass latch holds the heavy lid firmly shut. The wood is smooth with age, the ironwork cold to the touch.",
    size = 5,
    weight = 20,
    categories = {"container", "furniture", "wooden"},
    portable = true,
    hands_required = 2,

    container = true,
    openable = true,
    accessible = false,
    capacity = 8,
    weight_capacity = 30,
    max_item_size = 3,

    on_feel = "Wood smooth with age, iron bands cold under your fingers. The brass latch is sturdy. Heavy to lift.",
    on_smell = "Old wood, faint iron, storage mustiness.",
    on_listen = "Hollow, resonant sound when tapped. The latch clicks faintly.",

    location = nil,

    -- FSM
    initial_state = "closed",
    _state = "closed",

    states = {
        closed = {
            name = "a wooden chest",
            description = "A substantial oak chest bound with iron bands. A brass latch holds the heavy lid firmly shut. The wood is smooth with age, the ironwork cold to the touch.",
            on_feel = "Wood smooth with age, iron bands cold under your fingers. The brass latch is sturdy. The lid is shut tight.",
            on_smell = "Old wood, faint iron, storage mustiness seeps through the grain.",
            on_listen = "A hollow *bonk* when tapped. Sounds sealed.",
            accessible = false,

            on_look = function(self)
                return self.description
            end,
        },

        open = {
            name = "a wooden chest (open)",
            description = "A substantial oak chest, its heavy lid propped open on stiff iron hinges. The interior is lined with faded cloth, worn thin at the corners. The hinges show years of wear.",
            on_feel = function(self)
                local n = self.contents and #self.contents or 0
                if n > 0 then
                    return "Smooth interior surfaces, cloth lining soft with dust. There's something inside."
                end
                return "Smooth interior surfaces, cloth lining soft with dust. It is empty."
            end,
            on_smell = "Cedar and old leather -- this chest has stored something once considered valuable. Cloth and sealed air mingle with the oak.",
            on_listen = "A quiet interior. The hinges groan faintly if jostled.",
            accessible = true,

            on_look = function(self, registry)
                local text = "A substantial oak chest, its heavy lid propped open on stiff iron hinges. The interior is lined with faded cloth."
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
            message = "The iron latch yields with a satisfying *click*. The heavy lid groans open on stiff hinges, releasing a breath of stale, sealed air.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "You lower the heavy lid. It settles with a deep wooden *thud* and the latch catches with a click.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
    },

    mutations = {},
}
