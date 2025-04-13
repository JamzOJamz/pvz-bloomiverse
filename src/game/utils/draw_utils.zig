const std = @import("std");

const rl = @import("raylib");

pub fn drawTexturePro(
    texture: rl.Texture2D,
    position: rl.Vector2,
    source: rl.Rectangle,
    tint: rl.Color,
    rotation: f32,
    origin: rl.Vector2,
    scale: f32,
) void {
    const scaled_width = @as(f32, @floatFromInt(texture.width)) * scale;
    const scaled_height = @as(f32, @floatFromInt(texture.height)) * scale;
    rl.drawTexturePro(
        texture,
        source,
        .{
            .x = position.x,
            .y = position.y,
            .width = scaled_width,
            .height = scaled_height,
        },
        .{
            .x = origin.x * scaled_width,
            .y = origin.y * scaled_height,
        },
        rotation * std.math.deg_per_rad,
        tint,
    );
}

pub fn drawAnimatedSprite(
    texture: rl.Texture2D,
    position: rl.Vector2,
    frame_count: usize,
    frame_padding: usize,
    animation_speed: f32,
) void {
    // Compute frame size
    const frame_width = @divFloor(@as(usize, @intCast(texture.width)) - (frame_count - 1) * frame_padding, frame_count);
    const frame_height = texture.height;

    // Compute current animation frame based on time
    const current_time = rl.getTime();
    const frame_index = @mod(@as(usize, @intFromFloat(current_time * animation_speed)), frame_count);

    // Compute source rectangle
    const src_rect = rl.Rectangle{
        .x = @as(f32, @floatFromInt(frame_index * (frame_width + frame_padding))),
        .y = 0.0,
        .width = @floatFromInt(frame_width),
        .height = @floatFromInt(frame_height),
    };

    // Compute destination rectangle (draw at actual size)
    const dst_rect = rl.Rectangle{
        .x = position.x,
        .y = position.y,
        .width = @floatFromInt(frame_width),
        .height = @floatFromInt(frame_height),
    };

    // Draw the animated sprite
    rl.drawTexturePro(texture, src_rect, dst_rect, .{ .x = 0, .y = 0 }, 0.0, .white);
}
