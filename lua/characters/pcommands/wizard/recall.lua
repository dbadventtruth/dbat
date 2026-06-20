local dbat = require("dbat")

local function execute(ctx)
    local ch = ctx.ch
    if ch:admin_level_get() < 1 then
        ch:send_line("You are not an immortal!")
        return
    end
    local room = dbat.rooms.by_id(2)
    if not room then return end
    ch:send_line("You disappear in a burst of light!")
    ch:act_around("$n disappears in a burst of light!")
    ch:from_room()
    ch:to_room(room)
    ch:look_at_room()
    ch:loadroom_set(ch:room_get():vnum_get())
end

return { id = "recall", aliases = { { "recall", 6 } }, execute = execute }
