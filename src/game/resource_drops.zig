const std = @import("std");
const assert = std.debug.assert;

const rl = @import("raylib");

const game = @import("game.zig");
const Sun = @import("Sun.zig");

/// The minimum possible interval between natural sun spawns in ticks.
const sun_spawn_interval_min = 300;

/// The maximum possible interval between natural sun spawns in ticks.
const sun_spawn_interval_max = 480;

/// The minimum X position for natural sun spawns.
const sun_spawn_x_min = 140;

/// The maximum X position for natural sun spawns.
const sun_spawn_x_max = 380;

/// The minimum Y position for natural sun spawns to fall to.
const sun_end_y_min = 154;

/// The maximum Y position for natural sun spawns to fall to.
const sun_end_y_max = 242;

var sun_spawn_timer: i32 = 0;
var next_sun_spawn: i32 = 0;

pub fn tick() !void {
    const rand = game.rng();

    if (next_sun_spawn == 0) {
        assert(sun_spawn_interval_min <= sun_spawn_interval_max);
        next_sun_spawn = rand.intRangeAtMost(i32, sun_spawn_interval_min, sun_spawn_interval_max);
        std.debug.print("Next sun spawn in {} ticks\n", .{next_sun_spawn});
    }

    sun_spawn_timer += 1;

    if (sun_spawn_timer >= next_sun_spawn) {
        sun_spawn_timer = 0;
        next_sun_spawn = 0;
        assert(sun_spawn_x_min <= sun_spawn_x_max);
        const spawn_position = rl.Vector2{
            .x = @floatFromInt(rand.intRangeAtMost(i32, sun_spawn_x_min, sun_spawn_x_max)),
            .y = 55.0,
        };
        const initial_velocity = rl.Vector2{
            .x = 0.0,
            .y = 19.4 / 60.0,
        };
        try game.newSun(.init(.sky, spawn_position, initial_velocity, ai_natural_sun));
    }
}

fn ai_natural_sun(instance: *Sun) void {
    // Calculates a random final Y position for the sun to fall to
    if (instance.ai == 0.0) {
        assert(sun_end_y_min <= sun_end_y_max);
        instance.ai = @floatFromInt(game.rng().intRangeAtMost(i32, sun_end_y_min, sun_end_y_max));
    }

    // Stop the sun at the final Y position
    if (instance.position.y >= instance.ai) {
        instance.velocity.y = 0.0;
        instance.position.y = instance.ai;
    }
}
