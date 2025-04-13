const std = @import("std");

const rl = @import("raylib");

const App = @import("App.zig");
const AssetDirectory = @import("AssetDirectory.zig");
const draw_utils = @import("utils/draw_utils.zig");

const Self = @This();

const base_resolution = rl.Vector2{
    .x = 544.0,
    .y = 306.0,
};
const scale_factor = 2.0;

app: *App,
assets: AssetDirectory,
camera: rl.Camera2D,
background_texture: ?rl.Texture = null,
sun_texture: ?rl.Texture = null,
sunflower_idle_texture: ?rl.Texture = null,
peashooter_idle_texture: ?rl.Texture = null,
sun_rotation: f32 = 69.0,

pub fn init(app: *App) !Self {
    const allocator = std.heap.page_allocator;

    // Scales the application window size by the scale factor
    app.screen_width *= scale_factor;
    app.screen_height *= scale_factor;

    // Initialize and return the game instance
    return Self{
        .app = app,
        .assets = AssetDirectory.init(allocator, "resources.rres"),
        .camera = rl.Camera2D{
            .offset = .zero(),
            .target = .zero(),
            .rotation = 0.0,
            .zoom = scale_factor,
        },
    };
}

pub fn loadContent(self: *Self) !void {
    // Load textures
    self.background_texture = try self.assets.request(rl.Texture, "images\\background_1.png");
    self.sun_texture = try self.assets.request(rl.Texture, "images\\sun.png");
    self.sunflower_idle_texture = try self.assets.request(rl.Texture, "images\\sunflower_idle.png");
    self.peashooter_idle_texture = try self.assets.request(rl.Texture, "images\\peashooter_idle.png");
}

pub fn update(self: *Self, delta_time: f32) void {
    const sun_rotation_speed: f32 = 0.60; // Radians per second
    self.sun_rotation += sun_rotation_speed * delta_time;
}

pub fn draw(self: *Self) void {
    rl.beginMode2D(self.camera);
    defer rl.endMode2D();

    // Draw the background texture
    rl.drawTexture(
        self.background_texture.?,
        -93,
        0,
        .white,
    );

    // Draw the sun texture with rotation
    const sun_texture = self.sun_texture.?;
    draw_utils.drawTexturePro(
        sun_texture,
        .{
            .x = 16 + @as(f32, @floatFromInt(sun_texture.width)) / 2.0,
            .y = 16 + @as(f32, @floatFromInt(sun_texture.height)) / 2.0,
        },
        .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(sun_texture.width),
            .height = @floatFromInt(sun_texture.height),
        },
        .white,
        self.sun_rotation,
        .{
            .x = 0.5,
            .y = 0.5,
        },
        1.0,
    );

    // Draw the sunflower texture with animation
    draw_utils.drawAnimatedSprite(
        self.sunflower_idle_texture.?,
        .{ .x = 48, .y = 48 },
        7,
        1,
        6.0,
    );

    // Draw the peashooter texture with animation
    draw_utils.drawAnimatedSprite(
        self.peashooter_idle_texture.?,
        .{ .x = 80, .y = 80 },
        7,
        1,
        6.0,
    );

    rl.drawText("Congrats! You created your first window!", 190, 200, 20, .black);
}

pub fn deinit(self: *Self) void {
    self.assets.deinit();
}
