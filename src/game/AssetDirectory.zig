const std = @import("std");

const rl = @import("raylib");
const rres = @import("zrres");
const rres_rl = @import("zrres_rl");

const Self = @This();

cd: rres.CentralDir,
rres_path: [:0]const u8,
loaded_texture_ids: std.ArrayList(u32),
loaded_shaders: std.ArrayList(rl.Shader),
loaded_music_data: std.ArrayList(*const u8),

pub fn init(ally: std.mem.Allocator, rres_path: [:0]const u8) Self {
    return Self{
        .cd = rres.loadCentralDirectory(rres_path),
        .rres_path = rres_path,
        .loaded_texture_ids = std.ArrayList(u32).init(ally),
        .loaded_shaders = std.ArrayList(rl.Shader).init(ally),
        .loaded_music_data = std.ArrayList(*const u8).init(ally),
    };
}

pub fn request(self: *Self, comptime T: type, path: [:0]const u8) !T {
    const id = rres.getResourceId(self.cd, path);
    if (id == 0) return error.ResourceNotFound;
    var chunk = rres.loadResourceChunk(self.rres_path, id);
    defer rres.unloadResourceChunk(chunk);
    if (rres_rl.unpackResourceChunk(&chunk) != 0) return error.UnpackError;

    switch (T) {
        rl.Texture => |_| {
            const image = rres_rl.loadImageFromResource(chunk);
            defer rl.unloadImage(image);
            const texture = try rl.loadTextureFromImage(image);
            try self.loaded_texture_ids.append(texture.id);
            return texture;
        },
        rl.Shader => |_| {
            const source = rres_rl.loadTextFromResource(chunk);
            defer rl.memFree(@ptrCast(source));
            const shader = try rl.loadShaderFromMemory(null, std.mem.span(source));
            try self.loaded_shaders.append(shader);
            return shader;
        },
        rl.Sound => |_| {
            var data_size: u32 = 0;
            const raw_data = rres_rl.loadDataFromResource(chunk, &data_size);
            defer rl.memFree(@ptrCast(raw_data));
            const wave = try rl.loadWaveFromMemory(".wav", raw_data[0..data_size]);
            defer rl.unloadWave(wave);
            const sound = rl.loadSoundFromWave(wave);
            return sound;
        },
        rl.Music => |_| {
            var data_size: u32 = 0;
            const raw_data = rres_rl.loadDataFromResource(chunk, &data_size);
            try self.loaded_music_data.append(raw_data);
            const music = rl.loadMusicStreamFromMemory(".ogg", raw_data[0..data_size]);
            return music;
        },
        else => return error.InvalidResourceType,
    }
}

pub fn deinit(self: *const Self) void {
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

    // Unload all shaders that were loaded
    for (self.loaded_shaders.items) |shader| {
        rl.unloadShader(shader);
    }
    self.loaded_shaders.deinit();

    // Unload all music data that was loaded
    for (self.loaded_music_data.items) |music_data| {
        rl.memFree(@constCast(music_data));
    }

    rres.unloadCentralDirectory(self.cd);
}
