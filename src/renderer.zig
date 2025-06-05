const lib = @import("root.zig");
const std = lib.std;

pub const Renderer = struct {
    main: lib.Buffer(u32),
    depth: lib.Buffer(f32),
    width: usize,
    height: usize,

    const Self = @This();
    const Infinity = 1e9;

    pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Self {
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
};
