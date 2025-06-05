const lib = @import("root.zig");
const std = lib.std;
const sim = lib.sim;
const vec = lib.vec;

pub const Renderer = struct {
    main: lib.Buffer(u32),
    depth: lib.Buffer(f32),
    width: usize,
    height: usize,

    const Self = @This();

    const infinity = 1e9;
    const epsilon = 1e-9;

    const math = std.math;

    pub fn init(allocator: std.mem.Allocator) !Self {
        const width, const height = lib.getTerminalDimensions();

        return Renderer{
            .main = try lib.Buffer(u32).init(width, height, allocator, ' '),
            .depth = try lib.Buffer(f32).init(width, height, allocator, Self.infinity),
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
            self.renderSquare(simulation.player, target.pos, target.size);
        }
    }

    // temporary just to see if working
    fn renderSquare(self: *Self, viewmodel: sim.Player, position: vec.Vec3(f32), size: f32) void {
        const fov = 1;
        const to_target = position.sub(viewmodel.pos);
        const dist = to_target.length();

        if (dist < Self.epsilon) {
            return;
        }

        const relx = to_target.inner_product(viewmodel.right);
        const rely = to_target.inner_product(viewmodel.up);
        const relz = to_target.inner_product(viewmodel.front);

        if (relz < 0.1) {
            return;
        }

        const sx = (relx / (relz * fov)) * @as(f32, @floatFromInt(self.width)) / 2 + @as(f32, @floatFromInt(self.width)) / 2;
        const sy = (-rely / (relz * fov)) * @as(f32, @floatFromInt(self.height)) / 2 + @as(f32, @floatFromInt(self.height)) / 2;

        const half_size = size / relz * 10;
        const int_half_size: isize = @intFromFloat(half_size);

        const center_x: isize = @intFromFloat(sx);
        const center_y: isize = @intFromFloat(sy);

        var dy = -int_half_size;
        while (dy <= int_half_size) : (dy += 1) {
            var dx = -int_half_size;
            while (dx <= int_half_size) : (dx += 1) {
                const x = center_x + dx;
                const y = center_y + dy;

                if (x < 0 or y < 0 or x >= self.width or y >= self.height) {
                    continue;
                }

                const bx: usize, const by: usize = .{ @bitCast(x), @bitCast(y) };
                const curr_depth = self.depth.get(bx, by) orelse Self.infinity;

                if (dist < curr_depth) {
                    _ = self.main.set(bx, by, '*');
                    _ = self.depth.set(bx, by, dist);
                }
            }
        }
    }

    pub fn commitPass(self: *Self) !void {
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
