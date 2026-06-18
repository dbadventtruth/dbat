local dbat = require("dbat")
local object = require("lua.objects.object")
local WEAR  = dbat.consts.wear_positions
local PLR   = dbat.consts.player_flags
local EF    = dbat.consts.item_extra_flags
local wear_where = dbat.consts.wear_where
local NUM_WEARS  = dbat.consts.NUM_WEARS

local HEADER = "        @YEquipment Being Worn\r\n@D-------------------------------------@w\r\n"
local SHEATH_PREFIX = "@D  ---- @YSheathed@D ----@c> @n"
local BOTH_HANDS    = "@c<@CWielded by B. Hands@c>@n "

local function execute(ctx)
    local ch = ctx.ch
    ch:send(HEADER)

    local thandw = ch:player_flagged(PLR.THANDW)

    -- C loop runs from 1 (not 0) to NUM_WEARS-1 inclusive
    for slot = 1, NUM_WEARS - 1 do
        local item = ch:equipment(slot)
        local is_wield = (slot == WEAR.WIELD1 or slot == WEAR.WIELD2)

        if item and ch:can_see_obj(item) then
            local prefix
            if is_wield and thandw then
                prefix = BOTH_HANDS
            else
                prefix = wear_where[slot]
            end
            ch:send(prefix .. object.render_inventory_line(item, ch))

            -- Sheath contents (not shown when two-handing)
            if item:extra_flagged(EF.SHEATH) and not (is_wield and thandw) then
                for obj2 in item:inventory() do
                    ch:send(SHEATH_PREFIX .. object.render_inventory_line(obj2, ch))
                end
            end
        else
            -- Empty slot: only show if character has that body part
            local show_nothing = ch:body_flagged(slot) and
                (slot ~= WEAR.WIELD2 or not thandw)
            if show_nothing then
                ch:send(wear_where[slot] .. "@wNothing.@n\r\n")
            end
        end
    end
end

return {
    id = "equipment",
    aliases = { { "equipment", 2 } },
    execute = execute,
}
