const std = @import("std");
pub const db = @import("db.zig");

comptime {
    _ = db.real_room;
}
