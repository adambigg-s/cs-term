const lib = @import("root.zig");
const std = lib.std;
const sim = lib.sim;
const vec = lib.vec;
const win = lib.win;

pub const Renderer = struct {
    main: Buffer(u32),
    depth: Buffer(f32),
    width: usize,
    height: usize,

    const Self = @This();
    const Alloc = std.mem.Allocator;

    const infinity = 1e9;
    const epsilon = 1e-9;

    const math = std.math;

    pub fn init(allocator: Alloc) !Self {
        const width, const height = try win.getTerminalDimensions();

        return Renderer{
            .main = try Buffer(u32).init(width, height, allocator, ' '),
            .depth = try Buffer(f32).init(width, height, allocator, Self.infinity),
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Self) void {
        self.main.deinit();
        self.depth.deinit();
    }

    pub fn clear(self: *Self) void {
        self.main.clear();
        self.depth.clear();
    }

    pub fn renderSimulation(self: *Self, simulation: *sim.Simulation) void {
        for (simulation.targets.items) |target| {
            self.renderBillboardCircle(simulation.player, target.pos, target.size);
        }
    }

    fn halfDimensionsFloat(self: *Self) struct { f32, f32 } {
        return .{ @as(f32, @floatFromInt(self.width)) / 2, @as(f32, @floatFromInt(self.height)) / 2 };
    }

    fn renderBillboardCircle(self: *Self, viewmodel: sim.Player, position: vec.Vec3(f32), size: f32) void {
        const tan_half_fov = math.tan(viewmodel.fov / 2);
        const relative_vector = position.sub(viewmodel.pos);
        const screenspace = relative_vector.directionCosineVec(
            viewmodel.right,
            viewmodel.up,
            viewmodel.front,
        );

        if (screenspace.z < Self.epsilon) return;

        const half_width, const half_height = self.halfDimensionsFloat();
        const screenx = (screenspace.x / (screenspace.z * tan_half_fov)) * half_width + half_width;
        const screeny = (-screenspace.y / (screenspace.z * tan_half_fov)) * half_height + half_height;

        const bufferx: usize, const buffery: usize = .{
            @intFromFloat(@abs(screenx)),
            @intFromFloat(@abs(screeny)),
        };

        _ = self.main.set(bufferx, buffery, '@');
        _ = size;
    }

    pub fn commitPass(self: *Self) !void {
        var stdout = std.io.getStdOut();
        var buffer_writer = std.io.bufferedWriter(stdout.writer());
        const writer = buffer_writer.writer();
        try writer.writeAll("\x1b[H");
        try writer.writeAll("\x1b[48;2;70;70;70m");
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const data = self.main.get(x, y).?;
                var char_buffer: [4]u8 = undefined;
                const len = try std.unicode.utf8Encode(@intCast(data), &char_buffer);
                try writer.writeAll(char_buffer[0..len]);
            }

            try writer.writeByte('\n');
        }
        try writer.writeAll("\x1b[0m");

        try buffer_writer.flush();
    }
};

pub fn Buffer(comptime T: type) type {
    return struct {
        width: usize,
        height: usize,
        data: std.ArrayList(T),
        clear_value: T,
        allocator: std.mem.Allocator,

        const Self = @This();
        const Alloc = std.mem.Allocator;

        pub fn init(width: usize, height: usize, allocator: Alloc, clear_value: T) !Self {
            var data = try std.ArrayList(T).initCapacity(allocator, width * height);
            data.expandToCapacity();
            var output = Buffer(T){
                .width = width,
                .height = height,
                .data = data,
                .clear_value = clear_value,
                .allocator = allocator,
            };
            output.clear();

            return output;
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn clear(self: *Self) void {
            @memset(self.data.items, self.clear_value);
        }

        pub fn get(self: *Self, x: usize, y: usize) ?T {
            if (!self.inbounds(x, y)) {
                return null;
            }

            return self.data.items[self.index(x, y)];
        }

        pub fn set(self: *Self, x: usize, y: usize, data: T) bool {
            if (!self.inbounds(x, y)) {
                return false;
            }

            self.data.items[self.index(x, y)] = data;
            return true;
        }

        fn index(self: *Self, x: usize, y: usize) usize {
            return self.width * y + x;
        }

        fn inbounds(self: *Self, x: usize, y: usize) bool {
            return x < self.width and y < self.height;
        }
    };
}

pub const LineTracer = struct {
    x0: isize,
    y0: isize,
    x1: isize,
    y1: isize,
    dx: isize,
    dy: isize,
    err: isize,

    const Self = @This();

    pub fn build() Self {
        LineTracer{};
    }
};
