-- money-vault.lua — The Money Vault
-- Counting and math puzzle. Difficulty: ★★

return {
    guid = "d2bb7221-c24d-4232-8d3a-ed35fca22c77",
    template = "room",

    id = "money-vault",
    name = "The Money Vault",
    level = { number = 1, name = "MrBeast's Challenge Arena" },
    sky_visible = false,
    light_level = 2,
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

    instances = {
        { id = "vault-sign", type = "Vault Sign", type_id = "{778317B4-33D6-41AD-8C36-4D388BED55D6}" },
        { id = "vault-safe", type = "Vault Safe", type_id = "{5143D970-B69E-4475-B0CF-ACBE61046C0E}" },
        { id = "money-table-one", type = "Red Money Table", type_id = "{63032BC1-E9B5-4B41-9E29-BC268291EE8B}",
            on_top = {
                { id = "money-card-one", type = "Card One", type_id = "{B92FF256-80A9-44A4-99E5-605D4A94219B}" },
            },
        },
        { id = "money-table-two", type = "Blue Money Table", type_id = "{0A803D74-B5EE-4408-A2BA-3780411CEC77}",
            on_top = {
                { id = "money-card-two", type = "Card Two", type_id = "{85DF19E7-5A97-45D5-96BD-1EF32FDD7AD1}" },
            },
        },
        { id = "money-table-three", type = "Green Money Table", type_id = "{F46A34B9-E513-4814-A011-928B439A54A7}",
            on_top = {
                { id = "money-card-three", type = "Card Three", type_id = "{8629E7E7-A92F-4176-A9C3-E32AE94A2033}" },
            },
        },
        { id = "gold-coins", type = "Gold Coins", type_id = "{0E2F262D-2AFB-478C-B38A-4B314840C9A9}" },
    },

    exits = {
        north = { target = "beast-studio" },
    },

    mutations = {},
}
