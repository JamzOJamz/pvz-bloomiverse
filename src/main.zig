const rl = @import("raylib");

const draw_utils = @import("utils/draw_utils.zig");

const c = @cImport({
    @cInclude("rres.h");
    @cInclude("raylib.h");
    @cInclude("rres-raylib.h");
});

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const scale_factor = 4.0;
    const base_width = 480;
    const base_height = 270;
    const screen_width = base_width * scale_factor;
    const screen_height = base_height * scale_factor;
    const square_size: f32 = 32.0;
    const scroll_speed: f32 = 10.0; // Adjust to change scrolling speed

    rl.initWindow(screen_width, screen_height, "Plants vs. Zombies: Multiverse");
    defer rl.closeWindow(); // Close window and OpenGL context

    const asset_dir = c.rresLoadCentralDirectory("resources.rres");
    defer c.rresUnloadCentralDirectory(asset_dir);

    const background_front_yard_id = c.rresGetResourceId(asset_dir, "Background_FrontYard.png");
    const background_front_yard = c.rresLoadResourceChunk("resources.rres", background_front_yard_id);
    defer c.rresUnloadResourceChunk(background_front_yard);
    //const success = c.UnpackResourceChunk(&background_front_yard);
    //_ = success; // autofix

    const image = @as(*rl.Image, @ptrFromInt(@intFromPtr(&c.LoadImageFromResource(background_front_yard)))).*;
    const texture = try rl.loadTextureFromImage(image);
    defer rl.unloadTexture(texture);
    rl.unloadImage(image);

    rl.setTargetFPS(144); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Create a camera to simulate a 2D game
    const camera = rl.Camera2D{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0.0,
        .zoom = scale_factor,
    };

    const sun_texture = try rl.loadTexture("Sun.png");
    defer rl.unloadTexture(sun_texture);

    const sunflower_idle_texture = try rl.loadTexture("Sunflower_Idle.png");
    defer rl.unloadTexture(sunflower_idle_texture);

    const peashooter_idle_texture = try rl.loadTexture("Peashooter_Idle.png");
    defer rl.unloadTexture(peashooter_idle_texture);

    // Debug variables for the sun rotation
    var debug_rotation: f32 = 0.0;
    const rotation_speed: f32 = 0.60; // Degrees per frame

    // Variable to control diagonal scrolling of the checkered grid
    var checkered_offset: f32 = 0.0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        const delta_time = rl.getFrameTime();

        // Rotate the sun
        debug_rotation += rotation_speed * delta_time;

        // Update the scrolling offset; once it reaches the square size, loop it.
        checkered_offset += scroll_speed * delta_time;
        if (checkered_offset >= square_size) {
            checkered_offset -= square_size;
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.init(201, 160, 147, 255));

        rl.beginMode2D(camera);

        // Draw the background texture
        rl.drawTexture(
            texture,
            0,
            0,
            .white,
        );

        // Draw the checkered pattern.
        // Determine how many columns and rows we need (add extra to cover scrolling)
        const num_cols = @as(u32, @intFromFloat((base_width / square_size) + 2));
        const num_rows = @as(u32, @intFromFloat((base_height / square_size) + 2));
        for (0..num_rows) |j| {
            for (0..num_cols) |i| {
                // Alternate squares: only draw a square if (i+j) is even.
                if ((i + j) % 2 == 0) {
                    const x: f32 = @as(f32, @floatFromInt(i)) * square_size - checkered_offset;
                    const y: f32 = @as(f32, @floatFromInt(j)) * square_size - checkered_offset;
                    rl.drawRectangleRec(
                        .{ .x = x, .y = y, .width = square_size, .height = square_size },
                        .init(188, 153, 147, 255),
                    );
                }
            }
        }

        // Draw the sun texture with rotation
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
            debug_rotation,
            .{
                .x = 0.5,
                .y = 0.5,
            },
            1.0,
        );

        // Draw the sunflower texture with animation
        draw_utils.drawAnimatedSprite(
            sunflower_idle_texture,
            .{ .x = 48, .y = 48 },
            7,
            1,
            6.0,
        );

        // Draw the peashooter texture with animation
        draw_utils.drawAnimatedSprite(
            peashooter_idle_texture,
            .{ .x = 80, .y = 80 },
            7,
            1,
            6.0,
        );

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .black);

        rl.endMode2D();
        //----------------------------------------------------------------------------------
    }
}
