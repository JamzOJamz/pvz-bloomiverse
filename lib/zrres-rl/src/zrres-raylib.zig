const rl = @import("raylib");
const rres = @import("zrres");

extern fn LoadDataFromResource(chunk: rres.ResourceChunk, size: *c_uint) [*c]u8;
pub const loadDataFromResource = LoadDataFromResource;
extern fn LoadImageFromResource(chunk: rres.ResourceChunk) rl.Image;
pub const loadImageFromResource = LoadImageFromResource;
extern fn LoadTextFromResource(chunk: rres.ResourceChunk) [*c]u8;
pub const loadTextFromResource = LoadTextFromResource;
extern fn LoadWaveFromResource(chunk: rres.ResourceChunk) rl.Wave;
pub const loadWaveFromResource = LoadWaveFromResource;
extern fn UnpackResourceChunk(chunk: [*c]rres.ResourceChunk) c_int;
pub const unpackResourceChunk = UnpackResourceChunk;
