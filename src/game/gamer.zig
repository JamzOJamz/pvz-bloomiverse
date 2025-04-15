const std = @import("std");
const assert = std.debug.assert;

const rl = @import("raylib");

const AssetDirectory = @import("AssetDirectory.zig");
const Grid = @import("Grid.zig");
const input = @import("input.zig");
const resource_drops = @import("resource_drops.zig");
const resources = @import("resources.zig");
const SoundPool = @import("SoundPool.zig");
const Sun = @import("Sun.zig");
const Ticker = @import("Ticker.zig");
const draw_utils = @import("utils/draw_utils.zig");
const utils = @import("utils/utils.zig");

const target_fps = 300;
const window_title = "Plants vs. Zombies: Multiverse";
const clear_color = rl.Color.init(201, 160, 147, 255);
const base_resolution = rl.Vector2{ .x = 544.0, .y = 306.0 };
const scale_factor = 3;
const screen_width = @as(i32, @intFromFloat(base_resolution.x)) * scale_factor;
const screen_height = @as(i32, @intFromFloat(base_resolution.y)) * scale_factor;
const background_offset_left = rl.Vector2{ .x = -93.0, .y = 0.0 };
const front_yard_grid = Grid{
    .size = .{ .x = 9.0, .y = 5.0 },
    .spacing = .{ .x = 34.0, .y = 43.0 },
    .start = .{ .x = 137.0, .y = 76.0 },
};
var allocator: std.mem.Allocator = undefined;
var asset_dir: AssetDirectory = undefined;
var camera: rl.Camera2D = undefined;
var prng: std.Random.DefaultPrng = undefined;
var rand: std.Random = undefined;
var sun: std.ArrayList(Sun) = undefined;
var background_texture: rl.Texture = undefined;
var sun_texture: rl.Texture = undefined;
var sunflower_idle_texture: rl.Texture = undefined;
var peashooter_idle_texture: rl.Texture = undefined;
var screen_blend_shader: rl.Shader = undefined;
var points_sound: SoundPool = undefined;

pub fn init() !void {
    allocator = std.heap.page_allocator;

    asset_dir = AssetDirectory.init(allocator, "resources.rres");

    camera = rl.Camera2D{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0.0,
        .zoom = scale_factor,
    };

    prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();

    sun = try std.ArrayList(Sun).initCapacity(allocator, 10);
}

pub fn run() !void {
    // Initialize Raylib
    rl.initWindow(screen_width, screen_height, window_title);
    defer rl.closeWindow();
    rl.setTargetFPS(target_fps);
    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    // Load the game content
    try loadContent();

    // Create the ticker to handle the game loop
    var ticker = Ticker{
        .current_time = rl.getTime(),
        .fixed_update_fn = fixedUpdate,
        .render_update_fn = renderUpdate,
        .draw_fn = draw,
    };

    // Start the game loop
    while (!rl.windowShouldClose()) try ticker.step();
}

pub fn loadContent() !void {
    // Load textures
    background_texture = try asset_dir.request(rl.Texture, "images\\background_1.png");
    sun_texture = try asset_dir.request(rl.Texture, "images\\sun.png");
    sunflower_idle_texture = try asset_dir.request(rl.Texture, "images\\sunflower_idle.png");
    peashooter_idle_texture = try asset_dir.request(rl.Texture, "images\\peashooter_idle.png");

    // Load shaders
    screen_blend_shader = try asset_dir.request(rl.Shader, "shaders\\screen_blend.fs");

    // Load sounds
    points_sound = try SoundPool.create(allocator, try asset_dir.request(rl.Sound, "sounds\\points.wav"), 4);
}

pub fn fixedUpdate() !void {
    // Update all suns in the game
    var i = sun.items.len;
    while (i > 0) {
        i -= 1;
        const s = &sun.items[i];

        // Despawn suns that have been on the screen for too long
        s.time_left -= 1;
        if (s.time_left <= 0) {
            _ = sun.orderedRemove(i);
            continue;
        }

        // Update the sun's position
        s.last_position = s.position;

        // Update the sun's position based on its velocity
        s.position = s.position.add(s.velocity);

        // Increment the frame counter
        s.frame_counter += 1;

        // Call the AI function if it exists
        if (s.ai_fn) |ai_fn| {
            ai_fn(s);
        }
    }

    // Handle natural sun spawning
    try resource_drops.tick();
}

pub fn renderUpdate(alpha: f32) void {
    input.readInputs();
    handleSunCollection(alpha);
}

fn handleSunCollection(alpha: f32) void {
    if (!input.lmb_release) return;
    const mouse_pos = utils.getMousePosition(scale_factor);
    const sun_texture_half_size = @as(f32, @floatFromInt(sun_texture.height)) / 2;
    var i = sun.items.len;
    while (i > 0) {
        i -= 1;
        const s = &sun.items[i];

        const interpolated_position = s.last_position.lerp(s.position, alpha);
        if (rl.checkCollisionPointCircle(
            mouse_pos,
            interpolated_position.addValue(sun_texture_half_size),
            sun_texture_half_size + 2.0, // Makes the hitbox slightly larger
        )) {
            input.lmb_release = false; // Consumes the click for this frame
            std.debug.print("Clicked sun: {}\n", .{s});
            resources.addSun(Sun.value);
            points_sound.play();
            _ = sun.orderedRemove(i);
            break;
        }
    }
}

pub fn draw(alpha: f32) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(clear_color);

    // Enter 2D mode for drawing the game view using the camera
    rl.beginMode2D(camera);
    defer rl.endMode2D();

    // Draw the background texture
    rl.drawTexture(
        background_texture,
        background_offset_left.x,
        background_offset_left.y,
        .white,
    );

    // Draw the grids bounding box as a red rectangle
    const grid_bounding_box = front_yard_grid.getBoundingBox();
    _ = grid_bounding_box; // autofix
    //rl.drawRectangleRec(
    //    grid_bounding_box,
    //    rl.Color{ .r = 255, .g = 0, .b = 0, .a = 255 },
    //);

    // Draw grid with some plants
    for (0..front_yard_grid.size.x) |i| {
        for (0..front_yard_grid.size.y) |j| {
            const x = front_yard_grid.start.x + @as(f32, @floatFromInt(i)) * front_yard_grid.spacing.x;
            const y = front_yard_grid.start.y + @as(f32, @floatFromInt(j)) * front_yard_grid.spacing.y;
            const plant_texture = if ((i + j) % 2 == 0) sunflower_idle_texture else peashooter_idle_texture;
            draw_utils.drawAnimatedSprite(
                plant_texture,
                .{ .x = x, .y = y },
                7,
                1,
                6.0,
                .white,
                .{ .x = 0.5, .y = 0.5 },
            );
        }
    }

    // If the mouse is inside the grid bounding box, debug print the nearest grid cell
    //const mouse_pos = utils.getMousePosition(scale_factor);
    //if (rl.checkCollisionPointRec(mouse_pos, grid_bounding_box)) {
    //    const nearest_cell = front_yard_grid.getNearestCell(mouse_pos);
    //    std.debug.print("Nearest cell: ({}, {})\n", .{ nearest_cell.x, nearest_cell.y });
    //}

    {
        // Set the shader mode for screen blending
        rl.beginShaderMode(screen_blend_shader);
        defer rl.endShaderMode();

        // Draw all active suns in the game
        for (sun.items) |s| {
            // Get interpolated position for smooth movement
            const interpolated_position = s.last_position.lerp(s.position, alpha);

            // Draw the sun texture
            draw_utils.drawAnimatedSprite(
                sun_texture,
                interpolated_position,
                4,
                1,
                9.0,
                .init(255, 255, 255, 205),
                .zero(),
            );
        }
    }

    //rl.drawText("Congrats! You created your first window!", 190, 200, 20, .black);
}

pub fn deinit() void {
    points_sound.deinit();
    sun.deinit();
    asset_dir.deinit();
}

/// Spawns a sun into the game world.
pub fn newSun(instance: Sun) !void {
    try sun.append(instance);
    std.debug.print("Spawned sun: {}\n", .{instance});
}

pub fn rng() std.Random {
    // Assert that the PRNG is initialized
    assert(!std.mem.allEqual(u64, &prng.s, 0));

    return rand;
}
