-- money-vault.lua — The Money Vault
-- Counting and math puzzle. Difficulty: ★★

return {
    guid = "d2bb7221-c24d-4232-8d3a-ed35fca22c77",
    template = "room",

    id = "money-vault",
    name = "The Money Vault",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    keywords = {"vault", "money vault", "money room", "bank vault"},
    description = "Wow! Stacks of play money are piled high on three tables. "
               .. "Gold coins are scattered across the shiny floor. "
               .. "A giant safe with a number pad sits against the back wall.",
    short_description = "A vault full of play money and a big locked safe.",

    goal = { verb = "enter", noun = "code", label = "crack the safe" },

    on_feel = "The floor is cold and smooth like metal. "
           .. "You feel crisp paper bills on the tables.",

    on_smell = "It smells like fresh paper and a little bit like metal.",

    on_listen = "The room is quiet. You hear a soft hum from the big safe.",

    instances = {},

    exits = {
        north = { target = "beast-studio" },
    },

    mutations = {},
}
