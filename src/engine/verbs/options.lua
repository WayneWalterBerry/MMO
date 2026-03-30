-- engine/verbs/options.lua
-- OPTIONS verb handler: contextual hints system.
-- Uses the options engine to generate 1-4 actionable suggestions.

local M = {}

local options_engine = require("engine.options")

function M.register(handlers)
    handlers["options"] = function(ctx, noun)
        -- Initialize options_request_count if not present
        if not ctx.options_request_count then
            ctx.options_request_count = 0
        end

        -- Increment request count
        ctx.options_request_count = ctx.options_request_count + 1

        -- Generate options
        local result = options_engine.generate_options(ctx)

        -- Print flavor text
        print(result.flavor_text)

        -- Check for disabled/delayed messages (no options)
        if #result.options == 0 then
            return
        end

        -- Print numbered options
        for i, opt in ipairs(result.options) do
            print("  " .. i .. ". " .. opt.display)
        end

        -- Store pending options for numbered selection
        ctx.player.pending_options = result.options
    end
end

return M
