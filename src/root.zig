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

pub fn randomf32() f32 {
    var rng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    return rng.random().float(f32);
}

pub fn randomf32Distribution() f32 {
    return randomf32() * 2 - 1;
}

pub fn getTerminalDimensions() struct { usize, usize } {
    var console_info: win.WinConsoleInfo = undefined;
    const handle = win.GetStdHandle(win.WIN_STD_HANDLE);
    _ = win.GetConsoleScreenBufferInfo(handle, &console_info);

    const width_signed, const height_signed = .{
        console_info.window_size.x - 1,
        console_info.window_size.y - 1,
    };
    const width: u16, const height: u16 = .{ @bitCast(width_signed), @bitCast(height_signed) };

    return .{ @as(usize, width), @as(usize, height) };
}

pub fn randomVec3() vec.Vec3(f32) {
    return vec.Vec3(f32).build(
        randomf32Distribution(),
        randomf32Distribution(),
        randomf32Distribution(),
    );
}

pub fn vec2FromPoint(point: win.WinPoint) vec.Vec2(i32) {
    return vec.Vec2(i32).build(point.x, point.y);
}

