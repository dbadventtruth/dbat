local act = require("lua.libs.act")

return {
    act = act.message,
    render = act.render,
    render_for = act.render_for,
    send_room = act.to_room,
}
