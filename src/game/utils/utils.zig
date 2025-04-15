//! Provides general purpose utility functions to be used throughout the game.

const rl = @import("raylib");

/// Returns the current mouse position relative to the window adjusted by the given scale factor.
/// The scale factor is useful for converting the mouse position from screen coordinates to world coordinates.
pub fn getMousePosition(scale_factor: f32) rl.Vector2 {
    return rl.Vector2.divide(rl.getMousePosition(), rl.Vector2{ .x = scale_factor, .y = scale_factor });
}
