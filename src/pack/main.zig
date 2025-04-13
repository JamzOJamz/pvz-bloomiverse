//! Packs game assets into a single `.rres` file.

const std = @import("std");

const rres = @import("zrres");

/// Name of the directory containing the game assets to be packed.
const resources_dir_name = "resources";

/// Name of the output `.rres` file.
const rres_file_name = "resources.rres";

/// Whether or not to create a central directory in the `.rres` file.
const create_central_directory = true;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create a timer to measure the packing time
    var run_timer = try std.time.Timer.start();

    // Get the current working directory
    const cwd = std.fs.cwd();

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_path = try cwd.realpath(".", &buf);

    // Print the cwd path
    std.debug.print("Current working directory: {s}\n", .{cwd_path});

    // Create the .rres file
    var rres_file = try cwd.createFile(rres_file_name, .{});
    defer rres_file.close();

    // Skip header for now; we'll write it last since it depends on the final chunk count
    try rres_file.seekTo(@sizeOf(rres.FileHeader));

    // Define chunk info and data structures for reuse
    var chunk_info = rres.ResourceChunkInfo{
        .type = "RAWD".*, // Resource chunk type
    };
    var chunk_data = rres.ResourceChunkData{};

    // If creating a central directory, define its chunk info and data structures
    var cd_chunk_info = if (create_central_directory) rres.ResourceChunkInfo{
        .type = "CDIR".*, // Resource chunk type
    };
    var cd_props = if (create_central_directory) [_]u32{0} else {};
    var cd_chunk_data = if (create_central_directory) rres.ResourceChunkData{
        .propCount = 1,
        .props = &cd_props,
        .raw = null,
    };
    var cd_entries = if (create_central_directory) std.ArrayList(rres.DirEntry).init(allocator);
    defer if (create_central_directory) cd_entries.deinit();

    // Open the resources directory for iteration
    var resources_dir = try cwd.openDir(resources_dir_name, .{
        .iterate = true,
    });
    defer resources_dir.close();

    std.debug.print("Opened resources directory for reading\n", .{});

    // Walk through and process the contents of the resources directory
    var walker = try resources_dir.walk(allocator);
    defer walker.deinit();
    var processed_count: usize = 0;
    while (try walker.next()) |entry| {
        if (entry.kind == .directory) continue;

        // Skip any files in an unused directory
        if (std.mem.indexOf(u8, entry.path, "_unused\\") != null) continue;

        std.debug.print("Processing file: {s}\n", .{entry.path});

        // Open the file for reading
        var file = try resources_dir.openFile(entry.path, .{});
        defer file.close();
        const stat = try file.stat();

        // Read the file contents into a buffer
        const raw_data = try allocator.alloc(u8, stat.size);
        defer allocator.free(raw_data);
        _ = try file.readAll(raw_data);

        // Set resource chunk identifier (generated from file name CRC32 hash)
        chunk_info.id = rres.computeCRC32(@constCast(entry.path.ptr), @intCast(entry.path.len));

        chunk_info.baseSize = 5 * @sizeOf(u32) + @as(u32, @intCast(stat.size));
        chunk_info.packedSize = chunk_info.baseSize;

        // Define chunk data: RAWD
        chunk_data.propCount = 4;
        const props = try allocator.alloc(u32, chunk_data.propCount);
        defer allocator.free(props);
        chunk_data.props = props.ptr;
        chunk_data.props[0] = @intCast(stat.size); // Size of the file
        chunk_data.props[1] = 0x2e706e67; // File extension ".png"
        chunk_data.props[2] = 0;
        chunk_data.props[3] = 0;
        chunk_data.raw = raw_data.ptr;

        // Get a continuous data buffer from chunk data
        const buffer = try loadDataBuffer(allocator, chunk_data, stat.size);
        defer allocator.free(buffer);

        // Compute data chunk CRC32 (propCount + props[] + data)
        chunk_info.crc32 = rres.computeCRC32(buffer.ptr, @intCast(chunk_info.packedSize));

        // Write the chunk info and data to the file
        const chunk_global_offset = try rres_file.getPos();
        try rres_file.writeAll(std.mem.asBytes(&chunk_info));
        try rres_file.writeAll(buffer);

        // Add entry to the central directory if needed
        if (create_central_directory) {
            var cd_entry = rres.DirEntry{
                .id = chunk_info.id,
                .offset = @intCast(chunk_global_offset),
                .fileNameSize = @intCast(std.mem.alignForward(usize, entry.path.len, 4)),
                .fileName = undefined,
            };
            @memset(&cd_entry.fileName, 0);
            @memcpy(cd_entry.fileName[0..entry.path.len], entry.path.ptr);
            try cd_entries.append(cd_entry);
        }

        // Increment the processed file count
        processed_count += 1;
    }

    // Finalize the central directory and write it to the file if needed
    if (create_central_directory) {
        cd_props[0] = @intCast(cd_entries.items.len); // Set number of entries

        var list = std.ArrayList(u8).init(allocator);
        const writer = list.writer();
        for (cd_entries.items) |entry| {
            try writer.writeAll(std.mem.asBytes(&entry.id));
            try writer.writeAll(std.mem.asBytes(&entry.offset));
            try writer.writeByteNTimes(0, 4); // Reserved bytes
            try writer.writeAll(std.mem.asBytes(&entry.fileNameSize));
            try writer.writeAll(std.mem.sliceAsBytes(entry.fileName[0..entry.fileNameSize]));
        }

        // Set chunk data raw pointer to the central directory data
        cd_chunk_data.raw = list.items.ptr;

        // Set chunk data size
        cd_chunk_info.baseSize = 2 * @sizeOf(u32) + @as(u32, @intCast(list.items.len));
        cd_chunk_info.packedSize = cd_chunk_info.baseSize;
    }

    // Write the file header to the beginning of the file
    var header = rres.FileHeader{
        .id = "rres".*, // File identifier
        .version = 100, // Version 1.0
        .chunkCount = @intCast(processed_count),
    };
    if (create_central_directory) header.cdOffset = @intCast(try rres_file.getPos() - @sizeOf(rres.FileHeader));
    try rres_file.seekTo(0);
    try rres_file.writeAll(std.mem.asBytes(&header));

    // Write the central directory if needed
    if (create_central_directory) {
        try rres_file.seekFromEnd(0);
        const buffer = try loadDataBuffer(allocator, cd_chunk_data, cd_chunk_info.packedSize - 2 * @sizeOf(u32));
        defer allocator.free(buffer);

        // Compute data chunk CRC32 (propCount + props[] + data)
        cd_chunk_info.crc32 = rres.computeCRC32(buffer.ptr, @intCast(cd_chunk_info.packedSize));

        try rres_file.writeAll(std.mem.asBytes(&cd_chunk_info));
        try rres_file.writeAll(buffer);
    }

    // Print the final message
    std.debug.print("Packed {d} files into {s} in {d:.2}ms\n", .{
        processed_count,
        rres_file_name,
        @as(f64, @floatFromInt(run_timer.read())) / 1e+6,
    });
}

/// Load a continuous data buffer from ResourceChunkData struct. The caller owns the returned memory.
fn loadDataBuffer(allocator: std.mem.Allocator, data: rres.ResourceChunkData, raw_size: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, (data.propCount + 1) * @sizeOf(u32) + raw_size);

    @memcpy(buffer[0..@sizeOf(u32)], std.mem.asBytes(&data.propCount));
    for (0..data.propCount) |i| {
        @memcpy(buffer[(i + 1) * @sizeOf(u32) ..][0..@sizeOf(u32)], std.mem.asBytes(&data.props[i]));
    }
    @memcpy(buffer[(data.propCount + 1) * @sizeOf(u32) ..][0..raw_size], @as([*]u8, @alignCast(@ptrCast(data.raw)))[0..raw_size]);

    return buffer;
}
