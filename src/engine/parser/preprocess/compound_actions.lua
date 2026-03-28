-- engine/parser/preprocess/compound_actions.lua
-- Compound action transforms.

local data = require("engine.parser.preprocess.data")

local compound = {}

function compound.transform_compound_actions(text)
    local first_word = text:match("^(%S+)")
    if first_word and data.HIT_SYNONYMS[first_word] then
        return "hit" .. text:sub(#first_word + 1)
    end

    local hurt_target = text:match("^hurt%s+(.+)$")
    if hurt_target then
        return "hit " .. hurt_target
    end

    local beat_up_target = text:match("^beat%s+(.+)%s+up$")
    if beat_up_target then
        return "hit " .. beat_up_target
    end
    local beat_up_target2 = text:match("^beat%s+up%s+(.+)$")
    if beat_up_target2 then
        return "hit " .. beat_up_target2
    end

    if text:match("^headbutt") then
        return "hit head"
    end

    if text == "bonk" then return "hit head" end
    local bonk_noun = text:match("^bonk%s+(.+)$")
    if bonk_noun then
        local cleaned = bonk_noun:gsub("^my%s+", ""):gsub("^your%s+", "")
        if cleaned == "myself" or cleaned == "self" or cleaned == "me"
            or cleaned == "yourself" then
            return "hit head"
        end
        return "hit " .. bonk_noun
    end

    local WASH_SYNONYMS = { clean=true, rinse=true, scrub=true, wash=true }
    if first_word and WASH_SYNONYMS[first_word] then
        local rest = text:sub(#first_word + 1)
        local item_in, target_in = rest:match("^%s+(.+)%s+in%s+(.+)$")
        if item_in then
            return "wash " .. item_in .. " in " .. target_in
        end
        local item_w, target_w = rest:match("^%s+(.+)%s+with%s+(.+)$")
        if item_w then
            return "wash " .. item_w .. " in " .. target_w
        end
        if first_word ~= "wash" then
            return "wash" .. rest
        end
    end

    local pour_item, pour_target = text:match("^pour%s+(.+)%s+into%s+(.+)$")
    if not pour_item then
        pour_item, pour_target = text:match("^pour%s+(.+)%s+in%s+(.+)$")
    end
    if pour_item then
        return "pour " .. pour_item .. " into " .. pour_target
    end

    -- #320: "insert X into Y" — route to unlock for locks, put for containers
    local insert_item, insert_target = text:match("^insert%s+(.+)%s+into%s+(.+)$")
    if insert_item then
        if insert_target:match("lock") or insert_target:match("keyhole") then
            return "unlock " .. insert_target .. " with " .. insert_item
        end
        return "put " .. insert_item .. " in " .. insert_target
    end

    local fill_target, fill_source = text:match("^fill%s+(.+)%s+with%s+(.+)$")
    if fill_target and fill_source then
        return "pour " .. fill_source .. " into " .. fill_target
    end

    local apply_item, apply_target = text:match("^apply%s+(.+)%s+to%s+(.+)$")
    if apply_item then
        return "apply " .. apply_item .. " to " .. apply_target
    end

    local rub_item, rub_target = text:match("^rub%s+(.+)%s+on%s+(.+)$")
    if not rub_item then
        rub_item, rub_target = text:match("^rub%s+(.+)%s+to%s+(.+)$")
    end
    if not rub_item then
        rub_item, rub_target = text:match("^rub%s+(.+)%s+into%s+(.+)$")
    end
    if rub_item then
        return "apply " .. rub_item .. " to " .. rub_target
    end

    local pry_target = text:match("^pry%s+open%s+(.+)")
    if pry_target then
        return "open " .. pry_target
    end

    local pry_noun, pry_tool = text:match("^pry%s+(.+)%s+with%s+(.+)$")
    if pry_noun and pry_tool then
        return "open " .. pry_noun .. " with " .. pry_tool
    end

    local force_target = text:match("^force%s+open%s+(.+)")
    if force_target then
        return "open " .. force_target
    end

    local crowbar_target = text:match("^use%s+crowbar%s+on%s+(.+)")
        or text:match("^use%s+bar%s+on%s+(.+)")
        or text:match("^use%s+pry%s*bar%s+on%s+(.+)")
    if crowbar_target then
        return "open " .. crowbar_target
    end

    if text:match("^report%s+a?%s*bug")
        or text:match("^bug%s+report")
        or text:match("^file%s+a?%s*bug") then
        return "report_bug"
    end

    local pull_target = text:match("^take%s+out%s+(.+)")
        or text:match("^pull%s+out%s+(.+)")
        or text:match("^yank%s+out%s+(.+)")
    if pull_target then
        return "pull " .. pull_target
    end

    if text == "pick up" then
        return "take"
    end

    local roll_target = text:match("^roll%s+up%s+(.+)")
        or text:match("^roll%s+(.+)%s+up$")
    if roll_target then
        return "move " .. roll_target
    end

    local pullback_target = text:match("^pull%s+back%s+(.+)")
    if pullback_target then
        return "move " .. pullback_target
    end

    local uncork_target = text:match("^pop%s+(.+)")
    if uncork_target and uncork_target:match("cork") then
        return "uncork bottle"
    end

    local use_tool, use_target = text:match("^use%s+(.+)%s+on%s+(.+)$")
    if use_tool and use_target then
        if use_tool:match("needle") or use_tool:match("thread") then
            return "sew " .. use_target .. " with " .. use_tool
        end
        if use_tool:match("key") then
            return "unlock " .. use_target .. " with " .. use_tool
        end
        if use_tool:match("match") or use_tool:match("lighter")
            or use_tool:match("flint") or use_tool:match("torch")
            or use_tool:match("fire") or use_tool:match("flame") then
            return "light " .. use_target .. " with " .. use_tool
        end
        return "apply " .. use_tool .. " to " .. use_target
    end

    local set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(in)%s+(.+)$")
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(on)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(under)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(inside)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(underneath)%s+(.+)$")
    end
    if not set_item then
        set_item, set_prep, set_target = text:match("^set%s+(.+)%s+(beneath)%s+(.+)$")
    end
    if set_item then
        return "put " .. set_item .. " " .. set_prep .. " " .. set_target
    end

    local drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(on)%s+(.+)$")
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(in)%s+(.+)$")
    end
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(under)%s+(.+)$")
    end
    if not drop_item then
        drop_item, drop_prep, drop_target = text:match("^drop%s+(.+)%s+(inside)%s+(.+)$")
    end
    if drop_item then
        return "put " .. drop_item .. " " .. drop_prep .. " " .. drop_target
    end

    local hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(under)%s+(.+)$")
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(underneath)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(beneath)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(in)%s+(.+)$")
    end
    if not hide_item then
        hide_item, hide_prep, hide_target = text:match("^hide%s+(.+)%s+(inside)%s+(.+)$")
    end
    if hide_item then
        return "put " .. hide_item .. " " .. hide_prep .. " " .. hide_target
    end

    local stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+in%s+(.+)$")
    if not stuff_item then
        stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+inside%s+(.+)$")
    end
    if not stuff_item then
        stuff_item, stuff_target = text:match("^stuff%s+(.+)%s+into%s+(.+)$")
    end
    if stuff_item then
        return "put " .. stuff_item .. " in " .. stuff_target
    end

    for _, toss_verb in ipairs({"toss", "throw"}) do
        local toss_rest = text:match("^" .. toss_verb .. "%s+(.+)$")
        if toss_rest then
            local t_item, t_target
            t_item, t_target = toss_rest:match("^(.+)%s+onto%s+(.+)$")
            if t_item then return "put " .. t_item .. " on " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+into%s+(.+)$")
            if t_item then return "put " .. t_item .. " in " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+on%s+(.+)$")
            if t_item then return "put " .. t_item .. " on " .. t_target end
            t_item, t_target = toss_rest:match("^(.+)%s+in%s+(.+)$")
            if t_item then return "put " .. t_item .. " in " .. t_target end
            return "drop " .. toss_rest
        end
    end

    local slide_item, slide_target = text:match("^slide%s+(.+)%s+under%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " under " .. slide_target
    end
    slide_item, slide_target = text:match("^slide%s+(.+)%s+underneath%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " under " .. slide_target
    end
    slide_item, slide_target = text:match("^slide%s+(.+)%s+into%s+(.+)$")
    if slide_item then
        return "put " .. slide_item .. " in " .. slide_target
    end

    local push_back_target = text:match("^push%s+(.+)%s+back")
    if push_back_target then
        return "put " .. push_back_target .. " in " .. push_back_target
    end

    local heave_target = text:match("^heave%s+(.+)%s+up$")
    if heave_target then return "lift " .. heave_target end
    heave_target = text:match("^heave%s+up%s+(.+)$")
    if heave_target then return "lift " .. heave_target end

    local drag_target = text:match("^drag%s+(.+)%s+across$")
    if drag_target then return "move " .. drag_target end
    drag_target = text:match("^drag%s+(.+)%s+along$")
    if drag_target then return "move " .. drag_target end

    local shove_target = text:match("^shove%s+(.+)%s+aside$")
        or text:match("^shove%s+(.+)%s+away$")
        or text:match("^shove%s+(.+)%s+over$")
    if shove_target then return "push " .. shove_target end

    local nudge_target = text:match("^nudge%s+(.+)%s+aside$")
        or text:match("^nudge%s+(.+)%s+over$")
    if nudge_target then return "push " .. nudge_target end

    local put_back_item, put_back_target2 = text:match("^put%s+(.+)%s+back%s+in%s+(.+)")
    if put_back_item then
        return "put " .. put_back_item .. " in " .. put_back_target2
    end

    local extinguish_target = text:match("^put%s+out%s+(.+)")
        or text:match("^blow%s+out%s+(.+)")
    if extinguish_target then
        return "extinguish " .. extinguish_target
    end

    local put_wear_item, put_wear_part
    put_wear_item, put_wear_part = text:match("^put%s+(.+)%s+on%s+my%s+(%S+)$")
    if not put_wear_item then
        put_wear_item, put_wear_part = text:match("^put%s+(.+)%s+on%s+(%S+)$")
    end
    if put_wear_item and put_wear_part and data.BODY_PARTS[put_wear_part] then
        return "wear " .. put_wear_item
    end

    local wear_target = text:match("^put%s+on%s+(.+)")
        or text:match("^dress%s+in%s+(.+)")
    if wear_target then
        return "wear " .. wear_target
    end

    local remove_target = text:match("^take%s+off%s+(.+)")
    if remove_target then
        return "remove " .. remove_target
    end

    return text
end

return compound
