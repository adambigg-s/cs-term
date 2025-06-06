pub const std = @import("std");

pub const app = @import("application.zig");
pub const ren = @import("renderer.zig");
pub const sim = @import("simulation.zig");
pub const vec = @import("vector.zig");
pub const win = @import("winapi.zig");

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
