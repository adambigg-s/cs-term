const lib = @import("root.zig");
const std = lib.std;

pub const Renderer = struct {
    main: lib.Buffer(u32),
    depth: lib.Buffer(f32),
    width: usize,
    height: usize,

    const Self = @This();
    const Infinity = 1e9;

    pub fn init(allocator: std.mem.Allocator) !Self {
        const width, const height = lib.getTerminalDimensions();

        return Renderer{
            .main = try lib.Buffer(u32).init(width, height, allocator, ' '),
            .depth = try lib.Buffer(f32).init(width, height, allocator, Self.Infinity),
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Self) void {
        self.main.deinit();
        self.depth.deinit();
    }

    pub fn renderScene(self: *Self) !void {
        var stdout = std.io.getStdOut();
        var buffer_writer = std.io.bufferedWriter(stdout.writer());
        const writer = buffer_writer.writer();
        _ = try buffer_writer.write("\x1b[H");
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const data = self.main.get(x, y).?;

                var char_buffer: [4]u8 = undefined;
                const len = try std.unicode.utf8Encode(@intCast(data), &char_buffer);

                try writer.writeAll(char_buffer[0..len]);
            }

            try writer.writeByte('\n');
        }

        try buffer_writer.flush();
    }
};
