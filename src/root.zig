pub const std = @import("std");

pub const app = @import("application.zig");
pub const ren = @import("renderer.zig");
pub const sim = @import("simulation.zig");
pub const vec = @import("vector.zig");
pub const win = @import("winapi.zig");
pub const mat = @import("matrix.zig");

pub fn randomf32() f32 {
    var rng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    return rng.random().float(f32);
}

pub fn randomf32Distribution() f32 {
    return randomf32() * 2 - 1;
}

pub fn randomVec3() vec.Vec3(f32) {
    return vec.Vec3(f32).build(
        randomf32Distribution(),
        randomf32Distribution(),
        randomf32Distribution(),
    );
}

pub fn linearInterpolateVec3(start: vec.Vec3(f32), end: vec.Vec3(f32), time: f32) vec.Vec3(f32) {
    const a, const b = .{ start, end };

    return vec.Vec3(f32).build(
        a.x + time * (b.x - a.x),
        a.y + time * (b.y - a.y),
        a.z + time * (b.z - a.z),
    );
}

pub fn nearestLowerOdd(comptime T: type, value: T) T {
    return @divFloor(value, 2) * 2 - 1;
}

test "module tree test distribtuion entry point" {
    _ = @import("application.zig");
    _ = @import("renderer.zig");
    _ = @import("simulation.zig");
    _ = @import("vector.zig");
    _ = @import("winapi.zig");
    _ = @import("matrix.zig");
}

test "nearest odd testing" {
    const xp: i333 = 4;
    const x = nearestLowerOdd(i333, xp);
    try std.testing.expect(x == 3);

    const yp: usize = 20;
    const y = nearestLowerOdd(usize, yp);
    try std.testing.expect(y == 19);
}
