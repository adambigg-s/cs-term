pub const win = @import("winapi.zig");
pub const vec = @import("vector.zig");
pub const std = @import("std");
pub const app = @import("application.zig");

pub const Inputs = struct {
    key_w: bool = false,
    key_a: bool = false,
    key_s: bool = false,
    key_d: bool = false,
    key_escape: bool = false,
    mouse_click: bool = false,
    mouse_delta: vec.Vec2(i32),
    mouse_pos: vec.Vec2(i32),

    const Self = @This();

    pub fn init() Self {
        _ = win.GetAsyncKeyState(win.VK_W);
        _ = win.GetAsyncKeyState(win.VK_A);
        _ = win.GetAsyncKeyState(win.VK_S);
        _ = win.GetAsyncKeyState(win.VK_D);
        _ = win.GetAsyncKeyState(win.VK_ESCAPE);
        _ = win.GetAsyncKeyState(win.MOUSE_LBUTTON);

        return Inputs{
            .mouse_delta = vec.Vec2(i32).zeros(),
            .mouse_pos = vec.Vec2(i32).zeros(),
        };
    }

    pub fn update(self: *Self) void {
        self.key_w = win.GetAsyncKeyState(win.VK_W) != win.WINKEYFALSE;
        self.key_a = win.GetAsyncKeyState(win.VK_A) != win.WINKEYFALSE;
        self.key_s = win.GetAsyncKeyState(win.VK_S) != win.WINKEYFALSE;
        self.key_d = win.GetAsyncKeyState(win.VK_D) != win.WINKEYFALSE;
        self.key_escape = win.GetAsyncKeyState(win.VK_ESCAPE) != win.WINKEYFALSE;
        self.mouse_click = win.GetAsyncKeyState(win.MOUSE_LBUTTON) != win.WINKEYFALSE;

        var point: win.WinPoint = undefined;
        _ = win.GetCursorPos(&point);
        const new_pos = vec2_from_point(point);
        self.mouse_delta = new_pos.sub(self.mouse_pos);
        self.mouse_pos = new_pos;
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
            const data = try std.ArrayList(T).initCapacity(allocator, width * height);
            var output = Buffer{
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
            @memset(self.data, self.clear_value);
        }

        pub fn get(self: *Self, x: usize, y: usize) ?T {
            if (!self.inbounds(x, y)) {
                return null;
            }

            return self.data[self.index(x, y)];
        }

        pub fn set(self: *Self, x: usize, y: usize, data: T) bool {
            if (!self.inbounds(x, y)) {
                return false;
            }

            self.data[self.index(x, y)] = data;
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

pub fn vec2_from_point(point: win.WinPoint) vec.Vec2(i32) {
    return vec.Vec2(i32).build(point.x, point.y);
}
