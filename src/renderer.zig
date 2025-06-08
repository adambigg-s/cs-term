const lib = @import("root.zig");
const std = lib.std;
const sim = lib.sim;
const vec = lib.vec;
const win = lib.win;

pub const Renderer = struct {
    main: Buffer(u21),
    depth: Buffer(f32),
    width: usize,
    height: usize,
    terminal_info: TerminalInfo,
    config: RenderConfig,

    const Self = @This();
    const Alloc = std.mem.Allocator;

    const infinity = 1e9;
    const epsilon = 1e-9;

    const math = std.math;

    pub fn init(allocator: Alloc) !Self {
        const width, const height = try win.getTerminalDimensions();
        var terminal_info: TerminalInfo = undefined;
        terminal_info.char_apsect = 1.5; // height x width of the terminal character
        terminal_info.screen_aspect = 2560.0 / 1080.0; // width x height of the terminal screen

        return Renderer{
            .main = try Buffer(u21).init(width, height, allocator, ' '),
            .depth = try Buffer(f32).init(width, height, allocator, Self.infinity),
            .width = width,
            .height = height,
            // need to query this later for proper scale rendering
            .terminal_info = terminal_info,
            .config = RenderConfig{
                .render_freq = 3,
            },
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
            self.renderDebugCharacter(&simulation.player, target.pos, 'X');
        }
        // other debug stuff right in front
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(10, 0, 1.5), 'a');
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(10, 1.5, 0), 'b');
        // large square on the ground
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(10, -50, 10), 'a');
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(10, -50, -10), 'b');
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(-10, -50, 10), 'c');
        self.renderDebugCharacter(&simulation.player, vec.Vec3(f32).build(-10, -50, -10), 'd');

        var box = Box3.build(vec.Vec3(f32).build(-70, -70, -70), vec.Vec3(f32).build(70, 70, 70));
        const edges = box.toLinestrip();

        for (0..edges.len / 2) |index| {
            const p1 = edges[2 * index + 0];
            const p2 = edges[2 * index + 1];
            const a = vec.Vec3(f32).build(p1[0], p1[1], p1[2]);
            const b = vec.Vec3(f32).build(p2[0], p2[1], p2[2]);

            self.renderLine(&simulation.player, a, b, '*');
        }

        self.renderLine(
            &simulation.player,
            vec.Vec3(f32).build(30, -2, 30),
            vec.Vec3(f32).build(30, -2, -30),
            '.',
        );
        self.renderLine(
            &simulation.player,
            vec.Vec3(f32).build(30, -2, -30),
            vec.Vec3(f32).build(-30, -2, -30),
            ',',
        );
        self.renderLine(
            &simulation.player,
            vec.Vec3(f32).build(-30, -2, -30),
            vec.Vec3(f32).build(-30, -2, 30),
            '<',
        );
        self.renderLine(
            &simulation.player,
            vec.Vec3(f32).build(-30, -2, 30),
            vec.Vec3(f32).build(30, -2, 30),
            '`',
        );
    }

    pub fn commitPass(self: *Self) !void {
        var stdout = std.io.getStdOut();
        var buffer_writer = std.io.bufferedWriter(stdout.writer());
        const writer = buffer_writer.writer();
        try writer.writeAll("\x1b[H");
        try writer.writeAll("\x1b[48;2;110;110;110m");
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const data = self.main.get(x, y).?;
                var char_buffer: [3]u8 = undefined;
                // this is a really weird conversion but it shouldn't ever panic
                // 3 * 8 > 21 so it should always be a big enough buffer
                const len = try std.unicode.utf8Encode(@intCast(data), &char_buffer);
                try writer.writeAll(char_buffer[0..len]);
            }

            try writer.writeByte('\n');
        }
        try writer.writeAll("\x1b[0m");

        try buffer_writer.flush();
    }

    fn renderDebugCharacter(self: *Self, viewmodel: *sim.Player, position: vec.Vec3(f32), fill: u8) void {
        const ndc = self.worldToNDC(viewmodel, position) orelse return;
        if (!Self.isInView(viewmodel, ndc)) {
            return;
        }
        const point = self.NDCToScreenspace(ndc);

        const unsigned_x: usize, const unsigned_y: usize = .{ @bitCast(point.x), @bitCast(point.y) };
        _ = self.main.set(unsigned_x, unsigned_y, fill);
    }

    fn renderLine(self: *Self, viewmodel: *sim.Player, a: vec.Vec3(f32), b: vec.Vec3(f32), fill: u8) void {
        var view_a, var view_b = .{
            self.worldToViewspace(viewmodel, a),
            self.worldToViewspace(viewmodel, b),
        };
        if (view_a.x < viewmodel.near_plane and view_b.x < viewmodel.near_plane) {
            return;
        } else if (view_a.x < viewmodel.near_plane) {
            Self.clipNear(&view_a, view_b, viewmodel);
        } else if (view_b.x < viewmodel.near_plane) {
            Self.clipNear(&view_b, view_a, viewmodel);
        }

        const ndc_a, const ndc_b = .{
            self.viewspaceToNDC(viewmodel, view_a),
            self.viewspaceToNDC(viewmodel, view_b),
        };

        const to, const from = .{
            self.NDCToScreenspace(ndc_a),
            self.NDCToScreenspace(ndc_b),
        };

        const to_inbounds, const from_inbounds = .{
            self.main.inbounds(@bitCast(to.x), @bitCast(to.y)),
            self.main.inbounds(@bitCast(to.x), @bitCast(to.y)),
        };
        if (!to_inbounds and !from_inbounds) return;

        var tracer = LineTracer.build(to.x, to.y, from.x, from.y);

        while (tracer.next()) |point| {
            const unsigned_x: usize, const unsigned_y: usize = .{ @bitCast(point.x), @bitCast(point.y) };
            _ = self.main.set(unsigned_x, unsigned_y, fill);
        }
    }

    fn worldToViewspace(_: *Self, viewmodel: *sim.Player, point: vec.Vec3(f32)) vec.Vec3(f32) {
        // takes care of translation
        const local = point.sub(viewmodel.pos);
        // cool direction cosine trick to take care of all rotations
        return local.directionCosineVec(
            viewmodel.front,
            viewmodel.up,
            viewmodel.right,
        );
    }

    fn viewspaceToNDC(self: *Self, viewmodel: *sim.Player, viewspace: vec.Vec3(f32)) vec.Vec3(f32) {
        // https://stackoverflow.com/questions/4427662/whats-the-relationship-between-field
        // -of-view-and-lens-length
        const projection_coefficient = 1 / (math.tan(viewmodel.vertical_fov / 2) * viewspace.x);
        const proj_x, const proj_y = self.terminalProjectionCorrection(projection_coefficient);

        // puts into NDC in screen-space basis
        return vec.Vec3(f32).build(
            viewspace.z * proj_x,
            -viewspace.y * proj_y,
            viewspace.x,
        );
    }

    // https://moorepants.github.io/learn-multibody-dynamics/orientation.html
    fn worldToNDC(self: *Self, viewmodel: *sim.Player, point: vec.Vec3(f32)) ?vec.Vec3(f32) {
        const viewspace = self.worldToViewspace(viewmodel, point);

        if (viewspace.x < viewmodel.near_plane) {
            return null;
        }

        return self.viewspaceToNDC(viewmodel, viewspace);
    }

    fn NDCToScreenspace(self: *Self, ndc: vec.Vec3(f32)) vec.Vec2(isize) {
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

    fn clipNear(target: *vec.Vec3(f32), other: vec.Vec3(f32), viewmodel: *sim.Player) void {
        const time = (viewmodel.near_plane - target.x) / (other.x - target.x);
        target.* = lib.linearInterpolateVec3(target.*, other, time);
    }

    fn terminalProjectionCorrection(self: *Self, raw_coefficient: f32) struct { f32, f32 } {
        return .{
            raw_coefficient / self.terminal_info.screen_aspect,
            raw_coefficient / self.terminal_info.char_apsect,
        };
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

pub const RenderConfig = struct {
    render_freq: usize,

    const Self = @This();

    pub fn shouldRender(self: *Self, tick: usize) bool {
        return 0 == tick % self.render_freq;
    }
};

pub const Box3 = struct {
    min: Vec3,
    max: Vec3,

    const Self = @This();
    const Vec3 = vec.Vec3(f32);

    pub fn build(min: Vec3, max: Vec3) Self {
        return Box3{ .min = min, .max = max };
    }

    pub fn toLinestrip(self: *Self) [24][3]f32 {
        var output: [24][3]f32 = undefined;

        const min, const max = .{ self.min, self.max };

        const corners: [8][3]f32 = .{
            .{ min.x, min.y, min.z },
            .{ max.x, min.y, min.z },
            .{ max.x, max.y, min.z },
            .{ min.x, max.y, min.z },
            .{ min.x, min.y, max.z },
            .{ max.x, min.y, max.z },
            .{ max.x, max.y, max.z },
            .{ min.x, max.y, max.z },
        };

        const indices: [12][2]usize = .{
            .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
            .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 4, 4 },
            .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
        };

        for (indices, 0..indices.len) |pair, index| {
            output[index * 2 + 0] = corners[pair[0]];
            output[index * 2 + 1] = corners[pair[1]];
        }

        return output;
    }
};
