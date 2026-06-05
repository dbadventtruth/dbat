const std = @import("std");
const zlua = @import("zlua");

const Lua = zlua.Lua;

pub fn mergeMethods(lua: *Lua, comptime module_name: [:0]const u8) void {
    const top = lua.getTop();
    errdefer lua.setTop(top);

    if (lua.getGlobal("require") != .function) {
        lua.pop(1);
        return;
    }
    _ = lua.pushString(module_name);
    lua.protectedCall(.{ .args = 1, .results = 1 }) catch |err| {
        const message = lua.toString(-1) catch @errorName(err);
        std.log.err("failed to load {s}: {s}", .{ module_name, message });
        lua.pop(1);
        return;
    };

    if (!lua.isTable(-1)) {
        lua.pop(1);
        return;
    }

    lua.pushNil();
    while (lua.next(-2)) {
        lua.pushValue(-2);
        lua.pushValue(-2);
        lua.setTable(-6);
        lua.pop(1);
    }

    lua.pop(1);
}
