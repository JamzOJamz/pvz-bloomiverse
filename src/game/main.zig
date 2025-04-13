const rl = @import("raylib");

const App = @import("App.zig");

const initial_screen_width = 544;
const initial_screen_height = 306;
const target_fps = 144;
const window_title = "Plants vs. Zombies: Multiverse";
const clear_color = rl.Color.init(201, 160, 147, 255);

pub fn main() !void {
    var app = App.init(
        initial_screen_width,
        initial_screen_height,
        target_fps,
        window_title,
        clear_color,
    );
    defer app.deinit();

    try app.run();
}
