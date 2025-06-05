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
        const tan_half_fov = math.tan(viewmodel.fov / 2);
        const to_target = position.sub(viewmodel.pos);
        const distance = to_target.length();
        if (distance < Self.epsilon) return;
        const dcx, const dcy, const dcz = to_target.directionCosineMat(
            viewmodel.right,
            viewmodel.up,
            viewmodel.front,
        );
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
