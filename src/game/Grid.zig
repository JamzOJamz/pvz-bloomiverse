const rl = @import("raylib");

const Self = @This();

size: rl.Vector2,
spacing: rl.Vector2,
start: rl.Vector2,

pub fn getBoundingBox(self: *const Self) rl.Rectangle {
    return .{
        .x = self.start.x - self.spacing.x / 2,
        .y = self.start.y - self.spacing.y / 2,
        .width = self.size.x * self.spacing.x,
        .height = self.size.y * self.spacing.y,
    };
}

pub fn getNearestCell(self: *const Self, pos: rl.Vector2) rl.Vector2 {
    const offset = pos.subtract(self.start);
    const cell = offset.divide(self.spacing);
    return .{ .x = @round(cell.x), .y = @round(cell.y) };
}
