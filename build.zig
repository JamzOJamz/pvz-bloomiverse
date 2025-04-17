const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_bin = b.option(bool, "no-bin", "") orelse false;

    // This is a dependency that is shared between the game and the asset packer tool.
    const zrres = b.dependency("zrres", .{
        .target = target,
        .optimize = optimize,
    });

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/game/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This creates another `std.Build.Step.Compile`, but this one builds an executable
    // rather than a static library.
    const exe = b.addExecutable(.{
        .name = "multiverse",
        .root_module = exe_mod,
    });

    // Hide the console window on Windows in release builds.
    if (optimize != .Debug) {
        exe.subsystem = .Windows;
    }

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    exe.root_module.addImport("zrres", zrres.module("root"));

    const zrres_rl = b.dependency("zrres_rl", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zrres_rl", zrres_rl.module("root"));

    var run_cmd: *std.Build.Step.Run = undefined;
    if (no_bin) {
        b.getInstallStep().dependOn(&exe.step);
    } else {
        b.installArtifact(exe);

        run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const pack_assets_mod = b.createModule(.{
        .root_source_file = b.path("src/pack/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const pack_assets = b.addExecutable(.{
        .name = "pack_assets",
        .root_module = pack_assets_mod,
    });
    pack_assets.root_module.addImport("zrres", zrres.module("root"));

    if (no_bin) {
        b.getInstallStep().dependOn(&pack_assets.step);
    } else {
        b.installArtifact(pack_assets);

        const pack_assets_run_cmd = b.addRunArtifact(pack_assets);

        const pack_step = b.step("pack-assets", "Pack assets to .rres file");
        pack_step.dependOn(&pack_assets_run_cmd.step);

        // Ensure that assets are packed before the game is run.
        std.fs.cwd().access("resources.rres", .{}) catch {
            b.getInstallStep().dependOn(&pack_assets_run_cmd.step);
        };
    }
}
