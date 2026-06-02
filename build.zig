const std = @import("std");
const zcc = @import("compile_commands");

fn getSourceFiles(b: *std.Build, base_path: []const u8, ext: []const u8) []const []const u8 {
    const allocator = b.allocator;
    const io = b.graph.io;
    const empty: []const []const u8 = &[_][]const u8{};

    var dir = b.build_root.handle.openDir(io, base_path, .{ .iterate = true }) catch return empty;
    defer dir.close(io);

    var walker = dir.walk(allocator) catch {
        return empty;
    };
    defer walker.deinit();

    var capacity: usize = 16;
    var files = allocator.alloc([]const u8, capacity) catch return empty;
    var count: usize = 0;

    while (true) {
        const next_opt = walker.next(io) catch continue;
        if (next_opt) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ext)) {
                if (count >= capacity) {
                    capacity *= 2;
                    files = allocator.realloc(files, capacity) catch return empty;
                }
                // Prepend base_path to get full relative path
                files[count] = std.fmt.allocPrint(allocator, "{s}/{s}", .{ base_path, entry.path }) catch return empty;
                count += 1;
            }
        } else {
            break;
        }
    }

    return files[0..count];
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var targets: std.ArrayList(*std.Build.Step.Compile) = .empty;

    const zlua = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
        .lang = .lua55,
    });

    const zlua_module = zlua.module("zlua");

    const translate_dbat = b.addTranslateC(.{
        .root_source_file = b.path("src/zig_api.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_dbat.addIncludePath(b.path("include"));
    translate_dbat.addIncludePath(b.path("src"));

    const mod_cdb = translate_dbat.createModule();

    // Native DBAT library: Zig API/runtime plus legacy C++ host code.
    const mod_dbat = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "cdb", .module = mod_cdb },
            .{ .name = "zlua", .module = zlua_module },
        },
    });

    mod_dbat.addIncludePath(b.path("include"));
    mod_dbat.addIncludePath(b.path("src"));
    const dbat_files = getSourceFiles(b, "src", ".cpp");
    mod_dbat.addCSourceFiles(.{ .files = dbat_files, .flags = &[_][]const u8{ "-std=gnu++23", "-w", "-g", "-DPATH_MAX=4096" } });

    const mod_dbat_zig = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{
            .{ .name = "cdb", .module = mod_cdb },
            .{ .name = "zlua", .module = zlua_module },
        },
    });
    mod_dbat_zig.addIncludePath(b.path("include"));
    mod_dbat_zig.addIncludePath(b.path("src"));

    const dbat = b.addLibrary(.{
        .name = "dbat",
        .linkage = .static,
        .root_module = mod_dbat,
    });

    // Executable - Zig entrypoint with legacy C++ runner.
    const circle_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
        .root_source_file = b.path("apps/server/src/main.zig"),
        .imports = &.{
            .{ .name = "db", .module = mod_dbat_zig },
            .{ .name = "zlua", .module = zlua_module },
        },
    });
    circle_mod.addIncludePath(b.path("include"));
    circle_mod.addIncludePath(b.path("src"));
    circle_mod.addCSourceFiles(.{ .files = &[_][]const u8{"apps/server/src/run.cpp"}, .flags = &[_][]const u8{ "-std=gnu++23", "-w", "-g", "-DPATH_MAX=4096" } });
    circle_mod.linkLibrary(dbat);

    const exe = b.addExecutable(.{
        .name = "dbat",
        .root_module = circle_mod,
    });

    targets.append(b.allocator, exe) catch @panic("OOM");

    b.installArtifact(dbat);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    _ = zcc.createStep(b, "cdb", targets.toOwnedSlice(b.allocator) catch @panic("OOM"));

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
