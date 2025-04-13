const rl = @import("raylib");
const rres = @import("zrres");

extern fn LoadImageFromResource(chunk: rres.ResourceChunk) rl.Image;
pub const loadImageFromResource = LoadImageFromResource;
extern fn UnpackResourceChunk(chunk: [*c]rres.ResourceChunk) c_int;
pub const unpackResourceChunk = UnpackResourceChunk;
