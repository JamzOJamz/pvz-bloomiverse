const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zrres_raylib = b.addModule("root", .{
        .root_source_file = b.path("src/zrres-raylib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zrres = b.dependency("zrres", .{
        .target = target,
        .optimize = optimize,
    });
    zrres_raylib.addImport("zrres", zrres.module("root"));

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    zrres_raylib.linkLibrary(raylib_artifact);
    zrres_raylib.addImport("raylib", raylib);

    zrres_raylib.addIncludePath(b.path("libs/rres"));
    zrres_raylib.addIncludePath(zrres.path("libs/rres"));
    zrres_raylib.addCSourceFile(.{
        .file = b.path("src/zrres-raylib.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });
}
