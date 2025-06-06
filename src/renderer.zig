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
    terminal_info: TerminalInfo,

    const Self = @This();
    const Alloc = std.mem.Allocator;

    const infinity = 1e9;
    const epsilon = 1e-9;

    const math = std.math;

    pub fn init(allocator: Alloc) !Self {
        const width, const height = try win.getTerminalDimensions();
        var terminal_info: TerminalInfo = undefined;
        terminal_info.char_apsect = 2; // height x width of the terminal character
        terminal_info.screen_aspect = 1; // width x height of the terminal screen

        return Renderer{
            .main = try Buffer(u32).init(width, height, allocator, ' '),
            .depth = try Buffer(f32).init(width, height, allocator, Self.infinity),
            .width = width,
            .height = height,
            // need to query this later for proper scale rendering
            .terminal_info = terminal_info,
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
            self.renderDebugAmpersand(&simulation.player, target.pos, target.size);
        }
        self.renderDebugAmpersand(&simulation.player, vec.Vec3(f32).build(10, 50, 10), 0);
        self.renderDebugAmpersand(&simulation.player, vec.Vec3(f32).build(10, 50, -10), 0);
        self.renderDebugAmpersand(&simulation.player, vec.Vec3(f32).build(-10, 50, 10), 0);
        self.renderDebugAmpersand(&simulation.player, vec.Vec3(f32).build(-10, 50, -10), 0);
        // self.renderClippedLine(
        //     &simulation.player,
        //     vec.Vec3(f32).build(10, 100, 10),
        //     vec.Vec3(f32).build(10, 100, -10),
        // );
        // self.renderClippedLine(
        //     &simulation.player,
        //     vec.Vec3(f32).build(10, 100, -10),
        //     vec.Vec3(f32).build(-10, 100, -10),
        // );
        // self.renderClippedLine(
        //     &simulation.player,
        //     vec.Vec3(f32).build(-10, 100, -10),
        //     vec.Vec3(f32).build(-10, 100, 10),
        // );
        // self.renderClippedLine(
        //     &simulation.player,
        //     vec.Vec3(f32).build(-10, 100, 10),
        //     vec.Vec3(f32).build(10, 100, 10),
        // );
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

    fn renderClippedLine(self: *Self, viewmodel: *sim.Player, start: vec.Vec3(f32), end: vec.Vec3(f32)) void {
        const ndc_a = self.worldToNDC(viewmodel, start) orelse return;
        const ndc_b = self.worldToNDC(viewmodel, end) orelse return;
        if (!Self.isInView(viewmodel, ndc_a) and !Self.isInView(viewmodel, ndc_b)) {
            return;
        }
        const a = self.NDCToScreenSpace(ndc_a);
        const b = self.NDCToScreenSpace(ndc_b);

        // const x0: isize, const y0: isize, const x1: isize, const y1: isize = .{
        //     @as(isize, screen_a.x),
        //     @as(isize, screen_a.y),
        //     @as(isize, screen_b.x),
        //     @as(isize, screen_b.y),
        // };

        var tracer = LineTracer.build(a.x, a.y, b.x, b.y);

        while (tracer.next()) |point| {
            const x: usize, const y: usize = .{ @bitCast(point.x), @bitCast(point.y) };

            _ = self.main.set(x, y, '.');
        }

        _ = .{ self, viewmodel, start, start, end }; // just to compile for now
    }

    fn renderDebugAmpersand(self: *Self, viewmodel: *sim.Player, position: vec.Vec3(f32), size: f32) void {
        const ndc = self.worldToNDC(viewmodel, position) orelse return;
        if (!Self.isInView(viewmodel, ndc)) {
            return;
        }
        const screen = self.NDCToScreenSpace(ndc);

        _ = self.main.set(@intCast(screen.x), @intCast(screen.y), '&');
        _ = size; // just to make it compile
    }

    fn worldToNDC(self: *Self, viewmodel: *sim.Player, point: vec.Vec3(f32)) ?vec.Vec3(f32) {
        const local = point.sub(viewmodel.pos);
        const screenspace = local.directionCosineVec(
            viewmodel.right,
            viewmodel.up,
            viewmodel.front,
        );

        if (screenspace.z < viewmodel.near_plane) return null;

        const projection_coefficient = 1 / (math.tan(viewmodel.vertical_fov / 2) * screenspace.z);

        return vec.Vec3(f32).build(
            screenspace.x * projection_coefficient / self.terminal_info.screen_aspect,
            screenspace.y * projection_coefficient / self.terminal_info.char_apsect,
            screenspace.z,
        );
    }

    fn NDCToScreenSpace(self: *Self, ndc: vec.Vec3(f32)) vec.Vec2(isize) {
        const half_width, const half_height = self.halfDimensionsFloat();
        const floatx, const floaty = .{
            ndc.x * half_width + half_width,
            ndc.y * half_height + half_height,
        };
        const xsigned: isize, const ysigned: isize = .{ @intFromFloat(floatx), @intFromFloat(floaty) };

        return vec.Vec2(isize).build(xsigned, ysigned);
    }

    fn isInView(viewmodel: *sim.Player, point: vec.Vec3(f32)) bool {
        const viewx, const viewy, const viewz = .{
            point.x < 1 and point.x > -1,
            point.y < 1 and point.y > -1,
            point.z < viewmodel.far_plane and point.z > viewmodel.near_plane,
        };

        return viewx and viewy and viewz;
    }

    fn halfDimensionsFloat(self: *Self) struct { f32, f32 } {
        return .{ @as(f32, @floatFromInt(self.width)) / 2, @as(f32, @floatFromInt(self.height)) / 2 };
    }
};

pub const TerminalInfo = struct {
    screen_aspect: f32,
    char_apsect: f32,
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

// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
pub const LineTracer = struct {
    x0: isize,
    y0: isize,
    x1: isize,
    y1: isize,
    dx: isize,
    dy: isize,
    sx: isize,
    sy: isize,
    err: isize,
    done: bool,

    const Self = @This();

    pub fn build(x0: isize, y0: isize, x1: isize, y1: isize) Self {
        var dx = x1 - x0;
        var dy = y1 - y0;
        dx = @intCast(@abs(dx));
        dy = @intCast(@abs(dy));
        dy = -dy;

        const sx: isize = if (x0 < x1) 1 else -1;
        const sy: isize = if (y0 < y1) 1 else -1;

        const err = dx + dy;

        return LineTracer{
            .x0 = x0,
            .y0 = y0,
            .x1 = x1,
            .y1 = y1,
            .dx = dx,
            .dy = dy,
            .sx = sx,
            .sy = sy,
            .err = err,
            .done = false,
        };
    }

    pub fn next(self: *Self) ?vec.Vec2(isize) {
        if (self.done) return null;
        const point = vec.Vec2(isize).build(self.x0, self.y0);

        const err2 = 2 * self.err;
        if (err2 >= self.dy) {
            if (self.x1 == self.x0) {
                self.done = true;
            }
            self.err += self.dy;
            self.x0 += self.sx;
        }
        if (err2 <= self.dx) {
            if (self.y1 == self.y0) {
                self.done = true;
            }
            self.err += self.dx;
            self.y0 += self.sy;
        }

        return point;
    }
};
