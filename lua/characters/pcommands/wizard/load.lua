local dbat = require("dbat")
local act  = dbat.lib.act

local function execute(ctx)
    local ch   = ctx.ch
    local toks = ctx.argparams.tokens
    local typ  = string.lower(toks[1] or "")
    local vnum = tonumber(toks[2] or "")
    local cnt  = tonumber(toks[3] or "") or 1

    if typ == "" or not vnum or not string.match(toks[2] or "", "^%d+$") then
        ch:send_line("Usage: load { obj | mob } <vnum> (amt)")
        return
    end

    cnt = math.max(1, math.min(100, math.floor(cnt)))
    local room = ch:room_get()

    if string.sub("mob", 1, #typ) == typ then
        local proto = dbat.mob_protos.by_id(vnum)
        if not proto then
            ch:send_line("There is no monster with that number.")
            return
        end
        for _ = 1, cnt do
            local mob = proto:spawn(room)
            if mob then
                act.to_char(ch, "You create $N.", { actor = ch, target = mob })
                act.around(ch, "$n makes a quaint, magical gesture with one hand.", { actor = ch })
                act.around(ch, "$n has created $N!", { actor = ch, target = mob })
                dbat.dgscripts.load_mtrigger(mob)
            end
        end
    elseif string.sub("obj", 1, #typ) == typ then
        local proto = dbat.obj_protos.by_id(vnum)
        if not proto then
            ch:send_line("There is no object with that number.")
            return
        end
        for _ = 1, cnt do
            local obj = proto:spawn()
            if obj then
                if ch:admin_level_get() > 0 then
                    local imm_msg = string.format("LOAD: %s has loaded a %s", ch:name_get(), obj:short_description_get())
                    dbat.send_to_imm(imm_msg)
                    dbat.log_imm_action(imm_msg)
                end
                if dbat.load_into_inventory then
                    obj:to_char(ch)
                else
                    obj:to_room(room)
                end
                act.to_char(ch, "You create $p.", { actor = ch, tool = obj })
                act.around(ch, "$n makes a strange magical gesture.", { actor = ch })
                act.around(ch, "$n has created $p!", { actor = ch, tool = obj })
                dbat.dgscripts.load_otrigger(obj)
            end
        end
    else
        ch:send_line("That'll have to be either 'obj' or 'mob'.")
    end
end

return { id = "load", aliases = { { "load", 2 } }, execute = execute }
