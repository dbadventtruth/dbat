const std = @import("std");
const argon2 = std.crypto.pwhash.argon2;

var global_allocator: std.mem.Allocator = undefined;
var global_io: std.Io = undefined;

const hash_params = argon2.Params{ .t = 3, .m = 32768, .p = 1 };

pub fn init(allocator: std.mem.Allocator, io: std.Io) void {
    global_allocator = allocator;
    global_io = io;
}

pub export fn password_is_hashed(pass: [*:0]const u8) bool {
    return std.mem.startsWith(u8, std.mem.sliceTo(pass, 0), "$argon2");
}

pub export fn password_hash(password: [*:0]const u8, buf: [*]u8, buf_len: usize) bool {
    const pw = std.mem.sliceTo(password, 0);
    const out = buf[0..buf_len];
    const result = argon2.strHash(pw, .{
        .allocator = global_allocator,
        .params = hash_params,
        .mode = .argon2id,
    }, out, global_io) catch return false;
    if (result.len >= buf_len) return false;
    buf[result.len] = 0;
    return true;
}

pub export fn password_verify(hash_str: [*:0]const u8, password: [*:0]const u8) bool {
    const h = std.mem.sliceTo(hash_str, 0);
    const pw = std.mem.sliceTo(password, 0);
    argon2.strVerify(h, pw, .{ .allocator = global_allocator }, global_io) catch return false;
    return true;
}
