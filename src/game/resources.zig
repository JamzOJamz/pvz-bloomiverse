/// The maximum amount of sun that can be stored.
const max_sun = 9990;

/// The amount of sun in reserve.
var sun: i32 = 50;

pub fn getSun() i32 {
    return sun;
}

pub fn addSun(amount: i32) void {
    sun += amount;
    if (sun > max_sun) {
        sun = max_sun;
    }
}
