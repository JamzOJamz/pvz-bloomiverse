const std = @import("std");

const rl = @import("raylib");
const rres = @import("zrres");
const rres_rl = @import("zrres_rl");

const Self = @This();

cd: rres.CentralDir,
rres_path: [:0]const u8,
loaded_texture_ids: std.ArrayList(u32),

pub fn init(ally: std.mem.Allocator, rres_path: [:0]const u8) Self {
    return Self{
        .cd = rres.loadCentralDirectory(rres_path),
        .rres_path = rres_path,
        .loaded_texture_ids = std.ArrayList(u32).init(ally),
    };
}

pub fn request(self: *Self, comptime T: type, path: [:0]const u8) !?T {
    const id = rres.getResourceId(self.cd, path);
    var chunk = rres.loadResourceChunk(self.rres_path, id);
    defer rres.unloadResourceChunk(chunk);
    if (rres_rl.unpackResourceChunk(&chunk) != 0) return null;

    switch (T) {
        rl.Texture => |_| {
            const image = rres_rl.loadImageFromResource(chunk);
            defer rl.unloadImage(image);
            const texture = try rl.loadTextureFromImage(image);
            try self.loaded_texture_ids.append(texture.id);
            return texture;
        },
        else => return null,
    }
}

pub fn deinit(self: *Self) void {
    // Unload all textures that were loaded
    for (self.loaded_texture_ids.items) |texture_id| {
        rl.unloadTexture(rl.Texture{
            .id = texture_id,
            .width = undefined,
            .height = undefined,
            .mipmaps = undefined,
            .format = undefined,
        });
    }
    self.loaded_texture_ids.deinit();

    rres.unloadCentralDirectory(self.cd);
}
