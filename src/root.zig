pub const std = @import("std");

pub const app = @import("application.zig");
pub const ren = @import("renderer.zig");
pub const sim = @import("simulation.zig");
pub const vec = @import("vector.zig");
pub const win = @import("winapi.zig");

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

pub fn vec2FromPoint(point: win.WinPoint) vec.Vec2(i32) {
    return vec.Vec2(i32).build(point.x, point.y);
}

pub fn getTerminalDimensions() struct { usize, usize } {
    var console_info: win.WinConsoleInfo = undefined;
    const handle = win.GetStdHandle(win.WIN_STD_HANDLE);
    _ = win.GetConsoleScreenBufferInfo(handle, &console_info);

    const width, const height = .{ console_info.window_size.x - 1, console_info.window_size.y - 1 };
    const wp: u16, const hp: u16 = .{ @bitCast(width), @bitCast(height) };

    return .{ @as(usize, wp), @as(usize, hp) };
}
