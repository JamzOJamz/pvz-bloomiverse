const assert = @import("std").debug.assert;

const rl = @import("raylib");

const game = @import("game.zig");

const Self = @This();

/// The amount of sun that is given to the player when a sun is clicked.
pub const value = 25;

/// The minimum lifetime of a sun in ticks.
const lifetime_min = 720;

/// The maximum lifetime of a sun in ticks.
const lifetime_max = 900;

pub const Source = enum {
    sky,
    plant,
};

source: Source,
position: rl.Vector2,
velocity: rl.Vector2,
last_position: rl.Vector2,
frame_counter: i32 = 0,
time_left: i32,
ai: f32 = 0.0,
ai_fn: ?*const fn (*Self) void,

pub fn init(
    source: Source,
    position: rl.Vector2,
    velocity: rl.Vector2,
    update_fn: ?*const fn (*Self) void,
) Self {
    assert(lifetime_min <= lifetime_max);
    return Self{
        .source = source,
        .position = position,
        .velocity = velocity,
        .last_position = position,
        .time_left = game.rng().intRangeAtMost(i32, lifetime_min, lifetime_max),
        .ai_fn = update_fn,
    };
}
