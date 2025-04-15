const assert = @import("std").debug.assert;
const std = @import("std");

const rl = @import("raylib");

const Self = @This();

sounds: std.ArrayList(rl.Sound),
cur_sound: u32 = 0,

pub fn create(ally: std.mem.Allocator, sound: rl.Sound, count: u32) !Self {
    assert(count > 0);
    var sounds = try std.ArrayList(rl.Sound).initCapacity(ally, count);
    for (0..count) |i| {
        if (i == 0) {
            try sounds.append(sound);
            continue;
        }

        const alias = rl.loadSoundAlias(sound);
        try sounds.append(alias);
    }
    return .{ .sounds = sounds };
}

/// Plays the next sound in the pool.
pub fn play(self: *Self) void {
    rl.playSound(self.sounds.items[self.cur_sound]);
    self.cur_sound = (self.cur_sound + 1) % @as(u32, @intCast(self.sounds.items.len));
}

/// Plays a sound at the specified index in the pool.
pub fn playIndex(self: *Self, index: u32) void {
    assert(index < @as(u32, @intCast(self.sounds.items.len)));
    rl.playSound(self.sounds.items[index]);
}

pub fn deinit(self: *Self) void {
    for (0..self.sounds.items.len) |i| {
        if (i == 0) {
            rl.unloadSound(self.sounds.items[i]);
            continue;
        }

        rl.unloadSoundAlias(self.sounds.items[i]);
    }

    self.sounds.deinit();
}
