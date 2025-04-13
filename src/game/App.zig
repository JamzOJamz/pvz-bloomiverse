const rl = @import("raylib");

const Game = @import("Game.zig");

const Self = @This();

screen_width: i32,
screen_height: i32,
target_fps: i32,
window_title: [:0]const u8,
clear_color: rl.Color,
game: Game,

pub fn init(width: i32, height: i32, fps: i32, title: [:0]const u8, clear: rl.Color) Self {
    return Self{
        .screen_width = width,
        .screen_height = height,
        .target_fps = fps,
        .window_title = title,
        .clear_color = clear,
        .game = undefined,
    };
}

pub fn run(self: *Self) !void {
    try self.setup();
    self.gameLoop();
}

fn setup(self: *Self) !void {
    // Initialize the game before the window is created
    self.game = try Game.init(self);

    // Initialize Raylib
    rl.initWindow(self.screen_width, self.screen_height, self.window_title);
    rl.setTargetFPS(self.target_fps);

    // Load the game content
    try self.game.loadContent();
}

fn update(self: *Self, delta_time: f32) void {
    self.game.update(delta_time);
}

fn draw(self: *Self) void {
    rl.clearBackground(self.clear_color);
    self.game.draw();
}

fn gameLoop(self: *Self) void {
    while (!rl.windowShouldClose()) {
        const delta_time = rl.getFrameTime();

        self.update(delta_time);

        rl.beginDrawing();
        defer rl.endDrawing();

        self.draw();
    }
}

pub fn deinit(self: *Self) void {
    self.game.deinit();

    rl.closeWindow();
}
