const game = @import("game.zig");

pub fn main() !void {
    try game.init();
    defer game.deinit();

    try game.run();
}
