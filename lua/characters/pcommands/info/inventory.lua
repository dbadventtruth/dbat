local dbat = require("dbat")
local object = require("lua.objects.object")
local PLR = dbat.consts.player_flags
local PRF = dbat.consts.prf_flags

local HEADER = "@w              @YInventory\r\n@D-------------------------------------@w\r\n"

local function execute(ctx)
    local ch = ctx.ch
    ch:send(HEADER)

    if ch:player_flagged(PLR.STOLEN) then
        ch:player_flag_set(PLR.STOLEN, false)
        ch:send("@r   --------------------------------------------------@n\n")
        ch:send("@R    You notice that you have been robbed sometime recently!\n")
        ch:send("@r   --------------------------------------------------@n\n")
        return
    end

    -- Collect inventory into a table (ch:inventory() returns an iterator)
    local items = {}
    for obj in ch:inventory() do
        items[#items + 1] = obj
    end

    if #items == 0 then
        ch:send(" Nothing.\r\n")
        ch:send("\n")
        return
    end

    -- Walk items in order; track which indices have already been grouped.
    local shown = {}
    local found = false
    local holylight = ch:pref_flagged(PRF.HOLYLIGHT)

    for i = 1, #items do
        if not shown[i] then
            local obj = items[i]
            -- Skip objects whose description starts with '.' (hidden items)
            -- unless viewer has PRF_HOLYLIGHT; also skip undefined descriptions
            local desc = obj:description_get()
            local sdesc = obj:short_description_get()
            if not (desc and desc ~= "" and desc ~= "undefined" and
                    (desc:sub(1,1) ~= '.' or holylight) and
                    sdesc and sdesc:sub(1,1) ~= '.') then
                shown[i] = true
                goto continue
            end

            if not ch:can_see_obj(obj) then
                shown[i] = true
                goto continue
            end

            -- Count matching objects later in the list
            local key = obj:stack_key()
            local count = 1
            shown[i] = true

            for j = i + 1, #items do
                if not shown[j] then
                    local other = items[j]
                    if ch:can_see_obj(other) and other:stack_key() == key then
                        count = count + 1
                        shown[j] = true
                    end
                end
            end

            if count > 1 then
                ch:send(string.format("@D(@Rx@Y%2i@D)@n ", count))
            end
            ch:send(object.render_inventory_line(obj, ch))
            found = true
        end
        ::continue::
    end

    if not found then
        ch:send(" Nothing.\r\n")
    end

    ch:send("\n")
end

return {
    id = "inventory",
    aliases = { { "inventory", 3 } },
    execute = execute,
}
