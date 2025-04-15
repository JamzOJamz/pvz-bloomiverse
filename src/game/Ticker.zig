const rl = @import("raylib");

const Self = @This();

fixed_dt: f64 = 1.0 / 60.0,
current_time: f64,
accumulator: f64 = 0,
//per_second_accumulator: f64 = 0,
fixed_update_fn: *const fn () anyerror!void,
render_update_fn: *const fn (f32) void,
draw_fn: *const fn (f32) void,

pub fn step(self: *Self) !void {
    const new_time = rl.getTime();
    const frame_time = new_time - self.current_time;
    //self.per_second_accumulator += frame_time;
    self.current_time = new_time;

    self.accumulator += frame_time;

    while (self.accumulator >= self.fixed_dt) {
        try self.fixed_update_fn();
        self.accumulator -= self.fixed_dt;
    }

    const alpha: f32 = @floatCast(self.accumulator / self.fixed_dt);

    self.render_update_fn(alpha);
    self.draw_fn(alpha);
}
