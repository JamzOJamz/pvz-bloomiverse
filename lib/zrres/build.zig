const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zrres = b.addModule("root", .{
        .root_source_file = b.path("src/zrres.zig"),
        .target = target,
        .optimize = optimize,
    });

    zrres.addIncludePath(b.path("libs/rres"));
    zrres.addCSourceFile(.{
        .file = b.path("src/zrres.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });

    zrres.link_libc = true;
}
