const rl = @import("raylib");

pub var lmb = false;
pub var lmb_release = false;

pub fn readInputs() void {
    // Read mouse inputs
    lmb = rl.isMouseButtonDown(.left);
    lmb_release = rl.isMouseButtonReleased(.left);
}
