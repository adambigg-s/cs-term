const lib = @import("root.zig");
const std = lib.std;
const vec = lib.vec;

pub const Application = struct {
    inputs: lib.Inputs,
    state: State,
    renderer: Renderer,
};

pub const State = struct {
    targets: std.ArrayList(Target),
};

pub const Renderer = struct {};

pub const Target = struct {
    size: f32,
    pos: vec.Vec3(f32),
};
