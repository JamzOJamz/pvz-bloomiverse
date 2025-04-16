const assert = @import("std").debug.assert;

const rl = @import("raylib");

const game = @import("game.zig");

const Self = @This();

/// The amount of sun that is given to the player when a sun is clicked.
pub const value = 25;

/// The starting alpha (transparency) value of the sun.
pub const starting_alpha = 205;

/// The number of ticks before the sun starts to fade out, at which point it is no longer collectable.
pub const fade_out_ticks = 6;

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
last_position: ?rl.Vector2,
frame_counter: i32 = 0,
time_left: i32,
alpha: u8 = starting_alpha,
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
        .time_left = game.rng().intRangeAtMost(i32, lifetime_min, lifetime_max) + fade_out_ticks,
        .ai_fn = update_fn,
    };
}

pub fn isCollectable(self: *const Self) bool {
    return self.time_left > fade_out_ticks;
}

pub fn getDrawPosition(self: *const Self, alpha: f32) ?rl.Vector2 {
    if (self.last_position) |last_position| {
        return last_position.lerp(self.position, alpha);
    } else {
        return null;
    }
}
