const std = @import("std");
const cdb = @import("cdb");
const rooms_json = @import("room_json.zig");
const objects_json = @import("object_json.zig");
const characters_json = @import("character_json.zig");
const zones_json = @import("zone_json.zig");
const shops_json = @import("shop_json.zig");
const guilds_json = @import("guild_json.zig");
const dgscripts_json = @import("dgscript_json.zig");

const Allocator = std.mem.Allocator;
const HmacSha256 = std.crypto.auth.hmac.sha2.HmacSha256;
const b64 = std.base64.url_safe_no_pad;
const timing_safe = std.crypto.timing_safe;

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const ParsedRequest = struct {
    method: []const u8,
    path: []const u8,
    body: []const u8,
    headers: [16]Header,
    header_count: usize,

    pub fn getHeader(self: *const ParsedRequest, name: []const u8) ?[]const u8 {
        for (self.headers[0..self.header_count]) |h| {
            if (std.ascii.eqlIgnoreCase(h.name, name)) return h.value;
        }
        return null;
    }
};

pub const Response = struct {
    status: u16,
    status_text: []const u8,
    body: []const u8,
};

// Static key fallback (dev mode when JWT secret not set)
var api_key: []const u8 = "";
pub fn setApiKey(key: []const u8) void {
    api_key = key;
}

// JWT secret — when set, all auth goes through JWT
var jwt_secret: []const u8 = "";
pub fn setJwtSecret(secret: []const u8) void {
    jwt_secret = secret;
}

// JWT header is always the same for HS256
const jwt_header_b64 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9";
const token_lifetime_secs: i64 = 86400; // 24 hours

fn jwtCreate(alloc: Allocator, account: []const u8, adm: i64) ![]u8 {
    const exp: i64 = cdb.time(0) + token_lifetime_secs;
    const payload_json = try std.fmt.allocPrint(
        alloc,
        "{{\"sub\":\"{s}\",\"adm\":{d},\"exp\":{d}}}",
        .{ account, adm, exp },
    );
    const payload_b64_size = b64.Encoder.calcSize(payload_json.len);
    const payload_b64 = try alloc.alloc(u8, payload_b64_size);
    _ = b64.Encoder.encode(payload_b64, payload_json);

    // signing_input = header.payload
    const signing_input = try std.fmt.allocPrint(alloc, "{s}.{s}", .{ jwt_header_b64, payload_b64 });

    var mac: [HmacSha256.mac_length]u8 = undefined;
    HmacSha256.create(&mac, signing_input, jwt_secret);

    const sig_b64_size = b64.Encoder.calcSize(mac.len);
    const sig_b64 = try alloc.alloc(u8, sig_b64_size);
    _ = b64.Encoder.encode(sig_b64, &mac);

    return std.fmt.allocPrint(alloc, "{s}.{s}", .{ signing_input, sig_b64 });
}

const JwtClaims = struct {
    sub: []const u8,
    adm: i64,
    exp: i64,
};

fn jwtVerify(alloc: Allocator, token: []const u8) !JwtClaims {
    // Split into header.payload.signature
    var iter = std.mem.splitScalar(u8, token, '.');
    const header_part = iter.next() orelse return error.MalformedToken;
    const payload_part = iter.next() orelse return error.MalformedToken;
    const sig_part = iter.next() orelse return error.MalformedToken;
    if (iter.next() != null) return error.MalformedToken;

    // Verify signature
    const signing_input = try std.fmt.allocPrint(alloc, "{s}.{s}", .{ header_part, payload_part });
    var expected_mac: [HmacSha256.mac_length]u8 = undefined;
    HmacSha256.create(&expected_mac, signing_input, jwt_secret);

    const sig_decoded_size = b64.Decoder.calcSizeForSlice(sig_part) catch return error.MalformedToken;
    if (sig_decoded_size != HmacSha256.mac_length) return error.MalformedToken;
    var actual_mac: [HmacSha256.mac_length]u8 = undefined;
    b64.Decoder.decode(&actual_mac, sig_part) catch return error.MalformedToken;

    if (!timing_safe.eql([HmacSha256.mac_length]u8, expected_mac, actual_mac))
        return error.InvalidSignature;

    // Decode and parse payload
    const payload_decoded_size = b64.Decoder.calcSizeForSlice(payload_part) catch return error.MalformedToken;
    const payload_json = try alloc.alloc(u8, payload_decoded_size);
    b64.Decoder.decode(payload_json, payload_part) catch return error.MalformedToken;

    const parsed = std.json.parseFromSlice(std.json.Value, alloc, payload_json, .{}) catch return error.MalformedToken;
    const obj = switch (parsed.value) {
        .object => |o| o,
        else => return error.MalformedToken,
    };

    const exp = switch (obj.get("exp") orelse return error.MissingClaim) {
        .integer => |i| i,
        else => return error.MalformedToken,
    };
    if (exp < cdb.time(0)) return error.TokenExpired;

    const sub = switch (obj.get("sub") orelse return error.MissingClaim) {
        .string => |s| s,
        else => return error.MalformedToken,
    };
    const adm = switch (obj.get("adm") orelse return error.MissingClaim) {
        .integer => |i| i,
        else => return error.MalformedToken,
    };

    return JwtClaims{ .sub = sub, .adm = adm, .exp = exp };
}

// Returns admin level from the request's auth header, or -1 if unauthorized.
fn authLevel(alloc: Allocator, request: *const ParsedRequest) i64 {
    const auth_header = request.getHeader("authorization") orelse return -1;
    if (!std.mem.startsWith(u8, auth_header, "Bearer ")) return -1;
    const token = auth_header["Bearer ".len..];

    if (jwt_secret.len > 0) {
        const claims = jwtVerify(alloc, token) catch return -1;
        return claims.adm;
    }
    // Dev fallback: static key
    if (api_key.len > 0 and std.mem.eql(u8, token, api_key)) return 1;
    return -1;
}

pub fn dispatch(alloc: Allocator, request: *const ParsedRequest) !Response {
    const path = request.path;

    // Login does NOT require auth
    if (std.mem.eql(u8, path, "/api/auth/token") and std.mem.eql(u8, request.method, "POST")) {
        return handleAuthToken(alloc, request);
    }

    // Meta endpoints are read-only and do not require auth
    if (std.mem.startsWith(u8, path, "/api/meta/")) {
        return handleMeta(alloc, request, path["/api/meta/".len..]);
    }

    // All other routes require auth (level > 0)
    if (authLevel(alloc, request) <= 0) {
        return .{ .status = 401, .status_text = "Unauthorized", .body = "{\"error\":\"unauthorized\"}" };
    }

    if (std.mem.eql(u8, path, "/api/status")) {
        return handleStatus(alloc);
    }
    if (std.mem.startsWith(u8, path, "/api/rooms/")) {
        return handleRoom(alloc, request, path["/api/rooms/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/objects/")) {
        return handleObject(alloc, request, path["/api/objects/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/mobs/")) {
        return handleMob(alloc, request, path["/api/mobs/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/shops/")) {
        return handleShop(alloc, request, path["/api/shops/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/guilds/")) {
        return handleGuild(alloc, request, path["/api/guilds/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/triggers/")) {
        return handleTrigger(alloc, request, path["/api/triggers/".len..]);
    }
    if (std.mem.startsWith(u8, path, "/api/zones/")) {
        return handleZone(alloc, request, path["/api/zones/".len..]);
    }

    return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"not found\"}" };
}

fn handleAuthToken(alloc: Allocator, request: *const ParsedRequest) !Response {
    const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
        return errorResponse(alloc, 400, "Bad Request", "invalid json");
    const obj = switch (parsed.value) {
        .object => |o| o,
        else => return errorResponse(alloc, 400, "Bad Request", "expected object"),
    };

    const account_val = obj.get("account") orelse return errorResponse(alloc, 400, "Bad Request", "missing account");
    const password_val = obj.get("password") orelse return errorResponse(alloc, 400, "Bad Request", "missing password");

    const account = switch (account_val) {
        .string => |s| s,
        else => return errorResponse(alloc, 400, "Bad Request", "account must be string"),
    };
    const password = switch (password_val) {
        .string => |s| s,
        else => return errorResponse(alloc, 400, "Bad Request", "password must be string"),
    };

    // Null-terminate for C calls
    const account_z = try alloc.dupeZ(u8, account);
    const password_z = try alloc.dupeZ(u8, password);

    const level = cdb.http_authenticate_user(account_z.ptr, password_z.ptr);
    if (level < 0) {
        return .{ .status = 401, .status_text = "Unauthorized", .body = "{\"error\":\"invalid credentials\"}" };
    }
    if (level == 0) {
        return .{ .status = 403, .status_text = "Forbidden", .body = "{\"error\":\"account not authorized for API access\"}" };
    }

    if (jwt_secret.len == 0) {
        return errorResponse(alloc, 500, "Internal Server Error", "jwt secret not configured");
    }

    const token = try jwtCreate(alloc, account, @intCast(level));
    const exp: i64 = cdb.time(0) + token_lifetime_secs;

    var resp_obj = std.json.Value{ .object = std.json.ObjectMap.empty };
    try resp_obj.object.put(alloc, "token", .{ .string = token });
    try resp_obj.object.put(alloc, "account", .{ .string = account });
    try resp_obj.object.put(alloc, "admin_level", .{ .integer = level });
    try resp_obj.object.put(alloc, "expires_at", .{ .integer = exp });
    return jsonResponse(alloc, 200, resp_obj);
}

fn metaFlagArray(alloc: Allocator, comptime countFn: anytype, comptime nameFn: anytype) !std.json.Value {
    var arr = std.json.Value{ .array = std.json.Array.init(alloc) };
    const count = countFn();
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        const name_ptr = nameFn(i) orelse { i += 1; continue; };
        const name = std.mem.sliceTo(name_ptr, 0);
        var entry = std.json.Value{ .object = std.json.ObjectMap.empty };
        try entry.object.put(alloc, "bit", .{ .integer = @as(i64, i) });
        try entry.object.put(alloc, "name", .{ .string = name });
        try arr.array.append(entry);
    }
    return arr;
}

fn metaIdArray(alloc: Allocator, comptime countFn: anytype, comptime nameFn: anytype) !std.json.Value {
    var arr = std.json.Value{ .array = std.json.Array.init(alloc) };
    const count = countFn();
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        const name_ptr = nameFn(i) orelse { i += 1; continue; };
        const name = std.mem.sliceTo(name_ptr, 0);
        var entry = std.json.Value{ .object = std.json.ObjectMap.empty };
        try entry.object.put(alloc, "id", .{ .integer = @as(i64, i) });
        try entry.object.put(alloc, "name", .{ .string = name });
        try arr.array.append(entry);
    }
    return arr;
}

fn metaTrigArray(alloc: Allocator, comptime nameFn: anytype) !std.json.Value {
    var arr = std.json.Value{ .array = std.json.Array.init(alloc) };
    const count = cdb.http_meta_trig_type_count();
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        const name_ptr = nameFn(i) orelse { i += 1; continue; };
        const name = std.mem.sliceTo(name_ptr, 0);
        var entry = std.json.Value{ .object = std.json.ObjectMap.empty };
        try entry.object.put(alloc, "bit", .{ .integer = @as(i64, i) });
        try entry.object.put(alloc, "mask", .{ .integer = @as(i64, 1) << @as(u6, @intCast(i)) });
        try entry.object.put(alloc, "name", .{ .string = name });
        try arr.array.append(entry);
    }
    return arr;
}

fn handleMeta(alloc: Allocator, request: *const ParsedRequest, key: []const u8) !Response {
    _ = request;
    if (std.mem.eql(u8, key, "room-flags"))
        return jsonResponse(alloc, 200, try metaFlagArray(alloc, cdb.http_meta_room_flag_count, cdb.http_meta_room_flag_name));
    if (std.mem.eql(u8, key, "sector-types"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_sector_type_count, cdb.http_meta_sector_type_name));
    if (std.mem.eql(u8, key, "mob-flags"))
        return jsonResponse(alloc, 200, try metaFlagArray(alloc, cdb.http_meta_mob_flag_count, cdb.http_meta_mob_flag_name));
    if (std.mem.eql(u8, key, "mob-affect-flags"))
        return jsonResponse(alloc, 200, try metaFlagArray(alloc, cdb.http_meta_aff_flag_count, cdb.http_meta_aff_flag_name));
    if (std.mem.eql(u8, key, "object-types"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_object_type_count, cdb.http_meta_object_type_name));
    if (std.mem.eql(u8, key, "object-extra-flags"))
        return jsonResponse(alloc, 200, try metaFlagArray(alloc, cdb.http_meta_object_extra_flag_count, cdb.http_meta_object_extra_flag_name));
    if (std.mem.eql(u8, key, "object-wear-flags"))
        return jsonResponse(alloc, 200, try metaFlagArray(alloc, cdb.http_meta_object_wear_flag_count, cdb.http_meta_object_wear_flag_name));
    if (std.mem.eql(u8, key, "directions"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_direction_count, cdb.http_meta_direction_name));
    if (std.mem.eql(u8, key, "character-races"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_race_count, cdb.http_meta_race_name));
    if (std.mem.eql(u8, key, "character-senseis"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_sensei_count, cdb.http_meta_sensei_name));
    if (std.mem.eql(u8, key, "dgscript-attach-types"))
        return jsonResponse(alloc, 200, try metaIdArray(alloc, cdb.http_meta_dgscript_attach_type_count, cdb.http_meta_dgscript_attach_type_name));
    if (std.mem.eql(u8, key, "dgscript-mob-triggers"))
        return jsonResponse(alloc, 200, try metaTrigArray(alloc, cdb.http_meta_mob_trig_name));
    if (std.mem.eql(u8, key, "dgscript-obj-triggers"))
        return jsonResponse(alloc, 200, try metaTrigArray(alloc, cdb.http_meta_obj_trig_name));
    if (std.mem.eql(u8, key, "dgscript-room-triggers"))
        return jsonResponse(alloc, 200, try metaTrigArray(alloc, cdb.http_meta_room_trig_name));
    return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"unknown meta key\"}" };
}

fn handleStatus(alloc: Allocator) !Response {
    var obj = std.json.Value{ .object = std.json.ObjectMap.empty };
    try obj.object.put(alloc, "status", .{ .string = "running" });
    try obj.object.put(alloc, "players", .{ .integer = cdb.game_active_player_count() });
    return jsonResponse(alloc, 200, obj);
}

fn handleRoom(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.room_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const room = cdb.room_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"room not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try rooms_json.serializeRoom(alloc, room));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        rooms_json.deserializeRoom(room, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.room_zone_vnum_get(room);
        _ = cdb.olc_save_rooms(zvnum);
        return jsonResponse(alloc, 200, try rooms_json.serializeRoom(alloc, room));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleObject(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.obj_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const proto = cdb.obj_proto_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"object not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try objects_json.serializeObjectPrototype(alloc, proto));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        objects_json.deserializeObjectPrototype(proto, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.virtual_zone_by_thing(vnum);
        if (zvnum != cdb.NOTHING) _ = cdb.olc_save_objects(zvnum);
        return jsonResponse(alloc, 200, try objects_json.serializeObjectPrototype(alloc, proto));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleMob(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.mob_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const proto = cdb.mob_proto_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"mob not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try characters_json.serializeMobPrototype(alloc, proto));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        characters_json.deserializeMobPrototype(proto, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.virtual_zone_by_thing(vnum);
        if (zvnum != cdb.NOTHING) _ = cdb.olc_save_mobs(zvnum);
        return jsonResponse(alloc, 200, try characters_json.serializeMobPrototype(alloc, proto));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleShop(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.shop_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const shop = cdb.shop_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"shop not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try shops_json.serializeShop(alloc, shop));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        shops_json.deserializeShop(shop, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.virtual_zone_by_thing(vnum);
        if (zvnum != cdb.NOTHING) _ = cdb.olc_save_shops(zvnum);
        return jsonResponse(alloc, 200, try shops_json.serializeShop(alloc, shop));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleGuild(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.guild_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const guild = cdb.guild_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"guild not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try guilds_json.serializeGuild(alloc, guild));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        guilds_json.deserializeGuild(guild, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.virtual_zone_by_thing(vnum);
        if (zvnum != cdb.NOTHING) _ = cdb.olc_save_guilds(zvnum);
        return jsonResponse(alloc, 200, try guilds_json.serializeGuild(alloc, guild));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleTrigger(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    const vnum = std.fmt.parseInt(cdb.trig_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const trig = cdb.trig_proto_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"trigger not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try dgscripts_json.serializeTrigger(alloc, trig));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        dgscripts_json.deserializeTrigger(trig, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        const zvnum = cdb.virtual_zone_by_thing(vnum);
        if (zvnum != cdb.NOTHING) _ = cdb.olc_save_triggers(zvnum);
        return jsonResponse(alloc, 200, try dgscripts_json.serializeTrigger(alloc, trig));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn handleZone(alloc: Allocator, request: *const ParsedRequest, rest: []const u8) !Response {
    if (std.mem.endsWith(u8, rest, "/reset")) {
        const vnum_str = rest[0 .. rest.len - "/reset".len];
        const vnum = std.fmt.parseInt(cdb.zone_vnum, vnum_str, 10) catch
            return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
        if (!std.mem.eql(u8, request.method, "POST"))
            return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
        const zone = cdb.zone_by_id(vnum) orelse
            return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"zone not found\"}" };
        cdb.reset_zone(zone);
        return .{ .status = 200, .status_text = "OK", .body = "{\"status\":\"reset\"}" };
    }

    const vnum = std.fmt.parseInt(cdb.zone_vnum, rest, 10) catch
        return .{ .status = 400, .status_text = "Bad Request", .body = "{\"error\":\"invalid vnum\"}" };
    const zone = cdb.zone_by_id(vnum) orelse
        return .{ .status = 404, .status_text = "Not Found", .body = "{\"error\":\"zone not found\"}" };

    if (std.mem.eql(u8, request.method, "GET")) {
        return jsonResponse(alloc, 200, try zones_json.serializeZone(alloc, zone));
    }
    if (std.mem.eql(u8, request.method, "PUT")) {
        const parsed = std.json.parseFromSlice(std.json.Value, alloc, request.body, .{}) catch
            return errorResponse(alloc, 400, "Bad Request", "invalid json");
        zones_json.deserializeZone(zone, .{}, parsed.value) catch |err|
            return errorResponse(alloc, 422, "Unprocessable Entity", @errorName(err));
        _ = cdb.olc_save_zone(vnum);
        return jsonResponse(alloc, 200, try zones_json.serializeZone(alloc, zone));
    }
    return .{ .status = 405, .status_text = "Method Not Allowed", .body = "{\"error\":\"method not allowed\"}" };
}

fn jsonResponse(alloc: Allocator, status: u16, value: std.json.Value) !Response {
    var out: std.Io.Writer.Allocating = .init(alloc);
    try std.json.Stringify.value(value, .{}, &out.writer);
    const body = out.written();
    const status_text: []const u8 = switch (status) {
        200 => "OK",
        201 => "Created",
        else => "OK",
    };
    return .{ .status = status, .status_text = status_text, .body = body };
}

fn errorResponse(alloc: Allocator, status: u16, status_text: []const u8, message: []const u8) !Response {
    const body = try std.fmt.allocPrint(alloc, "{{\"error\":\"{s}\"}}", .{message});
    return .{ .status = status, .status_text = status_text, .body = body };
}
